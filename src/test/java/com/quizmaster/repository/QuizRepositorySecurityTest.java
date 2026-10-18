package com.quizmaster.repository;

import com.google.gson.*;
import com.quizmaster.model.Question;
import com.quizmaster.model.Quiz;
import com.quizmaster.service.SupabaseDbService;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class QuizRepositorySecurityTest {

    @Test
    void onlyQuizOwnerCanAccessUnpublishedQuiz() throws Exception {
        String quizId = UUID.randomUUID().toString();
        String ownerId = UUID.randomUUID().toString();
        StubDatabase db = new StubDatabase();
        db.quiz = JsonParser.parseString("""
                {"id":"%s","title":"Private","published":false,"created_by":"%s"}
                """.formatted(quizId, ownerId)).getAsJsonObject();
        QuizRepository repository = new QuizRepository(db);

        assertNull(repository.findAccessibleById(quizId, UUID.randomUUID().toString()));
        Quiz owned = repository.findAccessibleById(quizId, ownerId);
        assertNotNull(owned);
        assertEquals(ownerId, owned.createdBy);
    }

    @Test
    void publishedQuizIsAccessibleAndInvalidIdsNeverReachDatabase() throws Exception {
        String quizId = UUID.randomUUID().toString();
        StubDatabase db = new StubDatabase();
        db.quiz = JsonParser.parseString("""
                {"id":"%s","title":"Public","published":true}
                """.formatted(quizId)).getAsJsonObject();
        QuizRepository repository = new QuizRepository(db);

        assertNotNull(repository.findAccessibleById(quizId, UUID.randomUUID().toString()));
        assertThrows(IllegalArgumentException.class,
                () -> repository.findAccessibleById("x&created_by=eq.any", UUID.randomUUID().toString()));
    }

    @Test
    void studentQuestionSelectionDoesNotRequestAnswerKeysOrExplanations() throws Exception {
        StubDatabase db = new StubDatabase();
        db.questions = JsonParser.parseString("""
                [{"id":"%s","quiz_id":"%s","question_text":"Question",
                  "options":[{"id":"a","text":"A"}],"order_index":1,"marks":1}]
                """.formatted(UUID.randomUUID(), UUID.randomUUID())).getAsJsonArray();
        QuizRepository repository = new QuizRepository(db);

        Question question = repository.findQuestionsForStudent(UUID.randomUUID().toString()).getFirst();

        assertTrue(db.lastQuery.contains("select=id,quiz_id,question_text,options,order_index,marks"));
        assertFalse(db.lastQuery.contains("correct_option_id"));
        assertFalse(db.lastQuery.contains("explanation"));
        assertNull(question.correctOptionId);
        assertNull(question.explanation);
        assertFalse(new Gson().toJson(question).contains("correctOptionId"));
    }

    private static final class StubDatabase extends SupabaseDbService {
        private JsonObject quiz;
        private JsonArray questions = new JsonArray();
        private String lastQuery;

        @Override
        public JsonObject selectOne(String table, String query) {
            lastQuery = query;
            return quiz;
        }

        @Override
        public JsonArray select(String table, String query) {
            lastQuery = query;
            return questions;
        }
    }
}
