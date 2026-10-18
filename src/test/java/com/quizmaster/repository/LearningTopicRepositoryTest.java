package com.quizmaster.repository;

import com.google.gson.JsonArray;
import com.google.gson.JsonParser;
import com.quizmaster.model.LearningTopic;
import com.quizmaster.service.SupabaseDbService;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class LearningTopicRepositoryTest {

    @Test
    void loadsOnlyActiveCuratedTopicsInRecentFirstOrder() throws Exception {
        StubDatabase db = new StubDatabase();
        LearningTopicRepository repository = new LearningTopicRepository(db);

        List<LearningTopic> topics = repository.findActive();

        assertEquals("learning_topics", db.lastTable);
        assertEquals("active=eq.true&order=created_at.desc,title.asc", db.lastQuery);
        assertEquals(1, topics.size());
        assertEquals("Python Fundamentals", topics.getFirst().title);
        assertTrue(topics.getFirst().featured);
    }

    private static final class StubDatabase extends SupabaseDbService {
        private String lastTable;
        private String lastQuery;

        @Override
        public JsonArray select(String table, String query) {
            lastTable = table;
            lastQuery = query;
            return JsonParser.parseString("""
                    [{"slug":"python-fundamentals","title":"Python Fundamentals",
                      "category":"Programming","difficulty":"Beginner",
                      "description":"Practice core Python syntax.","featured":true,
                      "active":true,"created_at":"2026-10-17T12:00:00Z"}]
                    """).getAsJsonArray();
        }
    }
}
