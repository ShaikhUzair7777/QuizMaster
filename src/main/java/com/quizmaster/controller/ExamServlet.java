package com.quizmaster.controller;

import com.google.gson.*;
import com.quizmaster.model.*;
import com.quizmaster.repository.*;
import com.quizmaster.service.*;
import com.quizmaster.util.JsonResponse;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * Serves quiz questions for the exam interface.
 *
 * GET  /student/exam?quizId=<id>  — starts/resumes an attempt, returns exam page
 * GET  /student/exam/questions?attemptId=<id>&quizId=<id>  — AJAX: questions (no answers)
 * POST /student/exam/save   — AJAX: autosave a single answer
 * POST /student/exam/submit — AJAX: submit exam and get score
 */
@WebServlet(urlPatterns = {"/student/exam", "/student/exam/questions",
                            "/student/exam/save", "/student/exam/submit"})
public class ExamServlet extends HttpServlet {

    private static final Pattern UUID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

    private SupabaseDbService  db;
    private QuizRepository     quizRepo;
    private AttemptRepository  attemptRepo;
    private QuizService        quizService;

    @Override
    public void init() {
        db          = new SupabaseDbService();
        quizRepo    = new QuizRepository(db);
        attemptRepo = new AttemptRepository(db);
        quizService = new QuizService(quizRepo, attemptRepo);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String path = req.getServletPath();

        // AJAX: fetch questions without answers
        if ("/student/exam/questions".equals(path)) {
            serveQuestions(req, res);
            return;
        }

        // Page: start or resume exam
        String quizId = req.getParameter("quizId");
        if (quizId == null || !UUID_PATTERN.matcher(quizId).matches()) {
            res.sendRedirect(req.getContextPath() + "/student/quizzes");
            return;
        }

        HttpSession session = req.getSession(false);
        String userId = (String) session.getAttribute("userId");

        if (!db.isConfigured()) {
            req.setAttribute("error", "Database not configured.");
            req.getRequestDispatcher("/WEB-INF/views/student/exam.jsp").forward(req, res);
            return;
        }

        try {
            QuizService.StartResult result = quizService.startAttempt(quizId, userId);
            if (!result.success) {
                req.setAttribute("error", result.error);
                req.getRequestDispatcher("/WEB-INF/views/student/exam.jsp").forward(req, res);
                return;
            }

            req.setAttribute("attempt", result.attempt);
            req.setAttribute("quiz",    result.quiz);
            req.setAttribute("resumed", result.resumed);

        } catch (Exception e) {
            getServletContext().log("Exam start error", e);
            req.setAttribute("error", "Could not start exam: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/views/student/exam.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        res.setContentType("application/json;charset=UTF-8");

        String path = req.getServletPath();

        if ("/student/exam/save".equals(path)) {
            saveAnswer(req, res);
        } else if ("/student/exam/submit".equals(path)) {
            submitExam(req, res);
        } else {
            res.setStatus(404);
            res.getWriter().write(JsonResponse.error("Not found."));
        }
    }

    // ── Handlers ──────────────────────────────────────────────────────────

    private void serveQuestions(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        String quizId    = req.getParameter("quizId");
        String attemptId = req.getParameter("attemptId");

        if (quizId == null || attemptId == null
                || !UUID_PATTERN.matcher(quizId).matches()
                || !UUID_PATTERN.matcher(attemptId).matches()) {
            res.setStatus(400);
            res.getWriter().write(JsonResponse.error("Missing parameters."));
            return;
        }

        try {
            // Verify the attempt belongs to this user
            HttpSession session   = req.getSession(false);
            String      userId    = (String) session.getAttribute("userId");
            QuizAttempt attempt   = attemptRepo.findByIdForUser(attemptId, userId);

            if (attempt == null || userId == null || !userId.equals(attempt.userId)
                    || !Objects.equals(attempt.quizId, quizId)) {
                res.setStatus(403);
                res.getWriter().write(JsonResponse.error("Access denied."));
                return;
            }
            Quiz quiz = quizRepo.findAccessibleById(quizId, userId);
            if (quiz == null) {
                res.setStatus(HttpServletResponse.SC_NOT_FOUND);
                res.getWriter().write(JsonResponse.error("Quiz not found."));
                return;
            }
            if (!"in_progress".equals(attempt.status)) {
                res.setStatus(409);
                res.getWriter().write(JsonResponse.error("This attempt is no longer in progress."));
                return;
            }

            // Enforce server-side deadline
            if (attempt.deadline != null && java.time.Instant.now().isAfter(attempt.deadline)) {
                quizService.scoreAndSubmit(attemptId, quizId, quiz);
                res.setStatus(410);
                res.getWriter().write(JsonResponse.error("Exam time expired. Your attempt has been submitted."));
                return;
            }

            List<Question>      questions = quizRepo.findQuestionsForStudent(quizId);
            List<AttemptAnswer> saved     = attemptRepo.findAnswers(attemptId);

            Gson gson = new Gson();
            JsonObject out = new JsonObject();
            out.add("questions", gson.toJsonTree(questions));
            out.add("savedAnswers", gson.toJsonTree(saved));
            out.addProperty("deadline", attempt.deadline != null ? attempt.deadline.toString() : "");
            res.getWriter().write(JsonResponse.ok(out.toString()));

        } catch (Exception e) {
            getServletContext().log("Questions load error", e);
            res.setStatus(500);
            res.getWriter().write(JsonResponse.error("Could not load questions."));
        }
    }

    private void saveAnswer(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        String attemptId        = req.getParameter("attemptId");
        String questionId       = req.getParameter("questionId");
        String selectedOptionId = req.getParameter("selectedOptionId");

        if (attemptId == null || questionId == null
                || !UUID_PATTERN.matcher(attemptId).matches()
                || !UUID_PATTERN.matcher(questionId).matches()) {
            res.setStatus(400);
            res.getWriter().write(JsonResponse.error("Missing parameters."));
            return;
        }

        try {
            // Ownership check
            HttpSession session = req.getSession(false);
            String      userId  = (String) session.getAttribute("userId");
            QuizAttempt attempt = attemptRepo.findByIdForUser(attemptId, userId);

            if (attempt == null || userId == null || !userId.equals(attempt.userId)) {
                res.setStatus(403);
                res.getWriter().write(JsonResponse.error("Access denied."));
                return;
            }
            if (quizRepo.findAccessibleById(attempt.quizId, userId) == null) {
                res.setStatus(HttpServletResponse.SC_NOT_FOUND);
                res.getWriter().write(JsonResponse.error("Quiz not found."));
                return;
            }

            if (!"in_progress".equals(attempt.status)) {
                res.setStatus(409);
                res.getWriter().write(JsonResponse.error("This attempt has already been submitted."));
                return;
            }

            // Enforce server-side deadline
            if (attempt.deadline != null && java.time.Instant.now().isAfter(attempt.deadline)) {
                res.setStatus(410);
                res.getWriter().write(JsonResponse.error("Exam time has expired."));
                return;
            }

            List<Question> questions = quizRepo.findQuestionsForStudent(attempt.quizId);
            Question question = questions.stream()
                    .filter(candidate -> questionId.equals(candidate.id))
                    .findFirst().orElse(null);
            if (question == null) {
                res.setStatus(400);
                res.getWriter().write(JsonResponse.error("Question does not belong to this exam."));
                return;
            }
            boolean validOption = selectedOptionId == null || selectedOptionId.isBlank()
                    || (question.options != null && question.options.stream()
                    .anyMatch(option -> selectedOptionId.equals(option.id)));
            if (!validOption) {
                res.setStatus(400);
                res.getWriter().write(JsonResponse.error("The selected answer is not valid for this question."));
                return;
            }

            attemptRepo.upsertAnswer(attemptId, questionId, selectedOptionId);
            res.getWriter().write(JsonResponse.ok());

        } catch (Exception e) {
            getServletContext().log("Save answer error", e);
            res.setStatus(500);
            res.getWriter().write(JsonResponse.error("Could not save answer."));
        }
    }

    private void submitExam(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        String attemptId = req.getParameter("attemptId");
        String quizId    = req.getParameter("quizId");

        if (attemptId == null || quizId == null
                || !UUID_PATTERN.matcher(attemptId).matches()
                || !UUID_PATTERN.matcher(quizId).matches()) {
            res.setStatus(400);
            res.getWriter().write(JsonResponse.error("Missing parameters."));
            return;
        }

        try {
            // Ownership check
            HttpSession session = req.getSession(false);
            String      userId  = (String) session.getAttribute("userId");
            QuizAttempt attempt = attemptRepo.findByIdForUser(attemptId, userId);

            if (attempt == null || userId == null || !userId.equals(attempt.userId)
                    || !Objects.equals(attempt.quizId, quizId)) {
                res.setStatus(403);
                res.getWriter().write(JsonResponse.error("Access denied."));
                return;
            }
            Quiz quiz = quizRepo.findAccessibleById(quizId, userId);
            if (quiz == null) {
                res.setStatus(HttpServletResponse.SC_NOT_FOUND);
                res.getWriter().write(JsonResponse.error("Quiz not found."));
                return;
            }
            if (!"in_progress".equals(attempt.status)) {
                res.setStatus(409);
                res.getWriter().write(JsonResponse.error("This attempt has already been submitted."));
                return;
            }

            QuizAttempt scored = quizService.scoreAndSubmit(attemptId, quizId, quiz);

            JsonObject out = new JsonObject();
            out.addProperty("attemptId",  scored.id);
            out.addProperty("score",      scored.score);
            out.addProperty("total",      scored.totalQuestions);
            out.addProperty("percentage", scored.percentage);
            out.addProperty("passed",     scored.passed);
            res.getWriter().write(JsonResponse.ok(out.toString()));

        } catch (Exception e) {
            getServletContext().log("Submit exam error", e);
            res.setStatus(500);
            res.getWriter().write(JsonResponse.error("Could not submit exam."));
        }
    }
}
