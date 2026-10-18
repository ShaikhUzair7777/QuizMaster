package com.quizmaster.service;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.quizmaster.util.EnvConfig;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.regex.Pattern;

public class SupabaseAuthService {

    private static final Pattern UUID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

    private final String projectUrl;
    private final String apiKey;
    private final String serviceKey;
    private final HttpClient client;

    public SupabaseAuthService() {
        this.projectUrl = EnvConfig.get("SUPABASE_URL");
        this.apiKey = EnvConfig.get("SUPABASE_ANON_KEY");
        this.serviceKey = EnvConfig.get("SUPABASE_SERVICE_ROLE_KEY");
        this.client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    public AuthResult register(String fullName, String email, String password)
            throws Exception {
        if (hasServiceKey()) {
            JsonObject adminPayload = new JsonObject();
            adminPayload.addProperty("email", email);
            adminPayload.addProperty("password", password);
            adminPayload.addProperty("email_confirm", true);

            JsonObject metadata = new JsonObject();
            metadata.addProperty("full_name", fullName);
            adminPayload.add("user_metadata", metadata);

            JsonObject adminResult = sendWithKey(
                    "/auth/v1/admin/users", adminPayload, serviceKey);
            if (adminResult.has("id")) {
                return login(email, password);
            }
            return new AuthResult(false, errorMessage(adminResult),
                    null, null, null, null, null);
        }

        JsonObject payload = new JsonObject();
        payload.addProperty("email", email);
        payload.addProperty("password", password);

        JsonObject metadata = new JsonObject();
        metadata.addProperty("full_name", fullName);
        payload.add("data", metadata);

        JsonObject result = send("/auth/v1/signup", payload);
        if (result.has("access_token")) {
            String userId = readUserValue(result, "id");
            String name = readMetaValue(result, "full_name");
            Profile profile = readProfile(userId, name);
            return new AuthResult(true, "Account created successfully.",
                    result.get("access_token").getAsString(), userId, email,
                    profile.fullName != null ? profile.fullName : fullName, profile.role);
        }

        if (result.has("id") || result.has("user")) {
            return new AuthResult(true,
                    "Registration received. Check your email if confirmation is required, then sign in.",
                    null, readUserValue(result, "id"), email, fullName, "student");
        }
        return new AuthResult(false, errorMessage(result),
                null, null, null, null, null);
    }

    public AuthResult login(String email, String password) throws Exception {
        JsonObject payload = new JsonObject();
        payload.addProperty("email", email);
        payload.addProperty("password", password);

        JsonObject result = send("/auth/v1/token?grant_type=password", payload);
        if (!result.has("access_token")) {
            return new AuthResult(false, errorMessage(result),
                    null, null, null, null, null);
        }

        String userId = readUserValue(result, "id");
        String metadataName = readMetaValue(result, "full_name");
        Profile profile = readProfile(userId, metadataName);
        return new AuthResult(true, "Signed in successfully.",
                result.get("access_token").getAsString(), userId, email,
                profile.fullName, profile.role);
    }

    private JsonObject send(String endpoint, JsonObject payload) throws Exception {
        return sendWithKey(endpoint, payload, apiKey);
    }

    private JsonObject sendWithKey(String endpoint, JsonObject payload, String keyToUse)
            throws Exception {
        boolean privilegedKey = keyToUse != null && keyToUse.equals(serviceKey);
        if (!EnvConfig.isValidProjectUrl(projectUrl)
                || !EnvConfig.isValidSupabaseKey(keyToUse, privilegedKey)) {
            throw new SupabaseConfigurationException(
                    "Supabase is not configured. Set valid SUPABASE_URL and SUPABASE_ANON_KEY values.");
        }

        HttpRequest.Builder requestBuilder = HttpRequest.newBuilder()
                .uri(URI.create(projectUrl.replaceAll("/+$", "") + endpoint))
                .timeout(Duration.ofSeconds(20))
                .header("User-Agent", "QuizMaster-Backend/1.0")
                .header("Content-Type", "application/json")
                .header("apikey", keyToUse);
        if (keyToUse.split("\\.", -1).length == 3) {
            requestBuilder.header("Authorization", "Bearer " + keyToUse);
        }

        HttpRequest request = requestBuilder
                .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                .build();
        HttpResponse<String> response = client.send(
                request, HttpResponse.BodyHandlers.ofString());
        JsonObject result = parseObject(response);
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            return result;
        }
        return result;
    }

