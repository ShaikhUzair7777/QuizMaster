package com.quizmaster.service;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.Authenticator;
import java.net.CookieHandler;
import java.net.ProxySelector;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpHeaders;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.NoSuchAlgorithmException;
import java.util.Map;
import java.util.Optional;
import java.util.List;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import java.util.concurrent.Flow;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLParameters;
import javax.net.ssl.SSLSession;

import static org.junit.jupiter.api.Assertions.*;

class GeminiApiClientTest {

    @Test
    void sendsSystemInstructionAsGeminiPartObjectAndKeepsKeyInHeader() throws Exception {
        RecordingHttpClient http = new RecordingHttpClient(200, """
                {"candidates":[{"finishReason":"STOP","content":{"parts":[{"text":"{\\"ok\\":true}"}]}}]}
                """);
        GeminiApiClient client = new GeminiApiClient(http, "test-gemini-key", "gemini-test-model");

        String output = client.generate("Generate a topic quiz.");

        JsonObject requestBody = JsonParser.parseString(http.requestBody.get()).getAsJsonObject();
        JsonObject firstSystemPart = requestBody.getAsJsonObject("systemInstruction")
                .getAsJsonArray("parts").get(0).getAsJsonObject();
        assertTrue(firstSystemPart.has("text"));
        assertTrue(firstSystemPart.get("text").getAsString().contains("multiple-choice"));
        assertEquals("Generate a topic quiz.", requestBody.getAsJsonArray("contents")
                .get(0).getAsJsonObject().getAsJsonArray("parts")
                .get(0).getAsJsonObject().get("text").getAsString());
        assertEquals("test-gemini-key", http.request.get().headers()
                .firstValue("x-goog-api-key").orElseThrow());
        assertFalse(http.request.get().uri().toString().contains("test-gemini-key"));
        assertEquals("{\"ok\":true}", output);
    }

    @Test
    void returnsSafeActionableMessageForBadRequestWithoutExposingProviderBody() {
        RecordingHttpClient http = new RecordingHttpClient(400,
                "{\"error\":{\"message\":\"private provider detail\"}}");
        GeminiApiClient client = new GeminiApiClient(http, "test-gemini-key", "gemini-test-model");

        GeminiException error = assertThrows(GeminiException.class,
                () -> client.generate("Generate a topic quiz."));

        assertTrue(error.getMessage().contains("provider rejected"));
        assertFalse(error.getMessage().contains("private provider detail"));
    }

    @Test
    void reportsActionableErrorWhenFallbackModelIsAlsoUnavailable() {
        RecordingHttpClient http = new RecordingHttpClient(new int[]{404, 404},
                "{\"error\":{\"message\":\"private provider detail\"}}");
        GeminiApiClient client = new GeminiApiClient(http, "test-gemini-key", "retired-model");

        GeminiException error = assertThrows(GeminiException.class,
                () -> client.generate("Generate a topic quiz."));

        assertTrue(error.getMessage().contains("Gemini API is enabled"));
        assertFalse(error.getMessage().contains("private provider detail"));
        assertEquals(2, http.requestUris.size());
        assertEquals("GET", http.requestMethods.get(1));
    }

    @Test
    void discoversAndUsesTextModelAvailableToConfiguredApiKey() throws Exception {
        RecordingHttpClient http = new RecordingHttpClient(
                new int[]{404, 200, 200},
                new String[]{
                        "{\"error\":{\"message\":\"model not found\"}}",
                        """
                        {"models":[
                          {"name":"models/gemini-audio-live","supportedGenerationMethods":["generateContent"]},
                          {"name":"models/gemini-available-flash","supportedGenerationMethods":["generateContent"]},
                          {"name":"models/gemini-available-pro","supportedGenerationMethods":["generateContent"]},
                          {"name":"models/embedding-model","supportedGenerationMethods":["embedContent"]}
                        ]}
                        """,
                        """
                        {"candidates":[{"finishReason":"STOP","content":{"parts":[{"text":"{\\"ok\\":true}"}]}}]}
                        """
                });
        GeminiApiClient client = new GeminiApiClient(http, "test-gemini-key", "retired-model");

        assertEquals("{\"ok\":true}", client.generate("Generate a topic quiz."));
        assertEquals(List.of("POST", "GET", "POST"), http.requestMethods);
        assertTrue(http.requestUris.get(2).toString()
                .contains("/models/gemini-available-flash:generateContent"));
    }

