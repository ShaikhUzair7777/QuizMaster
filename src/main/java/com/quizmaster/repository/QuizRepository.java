package com.quizmaster.repository;

import com.google.gson.*;
import com.quizmaster.model.*;
import com.quizmaster.service.SupabaseDbService;

import java.time.Instant;
import java.util.*;
import java.util.regex.Pattern;

/** Data access for quizzes and questions. */
public class QuizRepository {

    private static final Pattern UUID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

    private final SupabaseDbService db;

    public QuizRepository(SupabaseDbService db) {
        this.db = db;
    }

    /** Returns all published quizzes visible to students. */
    public List<Quiz> findPublished() throws Exception {
        JsonArray arr = db.select("quizzes",
                "published=eq.true&order=created_at.desc");
        return parseList(arr);
    }

    /** Returns all quizzes for admin management. */
    public List<Quiz> findAll() throws Exception {
        JsonArray arr = db.select("quizzes", "order=created_at.desc");
        return parseList(arr);
    }

    /** Returns private quizzes created by one authenticated owner. */
    public List<Quiz> findOwnedBy(String ownerId) throws Exception {
        requireUuid(ownerId, "owner ID");
        JsonArray arr = db.select("quizzes",
                "created_by=eq." + ownerId + "&order=created_at.desc");
        return parseList(arr);
    }

    /** Returns a quiz only when it is public or owned by the requesting student. */
    public Quiz findAccessibleById(String id, String userId) throws Exception {
        requireUuid(id, "quiz ID");
        requireUuid(userId, "user ID");
        Quiz quiz = findById(id);
        return quiz != null && (quiz.published || userId.equals(quiz.createdBy)) ? quiz : null;
    }

    public boolean isOwnedBy(String id, String ownerId) throws Exception {
        requireUuid(id, "quiz ID");
        requireUuid(ownerId, "owner ID");
        JsonObject obj = db.selectOne("quizzes",
                "id=eq." + id + "&created_by=eq." + ownerId + "&published=eq.false");
        return obj != null;
    }

    /** Returns a single quiz by ID. */
    public Quiz findById(String id) throws Exception {
        requireUuid(id, "quiz ID");
        JsonObject obj = db.selectOne("quizzes", "id=eq." + id);
        return obj != null ? parse(obj) : null;
    }

    /** Creates a new quiz and returns the saved record. */
    public Quiz create(Quiz q) throws Exception {
        JsonObject p = quizPayload(q);
        JsonObject saved = db.insert("quizzes", p);
        return saved != null ? parse(saved) : null;
    }

    /** Updates quiz fields. */
    public void update(String id, Quiz q) throws Exception {
        requireUuid(id, "quiz ID");
        db.update("quizzes", "id=eq." + id, quizPayload(q));
    }

    /** Deletes a quiz (cascades to questions/attempts via FK). */
    public void delete(String id) throws Exception {
        requireUuid(id, "quiz ID");
        db.delete("quizzes", "id=eq." + id);
    }

    /** Inserts a private AI quiz and all its questions in one PostgreSQL transaction. */
    public Quiz createGenerated(Quiz quiz, List<Question> questions) throws Exception {
        return createGenerated(quiz, questions, UUID.randomUUID().toString());
    }

    /** Idempotently inserts a private AI quiz using its server-side draft identifier. */
    public Quiz createGenerated(Quiz quiz, List<Question> questions, String requestId) throws Exception {
        requireUuid(quiz.createdBy, "owner ID");
        requireUuid(requestId, "generation request ID");
        JsonObject params = new JsonObject();
        params.add("p_quiz", quizPayload(quiz));
        JsonArray questionPayloads = new JsonArray();
        for (Question question : questions) questionPayloads.add(questionPayload(question));
        params.add("p_questions", questionPayloads);
        params.addProperty("p_request_id", requestId);
        JsonElement result = db.rpc("create_private_ai_quiz_idempotent", params);
        if (result == null || result.isJsonNull()) return null;
        if (result.isJsonArray()) {
            JsonArray rows = result.getAsJsonArray();
            return rows.isEmpty() ? null : parse(rows.get(0).getAsJsonObject());
        }
        return result.isJsonObject() ? parse(result.getAsJsonObject()) : null;
    }

    /** Deletes a private quiz only if it belongs to the supplied owner. */
    public void deleteOwned(String id, String ownerId) throws Exception {
        requireUuid(id, "quiz ID");
        requireUuid(ownerId, "owner ID");
        db.delete("quizzes", "id=eq." + id + "&created_by=eq." + ownerId
                + "&published=eq.false");
    }

    // ── Questions ─────────────────────────────────────────────────────────

    /**
     * Returns questions for a quiz WITHOUT the correct_option_id field.
     * Safe to send to students before submission.
     */
    public List<Question> findQuestionsForStudent(String quizId) throws Exception {
        requireUuid(quizId, "quiz ID");
        JsonArray arr = db.select("questions",
                "quiz_id=eq." + quizId + "&order=order_index.asc" +
                "&select=id,quiz_id,question_text,options,order_index,marks");
        return parseQuestions(arr);
    }

