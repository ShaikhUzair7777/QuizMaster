package com.quizmaster.repository;

import com.google.gson.*;
import com.quizmaster.model.*;
import com.quizmaster.service.SupabaseDbService;

import java.time.Instant;
import java.util.*;
import java.util.regex.Pattern;

/** Data access for quiz attempts and answers. */
public class AttemptRepository {

    private static final Pattern UUID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

    private final SupabaseDbService db;

    public AttemptRepository(SupabaseDbService db) {
        this.db = db;
    }

    /**
     * Creates a new in-progress attempt.
     * @return saved attempt with assigned ID.
     */
    public QuizAttempt create(String quizId, String userId, Instant deadline) throws Exception {
        requireUuid(quizId, "quiz ID");
        requireUuid(userId, "user ID");
        JsonObject p = new JsonObject();
        p.addProperty("quiz_id",    quizId);
        p.addProperty("user_id",    userId);
        p.addProperty("status",     "in_progress");
        p.addProperty("deadline",   deadline.toString());
        p.addProperty("started_at", Instant.now().toString());
        JsonObject saved = db.insert("quiz_attempts", p);
        return saved != null ? parse(saved) : null;
    }

    /**
     * Finds an in-progress attempt for a given user+quiz combination.
     * Used to restore state after page refresh.
     */
    public QuizAttempt findInProgress(String quizId, String userId) throws Exception {
        requireUuid(quizId, "quiz ID");
        requireUuid(userId, "user ID");
        JsonObject obj = db.selectOne("quiz_attempts",
                "quiz_id=eq." + quizId +
                "&user_id=eq." + userId +
                "&status=eq.in_progress");
        return obj != null ? parse(obj) : null;
    }

    /** Finds a submitted/expired attempt by ID (used for results). */
    public QuizAttempt findById(String attemptId) throws Exception {
        requireUuid(attemptId, "attempt ID");
        JsonObject obj = db.selectOne("quiz_attempts", "id=eq." + attemptId);
        return obj != null ? parse(obj) : null;
    }

    /** Looks up an attempt only within the authenticated user's records. */
    public QuizAttempt findByIdForUser(String attemptId, String userId) throws Exception {
        requireUuid(attemptId, "attempt ID");
        requireUuid(userId, "user ID");
        JsonObject obj = db.selectOne("quiz_attempts",
                "id=eq." + attemptId + "&user_id=eq." + userId);
        return obj != null ? parse(obj) : null;
    }

    /** Returns all completed attempts for a user ordered by most recent. */
    public List<QuizAttempt> findByUser(String userId) throws Exception {
        requireUuid(userId, "user ID");
        JsonArray arr = db.select("quiz_attempts",
                "user_id=eq." + userId +
                "&status=in.(submitted,expired)&order=submitted_at.desc");
        return parseList(arr);
    }

    /** Counts how many times a user has attempted a quiz. */
    public int countAttempts(String quizId, String userId) throws Exception {
        requireUuid(quizId, "quiz ID");
        requireUuid(userId, "user ID");
        JsonArray arr = db.select("quiz_attempts",
                "quiz_id=eq." + quizId + "&user_id=eq." + userId);
        return arr.size();
    }

    /** Saves or updates an answer for an in-progress attempt. */
    public void upsertAnswer(String attemptId, String questionId, String selectedOptionId) throws Exception {
        requireUuid(attemptId, "attempt ID");
        requireUuid(questionId, "question ID");
        JsonObject p = new JsonObject();
        p.addProperty("attempt_id",         attemptId);
        p.addProperty("question_id",        questionId);
        p.addProperty("selected_option_id", selectedOptionId);
        db.upsert("attempt_answers", "attempt_id,question_id", p);
    }

