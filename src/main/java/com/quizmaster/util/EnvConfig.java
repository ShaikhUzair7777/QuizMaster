package com.quizmaster.util;

import java.io.*;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import java.util.logging.Logger;
import com.google.gson.JsonParser;

/**
 * Universal Environment & Properties Loader.
 * Resolves configuration in priority order:
 * 1. Operating System Environment Variables (System.getenv)
 * 2. JVM System Properties (System.getProperty)
 * 3. An external .env file in the working directory or Tomcat configuration directory.
 */
public final class EnvConfig {

    private static final Logger LOG = Logger.getLogger(EnvConfig.class.getName());
    private static final Map<String, String> FILE_VARS = new HashMap<>();

    static {
        loadDotEnv();
    }

    private EnvConfig() {}

    public static String get(String key) {
        return get(key, null);
    }

    public static String get(String key, String defaultValue) {
        if (key == null) return defaultValue;

        // 1. System Environment
        String val = System.getenv(key);
        if (val != null && !val.isBlank()) return val.trim();

        // 2. JVM System Property
        val = System.getProperty(key);
        if (val != null && !val.isBlank()) return val.trim();

        // 3. Loaded from .env file
        val = FILE_VARS.get(key);
        if (val != null && !val.isBlank()) return val.trim();

        return defaultValue;
    }

    public static boolean isConfiguredValue(String value) {
        if (value == null || value.isBlank()) return false;
        String normalized = value.trim().toLowerCase(Locale.ROOT);
        return !normalized.contains("your-")
                && !normalized.contains("your_")
                && !normalized.contains("placeholder")
                && !normalized.contains("replace-me")
                && !normalized.contains("replace_me")
                && !normalized.contains("changeme")
                && !normalized.contains("example")
                && !normalized.contains("<")
                && !normalized.contains(">");
    }

    public static boolean isValidProjectUrl(String value) {
        if (!isConfiguredValue(value)) return false;
        try {
            URI uri = URI.create(value.trim());
            String scheme = uri.getScheme();
            String path = uri.getPath();
            return ("https".equalsIgnoreCase(scheme) || "http".equalsIgnoreCase(scheme))
                    && uri.getHost() != null
                    && uri.getUserInfo() == null
                    && uri.getQuery() == null
                    && uri.getFragment() == null
                    && (path == null || path.isEmpty() || "/".equals(path));
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }

    public static boolean isValidSupabaseKey(String value, boolean serviceKey) {
        if (!isConfiguredValue(value)) return false;
        String key = value.trim();
        if (serviceKey && key.startsWith("sb_secret_")) {
            return key.length() > "sb_secret_".length();
        }
        if (!serviceKey && key.startsWith("sb_publishable_")) {
            return key.length() > "sb_publishable_".length();
        }
        String[] segments = key.split("\\.", -1);
        if (segments.length != 3 || segments[1].isEmpty()) return false;
        try {
            String payload = new String(
                    Base64.getUrlDecoder().decode(segments[1]), StandardCharsets.UTF_8);
            String role = JsonParser.parseString(payload)
                    .getAsJsonObject().get("role").getAsString();
            return serviceKey ? "service_role".equals(role) : "anon".equals(role);
        } catch (RuntimeException ex) {
            return false;
        }
    }

    private static void loadDotEnv() {
        List<File> candidates = new ArrayList<>();

        // Working directory .env
        candidates.add(new File(".env"));

        // Tomcat directories
        String catalinaBase = System.getProperty("catalina.base");
        if (catalinaBase != null) {
            candidates.add(new File(catalinaBase, ".env"));
            candidates.add(new File(catalinaBase, "conf/.env"));
        }

        String userDir = System.getProperty("user.dir");
        if (userDir != null) {
            candidates.add(new File(userDir, ".env"));
        }

        for (File f : candidates) {
            if (f.exists() && f.isFile() && f.canRead()) {
                try {
                    parseEnvLines(Files.readAllLines(f.toPath(), StandardCharsets.UTF_8));
                    LOG.info("Loaded environment variables from: " + f.getAbsolutePath());
                    return;
                } catch (Exception ex) {
                    LOG.warning("Could not parse " + f.getAbsolutePath() + ": " + ex.getMessage());
                }
            }
        }
    }

    private static void parseEnvLines(List<String> lines) {
        for (String raw : lines) {
            if (raw == null) continue;
            String line = raw.trim();
            if (line.isEmpty() || line.startsWith("#")) continue;

            int eq = line.indexOf('=');
            if (eq <= 0) continue;

            String key = line.substring(0, eq).trim();
            String val = line.substring(eq + 1).trim();

            // Strip surrounding quotes
            if ((val.startsWith("\"") && val.endsWith("\"")) ||
                (val.startsWith("'") && val.endsWith("'"))) {
                if (val.length() >= 2) {
                    val = val.substring(1, val.length() - 1);
                }
            }

            if (!key.isEmpty()) {
                FILE_VARS.put(key, val);
            }
        }
    }
}
