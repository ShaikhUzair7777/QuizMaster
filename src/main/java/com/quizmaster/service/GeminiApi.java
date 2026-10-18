package com.quizmaster.service;

/** A small seam that keeps Gemini network calls replaceable in tests. */
@FunctionalInterface
public interface GeminiApi {
    String generate(String prompt) throws GeminiException;
}