    /** Returns all saved answers for an attempt. */
    public List<AttemptAnswer> findAnswers(String attemptId) throws Exception {
        requireUuid(attemptId, "attempt ID");
        JsonArray arr = db.select("attempt_answers", "attempt_id=eq." + attemptId);
        List<AttemptAnswer> list = new ArrayList<>();
        for (JsonElement el : arr) {
            JsonObject o = el.getAsJsonObject();
            AttemptAnswer a = new AttemptAnswer();
            a.attemptId        = str(o, "attempt_id");
            a.questionId       = str(o, "question_id");
            a.selectedOptionId = str(o, "selected_option_id");
            a.correct          = bool(o, "correct");
            list.add(a);
        }
        return list;
    }

    /** Marks the attempt as submitted and stores the final score. */
    public void submit(String attemptId, int score, int totalQuestions,
                       int marksObtained, int totalMarks, double percentage,
                       boolean passed) throws Exception {
        requireUuid(attemptId, "attempt ID");
        JsonObject p = new JsonObject();
        p.addProperty("status",          "submitted");
        p.addProperty("submitted_at",    Instant.now().toString());
        p.addProperty("score",           score);
        p.addProperty("total_questions", totalQuestions);
        p.addProperty("marks_obtained",  marksObtained);
        p.addProperty("total_marks",     totalMarks);
        p.addProperty("percentage",      percentage);
        p.addProperty("passed",          passed);
        db.update("quiz_attempts", "id=eq." + attemptId, p);
    }

    /** Marks overdue in-progress attempts as expired. */
    public void expireOverdue() throws Exception {
        JsonObject p = new JsonObject();
        p.addProperty("status", "expired");
        p.addProperty("submitted_at", Instant.now().toString());
        db.update("quiz_attempts",
                "status=eq.in_progress&deadline=lt." + Instant.now().toString(), p);
    }

    /** Admin: all attempts for all users. */
    public List<QuizAttempt> findAllForAdmin() throws Exception {
        JsonArray arr = db.select("quiz_attempts", "order=started_at.desc");
        return parseList(arr);
    }

    // ── Parse helpers ─────────────────────────────────────────────────────

    private List<QuizAttempt> parseList(JsonArray arr) {
        List<QuizAttempt> list = new ArrayList<>();
        for (JsonElement el : arr) list.add(parse(el.getAsJsonObject()));
        return list;
    }

    private QuizAttempt parse(JsonObject o) {
        QuizAttempt a = new QuizAttempt();
        a.id             = str(o, "id");
        a.quizId         = str(o, "quiz_id");
        a.userId         = str(o, "user_id");
        a.status         = str(o, "status");
        a.score          = num(o, "score");
        a.totalQuestions = num(o, "total_questions");
        a.totalMarks     = num(o, "total_marks");
        a.marksObtained  = num(o, "marks_obtained");
        a.passed         = bool(o, "passed");
        try { a.percentage = o.has("percentage") && !o.get("percentage").isJsonNull()
                ? o.get("percentage").getAsDouble() : 0.0; } catch (Exception ignored) {}
        String sa = str(o, "started_at");
        String su = str(o, "submitted_at");
        String dl = str(o, "deadline");
        try { if (sa != null) a.startedAt   = Instant.parse(sa); } catch (Exception ignored) {}
        try { if (su != null) a.submittedAt = Instant.parse(su); } catch (Exception ignored) {}
        try { if (dl != null) a.deadline    = Instant.parse(dl); } catch (Exception ignored) {}
        return a;
    }

    private String str(JsonObject o, String key) {
        return (o.has(key) && !o.get(key).isJsonNull()) ? o.get(key).getAsString() : null;
    }

    private int num(JsonObject o, String key) {
        return (o.has(key) && !o.get(key).isJsonNull()) ? o.get(key).getAsInt() : 0;
    }

    private boolean bool(JsonObject o, String key) {
        return o.has(key) && !o.get(key).isJsonNull() && o.get(key).getAsBoolean();
    }

    private void requireUuid(String value, String label) {
        if (value == null || !UUID_PATTERN.matcher(value).matches()) {
            throw new IllegalArgumentException("Invalid " + label + ".");
        }
    }
}
