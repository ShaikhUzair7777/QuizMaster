package com.quizmaster.controller;

import com.google.gson.*;
import com.quizmaster.model.*;
import com.quizmaster.repository.*;
import com.quizmaster.service.SupabaseDbService;
import com.quizmaster.util.JsonResponse;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.List;

/**
 * Admin dashboard — /admin/dashboard
 * Admin quiz CRUD — /admin/quizzes (GET list, POST create)
 *                    /admin/quizzes?id=<id> (DELETE)
 */
@WebServlet(urlPatterns = {"/admin/dashboard", "/admin/quizzes"})
public class AdminServlet extends HttpServlet {

    private SupabaseDbService  db;
    private QuizRepository     quizRepo;
    private AttemptRepository  attemptRepo;

    @Override
    public void init() {
        db          = new SupabaseDbService();
        quizRepo    = new QuizRepository(db);
        attemptRepo = new AttemptRepository(db);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String path = req.getServletPath();

        if ("/admin/dashboard".equals(path)) {
            showDashboard(req, res);
        } else if ("/admin/quizzes".equals(path)) {
            listQuizzes(req, res);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String path = req.getServletPath();
        if ("/admin/quizzes".equals(path)) {
            createOrUpdateQuiz(req, res);
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        res.setContentType("application/json;charset=UTF-8");
        String path = req.getServletPath();
        if ("/admin/quizzes".equals(path)) {
            String id = req.getParameter("id");
            if (id == null) { res.setStatus(400); res.getWriter().write(JsonResponse.error("Missing id.")); return; }
            try {
                quizRepo.delete(id);
                res.getWriter().write(JsonResponse.okMessage("Quiz deleted."));
            } catch (Exception e) {
                getServletContext().log("Delete quiz error", e);
                res.setStatus(500); res.getWriter().write(JsonResponse.error("Could not delete quiz."));
            }
        }
    }

    // ── Handlers ──────────────────────────────────────────────────────────

    private void showDashboard(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            List<Quiz> quizzes = quizRepo.findAll();
            List<QuizAttempt> attempts = attemptRepo.findAllForAdmin();
            req.setAttribute("quizCount",    quizzes.size());
            req.setAttribute("attemptCount", attempts.size());
            long studentCount = attempts.stream().map(a -> a.userId).distinct().count();
            req.setAttribute("studentCount", studentCount);
            req.setAttribute("recentAttempts", attempts.subList(0, Math.min(10, attempts.size())));
        } catch (Exception e) {
            getServletContext().log("Admin dashboard error", e);
            req.setAttribute("dbError", "Database error: " + e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(req, res);
    }

    private void listQuizzes(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("quizzes", quizRepo.findAll());
        } catch (Exception e) {
            getServletContext().log("Admin quiz list error", e);
            req.setAttribute("dbError", e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/views/admin/quizzes.jsp").forward(req, res);
    }

    private void createOrUpdateQuiz(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        res.setContentType("application/json;charset=UTF-8");

        String id    = req.getParameter("id");
        String title = req.getParameter("title");
        if (title == null || title.isBlank()) {
            res.setStatus(400);
            res.getWriter().write(JsonResponse.error("Title is required."));
            return;
        }

        Quiz q = new Quiz();
        q.title           = title.trim();
        q.description     = req.getParameter("description");
        q.subject         = req.getParameter("subject");
        q.published       = "true".equals(req.getParameter("published"));
        q.passMark        = parseIntSafe(req.getParameter("passMark"), 0);
        q.maxAttempts     = parseIntSafe(req.getParameter("maxAttempts"), 1);
        q.durationMinutes = parseIntSafe(req.getParameter("durationMinutes"), 30);
        q.createdBy       = (String) req.getSession().getAttribute("userId");

        try {
            if (id != null && !id.isBlank()) {
                quizRepo.update(id, q);
                res.getWriter().write(JsonResponse.okMessage("Quiz updated."));
            } else {
                Quiz saved = quizRepo.create(q);
                JsonObject out = new JsonObject();
                out.addProperty("id",    saved != null ? saved.id : "");
                out.addProperty("message", "Quiz created.");
                res.getWriter().write(JsonResponse.ok(out.toString()));
            }
        } catch (Exception e) {
            getServletContext().log("Create/update quiz error", e);
            res.setStatus(500);
            res.getWriter().write(JsonResponse.error("Could not save quiz: " + e.getMessage()));
        }
    }

    private int parseIntSafe(String s, int def) {
        try { return s != null ? Integer.parseInt(s.trim()) : def; }
        catch (NumberFormatException e) { return def; }
    }
}
