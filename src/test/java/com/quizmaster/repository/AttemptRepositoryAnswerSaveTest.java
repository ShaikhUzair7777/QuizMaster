package com.quizmaster.repository;

import com.google.gson.JsonObject;
import com.quizmaster.service.SupabaseDbService;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class AttemptRepositoryAnswerSaveTest {

    @Test
    void savesAnswerWithAtomicConflictSafeUpsert() throws Exception {
        RecordingDatabase database = new RecordingDatabase();
        AttemptRepository repository = new AttemptRepository(database);
        String attemptId = "11111111-1111-4111-8111-111111111111";
        String questionId = "22222222-2222-4222-8222-222222222222";

        repository.upsertAnswer(attemptId, questionId, "opt3");

        assertEquals("attempt_answers", database.table);
        assertEquals("attempt_id,question_id", database.conflictColumns);
        assertEquals(attemptId, database.payload.get("attempt_id").getAsString());
        assertEquals(questionId, database.payload.get("question_id").getAsString());
        assertEquals("opt3", database.payload.get("selected_option_id").getAsString());
    }

    private static final class RecordingDatabase extends SupabaseDbService {
        private String table;
        private String conflictColumns;
        private JsonObject payload;

        @Override
        public JsonObject upsert(String table, String conflictColumns, JsonObject payload) {
            this.table = table;
            this.conflictColumns = conflictColumns;
            this.payload = payload.deepCopy();
            return null;
        }
    }
}
