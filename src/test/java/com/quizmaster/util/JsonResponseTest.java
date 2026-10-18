package com.quizmaster.util;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class JsonResponseTest {

    @Test
    public void testOkDefault() {
        String json = JsonResponse.ok();
        JsonObject obj = JsonParser.parseString(json).getAsJsonObject();
        assertTrue(obj.get("success").getAsBoolean());
    }

    @Test
    public void testOkMessage() {
        String json = JsonResponse.okMessage("Operation completed");
        JsonObject obj = JsonParser.parseString(json).getAsJsonObject();
        assertTrue(obj.get("success").getAsBoolean());
        assertEquals("Operation completed", obj.get("message").getAsString());
    }

    @Test
    public void testError() {
        String json = JsonResponse.error("Invalid credentials provided");
        JsonObject obj = JsonParser.parseString(json).getAsJsonObject();
        assertFalse(obj.get("success").getAsBoolean());
        assertEquals("Invalid credentials provided", obj.get("error").getAsString());
    }
}
