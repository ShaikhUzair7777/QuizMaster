package com.quizmaster.service;

import com.quizmaster.model.*;
import com.quizmaster.repository.*;

import java.time.Instant;
import java.util.*;

/**
 * Business logic for quiz attempts and scoring.
 * Scoring is always done server-side from trusted answer keys.
 */
public class QuizService {

    private final QuizRepository    quizRepo;
    private final AttemptRepository attemptRepo;

    public QuizService(QuizRepository quizRepo, AttemptRepository attemptRepo) {
        this.quizRepo    = quizRepo;
        this.attemptRepo = attemptRepo;
    }

    /**
     * Starts or resumes a quiz attempt for the given user.
     * Enforces attempt limits and availability windows.
     */
    public StartResult startAttempt(String quizId, String userId) throws Exception {
        Quiz quiz = quizRepo.findAccessibleById(quizId, userId);
        if (quiz == null) return StartResult.error("Quiz not found.");

        // Check availability window
        Instant now = Instant.now();
        if (quiz.availableFrom != null && now.isBefore(quiz.availableFrom))
            return StartResult.error("This quiz is not open yet.");
        if (quiz.availableUntil != null && now.isAfter(quiz.availableUntil))
            return StartResult.error("This quiz has closed.");

        // Check for an existing in-progress attempt (allow resume)
        QuizAttempt existing = attemptRepo.findInProgress(quizId, userId);
        if (existing != null) {
            // If deadline passed, expire it
            if (existing.deadline != null && now.isAfter(existing.deadline)) {
                scoreAndSubmit(existing.id, quizId, quiz);
                return StartResult.error("Your previous attempt has expired and was automatically submitted.");
            }
            return StartResult.resume(existing, quiz);
        }

        // Check attempt limit
        if (quiz.maxAttempts > 0) {
            int count = attemptRepo.countAttempts(quizId, userId);
            if (count >= quiz.maxAttempts)
                return StartResult.error("You have used all allowed attempts for this quiz.");
        }

        // Create new attempt
        Instant deadline = now.plusSeconds((long) quiz.durationMinutes * 60);
        QuizAttempt attempt = attemptRepo.create(quizId, userId, deadline);
        return StartResult.started(attempt, quiz);
    }

    /**
     * Server-side scoring: compares submitted answers against the answer key.
     * Returns the saved attempt with scores populated.
     */
    public QuizAttempt scoreAndSubmit(String attemptId, String quizId, Quiz quiz) throws Exception {
        // Prevent double submission
        QuizAttempt attempt = attemptRepo.findById(attemptId);
        if (attempt == null) throw new IllegalArgumentException("Attempt not found.");
        if (!Objects.equals(attempt.quizId, quizId)) {
            throw new IllegalArgumentException("Attempt does not belong to this quiz.");
        }
        if ("submitted".equals(attempt.status)) return attempt;
        if (quiz == null) throw new IllegalArgumentException("Quiz not found.");

        List<Question>     questions = quizRepo.findQuestionsWithAnswers(quizId);
        List<AttemptAnswer> answers  = attemptRepo.findAnswers(attemptId);

        // Build map: questionId -> selectedOptionId
        Map<String, String> selectedMap = new HashMap<>();
        for (AttemptAnswer a : answers) selectedMap.put(a.questionId, a.selectedOptionId);

        int correct   = 0;
        int total     = questions.size();
        int marks     = 0;
        int totalMark = 0;

        for (Question q : questions) {
            int qMark = q.marks > 0 ? q.marks : 1;
            totalMark += qMark;
            String selected = selectedMap.get(q.id);
            if (q.correctOptionId != null && q.correctOptionId.equals(selected)) {
                correct++;
                marks += qMark;
            }
        }

        double pct    = totalMark > 0 ? (marks * 100.0 / totalMark) : 0.0;
        boolean passed = quiz.passMark > 0 && pct >= quiz.passMark;

        attemptRepo.submit(attemptId, correct, total, marks, totalMark, pct, passed);

        attempt.score          = correct;
        attempt.totalQuestions = total;
        attempt.marksObtained  = marks;
        attempt.totalMarks     = totalMark;
        attempt.percentage     = pct;
        attempt.passed         = passed;
        attempt.status         = "submitted";
        return attempt;
    }

    // ── Result types ───────────────────────────────────────────────────────

    public static class StartResult {
        public final boolean       success;
        public final String        error;
        public final QuizAttempt   attempt;
        public final Quiz          quiz;
        public final boolean       resumed;

        private StartResult(boolean success, String error,
                            QuizAttempt attempt, Quiz quiz, boolean resumed) {
            this.success = success; this.error = error;
            this.attempt = attempt; this.quiz  = quiz;
            this.resumed = resumed;
        }

        static StartResult error(String msg) { return new StartResult(false, msg, null, null, false); }
        static StartResult started(QuizAttempt a, Quiz q)
            { return new StartResult(true, null, a, q, false); }
        static StartResult resume(QuizAttempt a, Quiz q)
            { return new StartResult(true, null, a, q, true); }
    }
}