    private Profile readProfile(String userId, String metadataName) throws Exception {
        if (!hasServiceKey() || userId == null
                || !UUID_PATTERN.matcher(userId).matches()) {
            return new Profile(metadataName, "student");
        }

        String url = projectUrl.replaceAll("/+$", "")
                + "/rest/v1/user_profiles?id=eq." + userId
                + "&select=role,full_name&limit=1";
        HttpRequest.Builder requestBuilder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(20))
                .header("User-Agent", "QuizMaster-Backend/1.0")
                .header("apikey", serviceKey);
        if (serviceKey.split("\\.", -1).length == 3) {
            requestBuilder.header("Authorization", "Bearer " + serviceKey);
        }

        HttpResponse<String> response = client.send(
                requestBuilder.GET().build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException("Unable to verify the account profile.");
        }

        JsonElement parsed = JsonParser.parseString(response.body());
        if (!parsed.isJsonArray()) {
            throw new IllegalStateException("Supabase returned an unexpected profile response.");
        }
        JsonArray profiles = parsed.getAsJsonArray();
        if (profiles.isEmpty()) {
            return new Profile(metadataName, "student");
        }

        JsonObject profile = profiles.get(0).getAsJsonObject();
        String role = readString(profile, "role");
        String fullName = readString(profile, "full_name");
        return new Profile(fullName != null ? fullName : metadataName,
                "admin".equals(role) ? "admin" : "student");
    }

    private boolean hasServiceKey() {
        return EnvConfig.isValidProjectUrl(projectUrl)
                && EnvConfig.isValidSupabaseKey(serviceKey, true);
    }

    private JsonObject parseObject(HttpResponse<String> response) {
        try {
            JsonElement parsed = JsonParser.parseString(response.body());
            if (parsed.isJsonObject()) return parsed.getAsJsonObject();
        } catch (RuntimeException ignored) {
            // The caller receives a safe message without response data or credentials.
        }
        throw new IllegalStateException(
                "Supabase returned an unexpected response (" + response.statusCode() + ").");
    }

    private String errorMessage(JsonObject result) {
        for (String field : new String[]{"msg", "message", "error_description", "error"}) {
            String value = readString(result, field);
            if (value != null && !value.isBlank()) return value;
        }
        return "Authentication failed. Please check your details and try again.";
    }

    private String readUserValue(JsonObject result, String field) {
        String value = readString(result, field);
        if (value != null) return value;
        if (result.has("user") && result.get("user").isJsonObject()) {
            return readString(result.getAsJsonObject("user"), field);
        }
        return null;
    }

    private String readMetaValue(JsonObject result, String field) {
        JsonObject user = result.has("user") && result.get("user").isJsonObject()
                ? result.getAsJsonObject("user") : result;
        if (user.has("user_metadata") && user.get("user_metadata").isJsonObject()) {
            return readString(user.getAsJsonObject("user_metadata"), field);
        }
        return null;
    }

    private String readString(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull()
                ? object.get(field).getAsString() : null;
    }

    public static class AuthResult {
        public final boolean success;
        public final String message;
        public final String accessToken;
        public final String userId;
        public final String email;
        public final String fullName;
        public final String role;

        public AuthResult(boolean success, String message, String accessToken,
                          String userId, String email, String fullName, String role) {
            this.success = success;
            this.message = message;
            this.accessToken = accessToken;
            this.userId = userId;
            this.email = email;
            this.fullName = fullName;
            this.role = role;
        }
    }

    public static class SupabaseConfigurationException extends IllegalStateException {
        public SupabaseConfigurationException(String message) {
            super(message);
        }
    }

    private static final class Profile {
        private final String fullName;
        private final String role;

        private Profile(String fullName, String role) {
            this.fullName = fullName;
            this.role = role;
        }
    }
}