    private static final class RecordingHttpClient extends HttpClient {
        private final int[] statuses;
        private final String[] responseBodies;
        private final AtomicReference<HttpRequest> request = new AtomicReference<>();
        private final AtomicReference<String> requestBody = new AtomicReference<>();
        private final AtomicInteger calls = new AtomicInteger();
        private final List<URI> requestUris = new CopyOnWriteArrayList<>();
        private final List<String> requestMethods = new CopyOnWriteArrayList<>();

        private RecordingHttpClient(int status, String responseBody) {
            this(new int[]{status}, new String[]{responseBody});
        }

        private RecordingHttpClient(int[] statuses, String responseBody) {
            this(statuses, new String[]{responseBody});
        }

        private RecordingHttpClient(int[] statuses, String[] responseBodies) {
            this.statuses = statuses;
            this.responseBodies = responseBodies;
        }

        @Override
        public <T> HttpResponse<T> send(HttpRequest request, HttpResponse.BodyHandler<T> handler)
                throws IOException {
            this.request.set(request);
            requestUris.add(request.uri());
            requestMethods.add(request.method());
            if (request.bodyPublisher().isPresent()) try {
                ByteArrayOutputStream bytes = new ByteArrayOutputStream();
                request.bodyPublisher().orElseThrow().subscribe(new Flow.Subscriber<>() {
                    @Override
                    public void onSubscribe(Flow.Subscription subscription) {
                        subscription.request(Long.MAX_VALUE);
                    }

                    @Override
                    public void onNext(ByteBuffer item) {
                        byte[] chunk = new byte[item.remaining()];
                        item.get(chunk);
                        bytes.writeBytes(chunk);
                    }

                    @Override
                    public void onError(Throwable throwable) {
                        throw new IllegalStateException(throwable);
                    }

                    @Override
                    public void onComplete() {
                        requestBody.set(bytes.toString(StandardCharsets.UTF_8));
                    }
                });
            } catch (RuntimeException ex) {
                throw ex;
            }
            int callIndex = calls.getAndIncrement();
            int status = statuses[Math.min(callIndex, statuses.length - 1)];
            String responseBody = responseBodies[Math.min(callIndex, responseBodies.length - 1)];
            return new StubHttpResponse<>(request, status, responseBody);
        }

        @Override public Optional<CookieHandler> cookieHandler() { return Optional.empty(); }
        @Override public Optional<Duration> connectTimeout() { return Optional.empty(); }
        @Override public Redirect followRedirects() { return Redirect.NEVER; }
        @Override public Optional<ProxySelector> proxy() { return Optional.empty(); }
        @Override public SSLContext sslContext() { try { return SSLContext.getDefault(); } catch (NoSuchAlgorithmException ex) { throw new IllegalStateException(ex); } }
        @Override public SSLParameters sslParameters() { return new SSLParameters(); }
        @Override public Optional<Authenticator> authenticator() { return Optional.empty(); }
        @Override public Version version() { return Version.HTTP_1_1; }
        @Override public Optional<Executor> executor() { return Optional.empty(); }
        @Override public <T> CompletableFuture<HttpResponse<T>> sendAsync(
                HttpRequest request, HttpResponse.BodyHandler<T> responseBodyHandler) {
            throw new UnsupportedOperationException();
        }
        @Override public <T> CompletableFuture<HttpResponse<T>> sendAsync(
                HttpRequest request, HttpResponse.BodyHandler<T> responseBodyHandler,
                HttpResponse.PushPromiseHandler<T> pushPromiseHandler) {
            throw new UnsupportedOperationException();
        }
        @Override public WebSocket.Builder newWebSocketBuilder() {
            throw new UnsupportedOperationException();
        }
    }

    private static final class StubHttpResponse<T> implements HttpResponse<T> {
        private final HttpRequest request;
        private final int status;
        private final String body;

        private StubHttpResponse(HttpRequest request, int status, String body) {
            this.request = request;
            this.status = status;
            this.body = body;
        }

        @Override public int statusCode() { return status; }
        @Override public HttpRequest request() { return request; }
        @Override public Optional<HttpResponse<T>> previousResponse() { return Optional.empty(); }
        @Override public HttpHeaders headers() { return HttpHeaders.of(Map.of(), (name, value) -> true); }
        @Override @SuppressWarnings("unchecked") public T body() { return (T) body; }
        @Override public Optional<SSLSession> sslSession() { return Optional.empty(); }
        @Override public URI uri() { return request.uri(); }
        @Override public HttpClient.Version version() { return HttpClient.Version.HTTP_1_1; }
    }
}
