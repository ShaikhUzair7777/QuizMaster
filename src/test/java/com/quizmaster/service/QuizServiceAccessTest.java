package com.quizmaster.service;

import com.quizmaster.model.Quiz;
import com.quizmaster.model.QuizAttempt;
import com.quizmaster.repository.AttemptRepository;
import com.quizmaster.repository.QuizRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class QuizServiceAccessTest {

    @Test
    void doesNotStartAttemptForPrivateQuizUnavailableToStudent() throws Exception {
        String quizId = UUID.randomUUID().toString();
        QuizRepository quizzes = new QuizRepository(null) {
            @Override
            public Quiz findAccessibleById(String id, String userId) {
                return null;
            }
        };
        AttemptRepository attempts = new AttemptRepository(null) {
            @Override
            public int countAttempts(String id, String userId) {
                fail("Must not create or count attempts for an inaccessible quiz.");
                return 0;
            }
        };

        QuizService.StartResult result = new QuizService(quizzes, attempts)
                .startAttempt(quizId, UUID.randomUUID().toString());

        assertFalse(result.success);
        assertEquals("Quiz not found.", result.error);
    }

    @Test
    void allowsOwnerToStartTheirPrivateQuiz() throws Exception {
        String quizId = UUID.randomUUID().toString();
        String ownerId = UUID.randomUUID().toString();
        Quiz quiz = new Quiz();
        quiz.id = quizId;
        quiz.createdBy = ownerId;
        quiz.durationMinutes = 30;
        quiz.maxAttempts = 1;
        QuizRepository quizzes = new QuizRepository(null) {
            @Override
            public Quiz findAccessibleById(String id, String userId) {
                return ownerId.equals(userId) ? quiz : null;
            }
        };
        AttemptRepository attempts = new AttemptRepository(null) {
            @Override
            public QuizAttempt findInProgress(String id, String userId) {
                return null;
            }

            @Override
            public int countAttempts(String id, String userId) {
                return 0;
            }

            @Override
            public QuizAttempt create(String id, String userId, Instant deadline) {
                QuizAttempt attempt = new QuizAttempt();
                attempt.id = UUID.randomUUID().toString();
                attempt.quizId = id;
                attempt.userId = userId;
                attempt.deadline = deadline;
                return attempt;
            }
        };

        QuizService.StartResult result = new QuizService(quizzes, attempts)
                .startAttempt(quizId, ownerId);

        assertTrue(result.success);
        assertEquals(ownerId, result.attempt.userId);
    }
}
