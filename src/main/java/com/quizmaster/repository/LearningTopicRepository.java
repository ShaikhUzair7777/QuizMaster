package com.quizmaster.repository;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.quizmaster.model.LearningTopic;
import com.quizmaster.service.SupabaseDbService;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/** Reads the public, curated topic catalog, which is separate from playable quizzes. */
public class LearningTopicRepository {

    private final SupabaseDbService db;

    public LearningTopicRepository(SupabaseDbService db) {
        this.db = db;
    }

    public List<LearningTopic> findActive() throws Exception {
        JsonArray rows = db.select("learning_topics",
                "active=eq.true&order=created_at.desc,title.asc");
        List<LearningTopic> topics = new ArrayList<>(rows.size());
        for (JsonElement row : rows) topics.add(parse(row.getAsJsonObject()));
        return topics;
    }

    private LearningTopic parse(JsonObject row) {
        LearningTopic topic = new LearningTopic();
        topic.slug = text(row, "slug");
        topic.title = text(row, "title");
        topic.category = text(row, "category");
        topic.difficulty = text(row, "difficulty");
        topic.description = text(row, "description");
        topic.featured = row.has("featured") && row.get("featured").getAsBoolean();
        String createdAt = text(row, "created_at");
        if (createdAt != null) {
            try {
                topic.createdAt = Instant.parse(createdAt);
            } catch (RuntimeException ignored) {
                topic.createdAt = null;
            }
        }
        return topic;
    }

    private String text(JsonObject row, String key) {
        return row.has(key) && !row.get(key).isJsonNull()
                ? row.get(key).getAsString() : null;
    }
}
