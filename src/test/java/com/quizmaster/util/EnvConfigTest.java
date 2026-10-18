package com.quizmaster.util;

import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class EnvConfigTest {

    @Test
    void validatesSupabaseUrlAndRejectsTemplateValues() {
        assertTrue(EnvConfig.isValidProjectUrl("https://project-ref.supabase.co"));
        assertTrue(EnvConfig.isValidProjectUrl("http://127.0.0.1:54321"));
        assertFalse(EnvConfig.isValidProjectUrl("https://<project-ref>.supabase.co"));
        assertFalse(EnvConfig.isValidProjectUrl("file:///project"));
        assertFalse(EnvConfig.isValidProjectUrl("https://user:password@project-ref.supabase.co"));
    }

    @Test
    void acceptsSupportedServerAndPublicKeyFormatsOnly() {
        assertTrue(EnvConfig.isValidSupabaseKey("sb_publishable_test-key", false));
        assertTrue(EnvConfig.isValidSupabaseKey("sb_secret_test-key", true));
        assertTrue(EnvConfig.isValidSupabaseKey(legacyJwt("anon"), false));
        assertTrue(EnvConfig.isValidSupabaseKey(legacyJwt("service_role"), true));
        assertFalse(EnvConfig.isValidSupabaseKey("your-supabase-anon-key", false));
        assertFalse(EnvConfig.isValidSupabaseKey("sb_secret_test-key", false));
        assertFalse(EnvConfig.isValidSupabaseKey("sb_publishable_test-key", true));
        assertFalse(EnvConfig.isValidSupabaseKey(legacyJwt("anon"), true));
        assertFalse(EnvConfig.isValidSupabaseKey(legacyJwt("service_role"), false));
        assertFalse(EnvConfig.isValidSupabaseKey("header.payload.signature", true));
    }

    private String legacyJwt(String role) {
        String payload = Base64.getUrlEncoder().withoutPadding().encodeToString(
                ("{\"role\":\"" + role + "\"}").getBytes(StandardCharsets.UTF_8));
        return "header." + payload + ".signature";
    }
}
