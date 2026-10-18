package com.quizmaster.controller;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class AiQuizServletRateLimitTest {

    @Test
    void releasingFailedGenerationReservationAllowsImmediateRetry() {
        AiQuizServlet servlet = new AiQuizServlet();
        String userId = UUID.randomUUID().toString();
        Instant reservation = servlet.checkRateLimit(userId);

        RuntimeException cooldown = assertThrows(RuntimeException.class,
                () -> servlet.checkRateLimit(userId));
        assertTrue(cooldown.getMessage().contains("20 seconds"));

        servlet.releaseRateLimit(userId, reservation);
        Instant retryReservation = assertDoesNotThrow(() -> servlet.checkRateLimit(userId));
        servlet.releaseRateLimit(userId, retryReservation);
    }
}