    /**
     * Returns questions including the correct_option_id.
     * Only use server-side for scoring — never send to the client.
     */
    public List<Question> findQuestionsWithAnswers(String quizId) throws Exception {
        requireUuid(quizId, "quiz ID");
        JsonArray arr = db.select("questions",
                "quiz_id=eq." + quizId + "&order=order_index.asc");
        return parseQuestions(arr);
    }

    public Question createQuestion(Question q) throws Exception {
        requireUuid(q.quizId, "quiz ID");
        JsonObject p = questionPayload(q);
        JsonObject saved = db.insert("questions", p);
        return saved != null ? parseQuestion(saved) : null;
    }

    public void updateQuestion(String id, Question q) throws Exception {
        requireUuid(id, "question ID");
        if (q.quizId != null) requireUuid(q.quizId, "quiz ID");
        db.update("questions", "id=eq." + id, questionPayload(q));
    }

    public void deleteQuestion(String id) throws Exception {
        requireUuid(id, "question ID");
        db.delete("questions", "id=eq." + id);
    }

    // ── Parse helpers ─────────────────────────────────────────────────────

    private List<Quiz> parseList(JsonArray arr) {
        List<Quiz> list = new ArrayList<>();
        for (JsonElement el : arr) list.add(parse(el.getAsJsonObject()));
        return list;
    }

    private Quiz parse(JsonObject o) {
        Quiz q = new Quiz();
        q.id              = str(o, "id");
        q.title           = str(o, "title");
        q.description     = str(o, "description");
        q.subject         = str(o, "subject");
        q.durationMinutes = num(o, "duration_minutes");
        q.questionCount   = num(o, "question_count");
        q.published       = bool(o, "published");
        q.maxAttempts     = num(o, "max_attempts");
        q.createdBy       = str(o, "created_by");
        q.passMark        = num(o, "pass_mark");
        String ca = str(o, "created_at");
        if (ca != null) try { q.createdAt = Instant.parse(ca); } catch (Exception ignored) {}
        return q;
    }

    private List<Question> parseQuestions(JsonArray arr) {
        List<Question> list = new ArrayList<>();
        for (JsonElement el : arr) list.add(parseQuestion(el.getAsJsonObject()));
        list.sort(Comparator.comparingInt(question -> question.orderIndex));
        return list;
    }

    private Question parseQuestion(JsonObject o) {
        Question q = new Question();
        q.id              = str(o, "id");
        q.quizId          = str(o, "quiz_id");
        q.questionText    = str(o, "question_text");
        q.orderIndex      = num(o, "order_index");
        q.marks           = num(o, "marks");
        q.correctOptionId = str(o, "correct_option_id");
        q.explanation     = str(o, "explanation");

        q.options = new ArrayList<>();
        if (o.has("options") && o.get("options").isJsonArray()) {
            for (JsonElement el : o.getAsJsonArray("options")) {
                JsonObject oo = el.getAsJsonObject();
                Question.Option opt = new Question.Option();
                opt.id   = str(oo, "id");
                opt.text = str(oo, "text");
                q.options.add(opt);
            }
        }
        return q;
    }

    private JsonObject quizPayload(Quiz q) {
        JsonObject p = new JsonObject();
        if (q.title           != null) p.addProperty("title",            q.title);
        if (q.description     != null) p.addProperty("description",      q.description);
        if (q.subject         != null) p.addProperty("subject",          q.subject);
        p.addProperty("duration_minutes", q.durationMinutes);
        p.addProperty("published",        q.published);
        p.addProperty("max_attempts",     q.maxAttempts > 0 ? q.maxAttempts : 1);
        p.addProperty("pass_mark",        q.passMark);
        if (q.createdBy       != null) p.addProperty("created_by",       q.createdBy);
        return p;
    }

    private JsonObject questionPayload(Question q) {
        JsonObject p = new JsonObject();
        if (q.quizId       != null) p.addProperty("quiz_id",           q.quizId);
        if (q.questionText != null) p.addProperty("question_text",     q.questionText);
        p.addProperty("order_index",      q.orderIndex);
        p.addProperty("marks",            q.marks > 0 ? q.marks : 1);
        if (q.correctOptionId != null) p.addProperty("correct_option_id", q.correctOptionId);
        if (q.explanation != null) p.addProperty("explanation", q.explanation);
        if (q.options != null) {
            JsonArray opts = new JsonArray();
            for (Question.Option o : q.options) {
                JsonObject oo = new JsonObject();
                oo.addProperty("id",   o.id);
                oo.addProperty("text", o.text);
                opts.add(oo);
            }
            p.add("options", opts);
        }
        return p;
    }

    // ── Field readers ─────────────────────────────────────────────────────

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
