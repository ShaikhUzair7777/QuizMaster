package com.quizmaster.repository;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.quizmaster.model.Question;
import com.quizmaster.model.Quiz;
import com.quizmaster.service.SupabaseDbService;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class QuizRepositoryIdempotencyTest {

    @Test
    void privateQuizSaveUsesStableDraftIdempotencyKey() throws Exception {
        StubDatabase db = new StubDatabase();
        QuizRepository repository = new QuizRepository(db);
        Quiz quiz = new Quiz();
        quiz.title = "Private practice";
        quiz.subject = "Python";
        quiz.createdBy = UUID.randomUUID().toString();
        quiz.durationMinutes = 30;
        quiz.published = false;
        Question question = new Question();
        question.questionText = "Which type is immutable?";
        question.correctOptionId = "opt1";
        question.options = new ArrayList<>();
        for (int i = 1; i <= 4; i++) {
            Question.Option option = new Question.Option();
            option.id = "opt" + i;
            option.text = "Choice " + i;
            question.options.add(option);
        }
        String draftId = UUID.randomUUID().toString();

        Quiz saved = repository.createGenerated(quiz, List.of(question), draftId);

        assertEquals("create_private_ai_quiz_idempotent", db.function);
        assertEquals(draftId, db.params.get("p_request_id").getAsString());
        assertEquals(quiz.createdBy, db.params.getAsJsonObject("p_quiz")
                .get("created_by").getAsString());
        assertFalse(db.params.getAsJsonObject("p_quiz").get("published").getAsBoolean());
        assertEquals(draftId, saved.id);
    }

    private static final class StubDatabase extends SupabaseDbService {
        private String function;
        private JsonObject params;

        @Override
        public JsonElement rpc(String function, JsonObject params) {
            this.function = function;
            this.params = params.deepCopy();
            return JsonParser.parseString("""
                    {"id":"%s","title":"Private practice","subject":"Python",
                     "created_by":"%s","published":false}
                    """.formatted(params.get("p_request_id").getAsString(),
                    params.getAsJsonObject("p_quiz").get("created_by").getAsString()));
        }
    }
}
