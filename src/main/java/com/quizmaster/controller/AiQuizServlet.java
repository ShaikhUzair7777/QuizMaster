package com.quizmaster.controller;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.quizmaster.model.Question;
import com.quizmaster.model.Quiz;
import com.quizmaster.repository.QuizRepository;
import com.quizmaster.service.*;
import com.quizmaster.util.JsonResponse;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.logging.Logger;

/** Student-owned AI quiz generation, preview, and private quiz management. */
@WebServlet(urlPatterns = {
        "/student/ai-quizzes", "/student/ai-quizzes/generate",
        "/student/ai-quizzes/save", "/student/ai-quizzes/preview",
        "/student/my-quizzes", "/student/my-quizzes/delete"
})
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 14 * 1024 * 1024,
        fileSizeThreshold = 256 * 1024)
public class AiQuizServlet extends HttpServlet {

    private static final Logger LOG = Logger.getLogger(AiQuizServlet.class.getName());
    private static final String DRAFTS_ATTRIBUTE = AiQuizServlet.class.getName() + ".drafts";
    private static final Duration DRAFT_LIFETIME = Duration.ofMinutes(30);
    private static final Map<String, List<Instant>> GENERATION_TIMES = new HashMap<>();

    private QuizRepository quizRepo;
    private QuizGenerationService generationService;

