package com.quizmaster.service;

import com.google.gson.*;
import java.net.URI;
import java.net.http.*;
import java.time.Duration;
import java.util.logging.Logger;

/**
 * HTTP client wrapper for Supabase PostgREST (database REST API).
 * Uses the service-role key for server-side privileged operations.
 * Never expose the service-role key to the client.
 */
public class SupabaseDbService {

    private static final Logger LOG = Logger.getLogger(SupabaseDbService.class.getName());

    private final String      projectUrl;
    private final String      serviceKey;
    private final HttpClient  client;
    private final Gson        gson;

    public SupabaseDbService() {
        this.projectUrl = com.quizmaster.util.EnvConfig.get("SUPABASE_URL");
        this.serviceKey = com.quizmaster.util.EnvConfig.get("SUPABASE_SERVICE_ROLE_KEY");
        this.client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
        this.gson = new GsonBuilder()
                .setDateFormat("yyyy-MM-dd'T'HH:mm:ss")
                .create();
    }

    public boolean isConfigured() {
        return com.quizmaster.util.EnvConfig.isValidProjectUrl(projectUrl)
                && com.quizmaster.util.EnvConfig.isValidSupabaseKey(serviceKey, true);
    }

    // ── Generic helpers ───────────────────────────────────────────────────

    public JsonArray select(String table, String query) throws Exception {
        assertConfigured();
        String url = base() + "/rest/v1/" + table + (query != null ? "?" + query : "");
        HttpRequest req = builder(url)
                .header("Prefer", "return=representation")
                .GET().build();
        HttpResponse<String> res = client.send(req, HttpResponse.BodyHandlers.ofString());
        checkStatus(res);
        return JsonParser.parseString(res.body()).getAsJsonArray();
    }

    public JsonObject selectOne(String table, String query) throws Exception {
        JsonArray arr = select(table, query + "&limit=1");
        if (arr.isEmpty()) return null;
        return arr.get(0).getAsJsonObject();
    }

    public JsonObject insert(String table, JsonObject payload) throws Exception {
        assertConfigured();
        String url = base() + "/rest/v1/" + table;
        HttpRequest req = builder(url)
                .header("Prefer", "return=representation")
                .POST(body(payload)).build();
        HttpResponse<String> res = client.send(req, HttpResponse.BodyHandlers.ofString());
        checkStatus(res);
        JsonElement el = JsonParser.parseString(res.body());
        if (el.isJsonArray() && el.getAsJsonArray().size() > 0) {
            return el.getAsJsonArray().get(0).getAsJsonObject();
        }
        return null;
    }

    public JsonObject upsert(String table, String conflictColumns, JsonObject payload) throws Exception {
        assertConfigured();
        String url = base() + "/rest/v1/" + table + "?on_conflict=" + conflictColumns;
        HttpRequest req = builder(url)
                .header("Prefer", "resolution=merge-duplicates,return=representation")
                .POST(body(payload)).build();
        HttpResponse<String> res = client.send(req, HttpResponse.BodyHandlers.ofString());
        checkStatus(res);
        JsonElement el = JsonParser.parseString(res.body());
        if (el.isJsonArray() && !el.getAsJsonArray().isEmpty()) {
            return el.getAsJsonArray().get(0).getAsJsonObject();
        }
        return null;
    }

    public void update(String table, String query, JsonObject payload) throws Exception {
        assertConfigured();
        String url = base() + "/rest/v1/" + table + "?" + query;
        HttpRequest req = builder(url)
                .method("PATCH", body(payload)).build();
        HttpResponse<String> res = client.send(req, HttpResponse.BodyHandlers.ofString());
        checkStatus(res);
    }

    public void delete(String table, String query) throws Exception {
        assertConfigured();
        String url = base() + "/rest/v1/" + table + "?" + query;
        HttpRequest req = builder(url).DELETE().build();
        HttpResponse<String> res = client.send(req, HttpResponse.BodyHandlers.ofString());
        checkStatus(res);
    }

    // ── RPC (stored functions) ────────────────────────────────────────────

    public JsonElement rpc(String function, JsonObject params) throws Exception {
        assertConfigured();
        String url = base() + "/rest/v1/rpc/" + function;
        HttpRequest req = builder(url)
                .POST(body(params)).build();
        HttpResponse<String> res = client.send(req, HttpResponse.BodyHandlers.ofString());
        checkStatus(res);
        return JsonParser.parseString(res.body());
    }

    // ── Private helpers ───────────────────────────────────────────────────

    private String base() {
        return projectUrl.replaceAll("/+$", "");
    }

    private HttpRequest.Builder builder(String url) {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(20))
                .header("User-Agent", "QuizMaster-Backend/1.0")
                .header("Content-Type", "application/json")
                .header("apikey", serviceKey);
        if (serviceKey.split("\\.", -1).length == 3) {
            builder.header("Authorization", "Bearer " + serviceKey);
        }
        return builder;
    }

    private HttpRequest.BodyPublisher body(JsonObject payload) {
        return HttpRequest.BodyPublishers.ofString(payload.toString());
    }

    private void assertConfigured() {
        if (!isConfigured()) {
            throw new IllegalStateException(
                    "Supabase is not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.");
        }
    }

    private void checkStatus(HttpResponse<String> res) {
        if (res.statusCode() < 200 || res.statusCode() >= 300) {
            LOG.warning("Supabase REST request failed with status " + res.statusCode() + ".");
            throw new RuntimeException("Database request failed (" + res.statusCode() + ")");
        }
    }

    public Gson gson() { return gson; }
}
