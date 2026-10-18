package com.quizmaster.util;

import com.google.gson.JsonObject;

/**
 * Builds consistent JSON API responses.
 * Format: {"success": true/false, "data": {...}, "error": "..."}
 */
public final class JsonResponse {

    private JsonResponse() {}

    public static String ok(String dataJson) {
        return "{\"success\":true,\"data\":" + dataJson + "}";
    }

    public static String ok() {
        return "{\"success\":true}";
    }

    public static String okMessage(String message) {
        return "{\"success\":true,\"message\":" + quoted(message) + "}";
    }

    public static String error(String message) {
        return "{\"success\":false,\"error\":" + quoted(message) + "}";
    }

    public static String error(int status, String message) {
        return "{\"success\":false,\"status\":" + status + ",\"error\":" + quoted(message) + "}";
    }

    private static String quoted(String value) {
        if (value == null) return "null";
        return "\"" + value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                + "\"";
    }
}
