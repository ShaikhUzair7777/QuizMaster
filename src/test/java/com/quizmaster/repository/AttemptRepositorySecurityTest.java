package com.quizmaster.repository;

import com.google.gson.JsonObject;
import com.quizmaster.service.SupabaseDbService;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class AttemptRepositorySecurityTest {

    @Test
    void filtersAttemptLookupByBothAttemptAndAuthenticatedUser() throws Exception {
        StubDatabase db = new StubDatabase();
        AttemptRepository repository = new AttemptRepository(db);
        String attemptId = UUID.randomUUID().toString();
        String userId = UUID.randomUUID().toString();

        assertNull(repository.findByIdForUser(attemptId, userId));

        assertEquals("id=eq." + attemptId + "&user_id=eq." + userId, db.query);
    }

    @Test
    void rejectsUntrustedAttemptAndUserIdentifiers() {
        AttemptRepository repository = new AttemptRepository(null);

        assertThrows(IllegalArgumentException.class,
                () -> repository.findByIdForUser("id&user_id=eq.other", UUID.randomUUID().toString()));
        assertThrows(IllegalArgumentException.class,
                () -> repository.findByIdForUser(UUID.randomUUID().toString(), "user,select(*)"));
    }

    private static final class StubDatabase extends SupabaseDbService {
        private String query;

        @Override
        public JsonObject selectOne(String table, String filters) {
            query = filters;
            return null;
        }
    }
}