    @Override
    public void init() {
        quizRepo = new QuizRepository(new SupabaseDbService());
        generationService = new QuizGenerationService(new GeminiApiClient());
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        String path = req.getServletPath();
        try {
            switch (path) {
                case "/student/ai-quizzes" ->
                        req.getRequestDispatcher("/WEB-INF/views/student/ai-quizzes.jsp").forward(req, res);
                case "/student/my-quizzes" -> {
                    List<Quiz> quizzes = quizRepo.findOwnedBy(userId(req));
                    req.setAttribute("quizzes", quizzes);
                    req.getRequestDispatcher("/WEB-INF/views/student/my-quizzes.jsp").forward(req, res);
                }
                case "/student/ai-quizzes/preview" -> showPreview(req, res);
                default -> res.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (IllegalArgumentException ex) {
            res.sendError(HttpServletResponse.SC_BAD_REQUEST, "The supplied identifier is invalid.");
        } catch (Exception ex) {
            LOG.warning("Could not load AI quiz page.");
            getServletContext().log("Could not load AI quiz page.", ex);
            res.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Could not load this page. Please try again.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String path = req.getServletPath();
        if ("/student/ai-quizzes/generate".equals(path)) {
            generate(req, res);
        } else if ("/student/ai-quizzes/save".equals(path)) {
            save(req, res);
        } else if ("/student/my-quizzes/delete".equals(path)) {
            delete(req, res);
        } else {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void generate(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        String userId = userId(req);
        String subject;
        String category;
        String instructions;
        String difficulty;
        String questionType;
        String mode;
        int count;
        int duration;
        String sourceText;

        try {
            subject = req.getParameter("subject");
            category = req.getParameter("category");
            instructions = req.getParameter("instructions");
            difficulty = req.getParameter("difficulty");
            questionType = req.getParameter("questionType");
            if (questionType == null || questionType.isBlank()) questionType = "MULTIPLE_CHOICE";
            mode = req.getParameter("mode");
            if (mode == null || mode.isBlank()) mode = "TOPIC";
            if (!Set.of("TOPIC", "MATERIAL").contains(mode)) {
                throw new IllegalArgumentException("Choose topic or study-material mode.");
            }
            count = parseInteger(req.getParameter("questionCount"), 10);
            duration = parseInteger(req.getParameter("durationMinutes"), 30);
            QuizGenerationService.validateDuration(duration);
            sourceText = "MATERIAL".equals(mode) ? extractSource(req) : null;
            if ("MATERIAL".equals(mode) && (sourceText == null || sourceText.isBlank())) {
                throw new IllegalArgumentException(
                        "Add study notes or upload a readable document in study-material mode.");
            }
            if ("MATERIAL".equals(mode) && (subject == null || subject.isBlank())) {
                subject = "Study material";
            }
            QuizGenerationService.validateRequest(subject, instructions, difficulty, count,
                    sourceText, category, questionType);
            ensureDraftCapacity(req.getSession(false));
            Instant rateReservation = checkRateLimit(userId);
            GeneratedQuiz quiz;
            try {
                quiz = generationService.generate(subject, category, instructions,
                        difficulty, count, questionType, sourceText);
            } catch (GeminiException | RuntimeException ex) {
                releaseRateLimit(userId, rateReservation);
                throw ex;
            }
            Map<String, GeneratedQuiz> drafts = drafts(req.getSession(false));
            synchronized (drafts) {
                purgeExpiredDrafts(drafts);
                if (drafts.size() >= 3) {
                    throw new IllegalArgumentException(
                            "You have three unsaved drafts. Save or discard one before generating another.");
                }
                drafts.put(quiz.draftId, quiz);
            }
            writePreview(res, quiz, duration);
        } catch (IllegalArgumentException ex) {
            res.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            res.getWriter().write(JsonResponse.error(ex.getMessage()));
        } catch (RateLimitException ex) {
            res.setStatus(429);
            res.getWriter().write(JsonResponse.error(ex.getMessage()));
        } catch (GeminiException ex) {
            res.setStatus(HttpServletResponse.SC_BAD_GATEWAY);
            res.getWriter().write(JsonResponse.error(ex.getMessage()));
        } catch (IllegalStateException ex) {
            res.setStatus(HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE);
            res.getWriter().write(JsonResponse.error("Uploaded files must be no larger than 10 MB."));
        } catch (Exception ex) {
            LOG.warning("AI quiz generation failed.");
            getServletContext().log("AI quiz generation failed.", ex);
            res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            res.getWriter().write(JsonResponse.error(
                    "Could not generate the quiz. Check the AI and database configuration, then try again."));
        }
    }

    private void save(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        try {
            JsonObject body;
            try {
                body = JsonParser.parseString(readBody(req, 8_192)).getAsJsonObject();
            } catch (RuntimeException ex) {
                throw new IllegalArgumentException("Invalid save request.");
            }
            String draftId = body.has("draftId") && body.get("draftId").isJsonPrimitive()
                    ? body.get("draftId").getAsString() : null;
            int duration = parseJsonInteger(body, "durationMinutes", 30);
            int passMark = parseJsonInteger(body, "passMark", 50);
            if (draftId == null || !isUuid(draftId)) {
                throw new IllegalArgumentException("The quiz draft is invalid or expired.");
            }
            if (duration < 1 || duration > 300 || passMark < 0 || passMark > 100) {
                throw new IllegalArgumentException("Duration or pass mark is outside the allowed range.");
            }

            HttpSession session = req.getSession(false);
            Map<String, GeneratedQuiz> drafts = drafts(session);
            GeneratedQuiz draft;
            synchronized (drafts) {
                purgeExpiredDrafts(drafts);
                draft = drafts.remove(draftId);
            }
            if (draft == null) {
                throw new IllegalArgumentException("The quiz draft has expired. Generate it again.");
            }

            Quiz quiz = new Quiz();
            quiz.title = draft.title;
            quiz.description = "AI-generated practice quiz. Review questions and answers before use.";
            quiz.subject = draft.subject;
            quiz.durationMinutes = duration;
            quiz.questionCount = draft.questions.size();
            quiz.published = false;
            quiz.maxAttempts = 1;
            quiz.passMark = passMark;
            quiz.createdBy = userId(req);

            Quiz saved;
            try {
                saved = quizRepo.createGenerated(quiz, draft.questions, draft.draftId);
                if (saved == null || saved.id == null) {
                    throw new IllegalStateException("Database did not return the saved quiz.");
                }
            } catch (Exception ex) {
                synchronized (drafts) {
                    drafts.putIfAbsent(draftId, draft);
                }
                throw ex;
            }
            JsonObject result = new JsonObject();
            result.addProperty("id", saved.id);
            res.getWriter().write(JsonResponse.ok(result.toString()));
        } catch (IllegalArgumentException ex) {
            res.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            res.getWriter().write(JsonResponse.error(ex.getMessage()));
        } catch (Exception ex) {
            LOG.warning("Could not save private AI quiz.");
            getServletContext().log("Could not save private AI quiz.", ex);
            res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            res.getWriter().write(JsonResponse.error(
                    "Could not save this quiz. Verify that 001_ai_quiz_generation.sql and "
                            + "003_idempotent_ai_quiz_saves.sql have been applied in Supabase."));
        }
    }

    private void delete(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        String id = req.getParameter("id");
        String ownerId = userId(req);
        try {
            if (!isUuid(id)) {
                res.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                res.getWriter().write(JsonResponse.error("Invalid quiz ID."));
                return;
            }
            if (!quizRepo.isOwnedBy(id, ownerId)) {
                res.setStatus(HttpServletResponse.SC_NOT_FOUND);
                res.getWriter().write(JsonResponse.error("Quiz not found."));
                return;
            }
            quizRepo.deleteOwned(id, ownerId);
            res.getWriter().write(JsonResponse.okMessage("Private quiz deleted."));
        } catch (Exception ex) {
            LOG.warning("Could not delete private quiz.");
            getServletContext().log("Could not delete private quiz.", ex);
            res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            res.getWriter().write(JsonResponse.error("Could not delete this quiz."));
        }
    }

    private void showPreview(HttpServletRequest req, HttpServletResponse res)
            throws Exception {
        String id = req.getParameter("id");
        if (!isUuid(id)) {
            res.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid quiz ID.");
            return;
        }
        String userId = userId(req);
        Quiz quiz = quizRepo.findById(id);
        if (quiz == null || !userId.equals(quiz.createdBy)) {
            res.sendError(HttpServletResponse.SC_NOT_FOUND, "Quiz not found.");
            return;
        }
        req.setAttribute("quiz", quiz);
        req.setAttribute("questions", quizRepo.findQuestionsWithAnswers(id));
        req.getRequestDispatcher("/WEB-INF/views/student/ai-quiz-preview.jsp").forward(req, res);
    }

    private String extractSource(HttpServletRequest req) throws Exception {
        String notes = req.getParameter("studyNotes");
        if (notes != null && notes.length() > QuizGenerationService.MAX_SOURCE_LENGTH) {
            throw new IllegalArgumentException("Study notes must be no longer than 300,000 characters.");
        }
        String contentType = req.getContentType();
        String extractedFile = null;
        if (contentType != null
                && contentType.toLowerCase(Locale.ROOT).startsWith("multipart/form-data")) {
            Part file = req.getPart("sourceFile");
            if (file != null) {
                String name = file.getSubmittedFileName();
                if (name != null && !name.isBlank()) {
                    if (file.getSize() == 0) {
                        throw new IllegalArgumentException("The selected source file is empty.");
                    }
                    byte[] bytes;
                    try (var input = file.getInputStream()) {
                        bytes = input.readNBytes(SourceMaterialExtractor.MAX_FILE_BYTES + 1);
                    }
                    extractedFile = SourceMaterialExtractor.extract(
                            name, file.getContentType(), bytes);
                }
            }
        }
        if ((notes == null || notes.isBlank()) && extractedFile == null) return null;
        String combined = (notes == null || notes.isBlank()) ? extractedFile
                : (extractedFile == null ? notes : notes + "\n\n" + extractedFile);
        if (combined.length() > QuizGenerationService.MAX_SOURCE_LENGTH) {
            throw new IllegalArgumentException(
                    "Combined study notes are too long. Keep the extracted text under 300,000 characters.");
        }
        return combined;
    }

    private void writePreview(HttpServletResponse res, GeneratedQuiz draft, int duration)
            throws IOException {
        JsonObject data = new JsonObject();
        data.addProperty("draftId", draft.draftId);
        data.addProperty("title", draft.title);
        data.addProperty("subject", draft.subject);
        data.addProperty("durationMinutes", duration);
        com.google.gson.JsonArray previewQuestions = new com.google.gson.JsonArray();
        for (Question question : draft.questions) {
            JsonObject safeQuestion = new JsonObject();
            safeQuestion.addProperty("id", question.id);
            safeQuestion.addProperty("questionText", question.questionText);
            safeQuestion.addProperty("orderIndex", question.orderIndex);
            safeQuestion.addProperty("marks", question.marks);
            safeQuestion.addProperty("correctOptionId", question.correctOptionId);
            safeQuestion.addProperty("explanation", question.explanation);
            com.google.gson.JsonArray options = new com.google.gson.JsonArray();
            for (Question.Option option : question.options) {
                JsonObject safeOption = new JsonObject();
                safeOption.addProperty("id", option.id);
                safeOption.addProperty("text", option.text);
                options.add(safeOption);
            }
            safeQuestion.add("options", options);
            previewQuestions.add(safeQuestion);
        }
        data.add("questions", previewQuestions);
        res.getWriter().write(JsonResponse.ok(data.toString()));
    }

    private Map<String, GeneratedQuiz> drafts(HttpSession session) {
        @SuppressWarnings("unchecked")
        Map<String, GeneratedQuiz> existing =
                (Map<String, GeneratedQuiz>) session.getAttribute(DRAFTS_ATTRIBUTE);
        if (existing != null) return existing;
        synchronized (session) {
            @SuppressWarnings("unchecked")
            Map<String, GeneratedQuiz> concurrent =
                    (Map<String, GeneratedQuiz>) session.getAttribute(DRAFTS_ATTRIBUTE);
            if (concurrent != null) return concurrent;
            Map<String, GeneratedQuiz> created = new HashMap<>();
            session.setAttribute(DRAFTS_ATTRIBUTE, created);
            return created;
        }
    }

    private void purgeExpiredDrafts(Map<String, GeneratedQuiz> drafts) {
        Instant cutoff = Instant.now().minus(DRAFT_LIFETIME);
        drafts.values().removeIf(draft -> draft.createdAt.isBefore(cutoff));
    }

    private void ensureDraftCapacity(HttpSession session) {
        Map<String, GeneratedQuiz> pendingDrafts = drafts(session);
        synchronized (pendingDrafts) {
            purgeExpiredDrafts(pendingDrafts);
            if (pendingDrafts.size() >= 3) {
                throw new IllegalArgumentException(
                        "You have three unsaved drafts. Save or discard one before generating another.");
            }
        }
    }

    Instant checkRateLimit(String userId) {
        Instant now = Instant.now();
        synchronized (GENERATION_TIMES) {
            GENERATION_TIMES.entrySet().removeIf(entry ->
                    entry.getValue().isEmpty()
                            || entry.getValue().get(entry.getValue().size() - 1)
                            .isBefore(now.minus(Duration.ofHours(1))));
            List<Instant> times = GENERATION_TIMES.computeIfAbsent(userId, ignored -> new ArrayList<>());
            times.removeIf(time -> time.isBefore(now.minus(Duration.ofHours(1))));
            if (!times.isEmpty() && times.get(times.size() - 1).isAfter(now.minusSeconds(20))) {
                throw new RateLimitException("Please wait 20 seconds before generating another quiz.");
            }
            if (times.size() >= 5) {
                throw new RateLimitException("You have reached the limit of five generated quizzes per hour.");
            }
            times.add(now);
            return now;
        }
    }

    void releaseRateLimit(String userId, Instant reservation) {
        synchronized (GENERATION_TIMES) {
            List<Instant> times = GENERATION_TIMES.get(userId);
            if (times == null) return;
            times.remove(reservation);
            if (times.isEmpty()) GENERATION_TIMES.remove(userId);
        }
    }

    private int parseInteger(String value, int defaultValue) {
        if (value == null || value.isBlank()) return defaultValue;
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Enter a valid number for quiz settings.");
        }
    }

    private int parseJsonInteger(JsonObject body, String field, int defaultValue) {
        try {
            return parseInteger(body.has(field) ? body.get(field).getAsString() : null,
                    defaultValue);
        } catch (RuntimeException ex) {
            throw new IllegalArgumentException("Invalid number for " + field + ".");
        }
    }

    private String readBody(HttpServletRequest req, int maxLength) throws IOException {
        StringBuilder body = new StringBuilder();
        try (var reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                body.append(line);
                if (body.length() > maxLength) {
                    throw new IllegalArgumentException("Request payload is too large.");
                }
            }
        }
        return body.toString();
    }

    private String userId(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        return session == null ? null : (String) session.getAttribute("userId");
    }

    private boolean isUuid(String value) {
        return value != null && value.matches(
                "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");
    }

    private static final class RateLimitException extends RuntimeException {
        private RateLimitException(String message) {
            super(message);
        }
    }

}
