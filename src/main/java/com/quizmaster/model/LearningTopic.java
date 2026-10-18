package com.quizmaster.model;

import java.time.Instant;
import java.util.Locale;
import java.util.List;

/** Curated topic that can be used to generate a private quiz on demand. */
public class LearningTopic {
    public static final List<String> CATEGORIES = List.of(
            "Programming", "Computer Science & IT", "AI & Data Science",
            "Psychology", "Other Learning Areas");

    public String slug;
    public String title;
    public String category;
    public String difficulty;
    public String description;
    public boolean featured;
    public Instant createdAt;

    public boolean matches(String query, String selectedCategory, String selectedDifficulty) {
        if (selectedCategory != null && !selectedCategory.isBlank()
                && !selectedCategory.equals(category)) {
            return false;
        }
        if (selectedDifficulty != null && !selectedDifficulty.isBlank()
                && !selectedDifficulty.equals(difficulty)) {
            return false;
        }
        if (query == null || query.isBlank()) return true;
        String normalized = query.trim().toLowerCase(Locale.ROOT);
        return contains(title, normalized) || contains(category, normalized)
                || contains(description, normalized);
    }

    private static boolean contains(String value, String query) {
        return value != null && value.toLowerCase(Locale.ROOT).contains(query);
    }
}
