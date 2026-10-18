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
import java.util.*;

/**
 * Admin question management — /admin/questions
 *
 * GET  /admin/questions?quizId=<id>  — page listing questions for a quiz
 * POST /admin/questions               — create a new question (JSON body via AJAX)
 * DELETE /admin/questions?id=<id>    — delete a question
 */
@WebServlet("/admin/questions")
public class AdminQuestionServlet extends HttpServlet {

    private SupabaseDbService db;
    private QuizRepository    quizRepo;

    @Override
    public void init() {
        db       = new SupabaseDbService();
        quizRepo = new QuizRepository(db);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String quizId = req.getParameter("quizId");
        if (quizId == null) {
            res.sendRedirect(req.getContextPath() + "/admin/quizzes");
            return;
        }

        try {
            Quiz quiz = quizRepo.findById(quizId);
            List<Question> questions = quizRepo.findQuestionsWithAnswers(quizId);
            req.setAttribute("quiz",      quiz);
            req.setAttribute("questions", questions);
        } catch (Exception e) {
            getServletContext().log("Admin question list error", e);
            req.setAttribute("dbError", e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/views/admin/questions.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        res.setContentType("application/json;charset=UTF-8");

        // Read JSON body
        StringBuilder sb = new StringBuilder();
        try (var reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line);
        }

        JsonObject body;
        try {
            body = JsonParser.parseString(sb.toString()).getAsJsonObject();
        } catch (Exception e) {
            res.setStatus(400);
            res.getWriter().write(JsonResponse.error("Invalid JSON."));
            return;
        }

        String quizId = body.has("quizId") ? body.get("quizId").getAsString() : null;
        String text   = body.has("questionText") ? body.get("questionText").getAsString() : null;
        if (quizId == null || text == null || text.isBlank()) {
            res.setStatus(400);
            res.getWriter().write(JsonResponse.error("quizId and questionText are required."));
            return;
        }

        Question q = new Question();
        q.quizId       = quizId;
        q.questionText = text;
        q.marks        = body.has("marks") ? body.get("marks").getAsInt() : 1;
        q.orderIndex   = body.has("orderIndex") ? body.get("orderIndex").getAsInt() : 0;
        q.correctOptionId = body.has("correctOptionId") ? body.get("correctOptionId").getAsString() : null;

        q.options = new ArrayList<>();
        if (body.has("options") && body.get("options").isJsonArray()) {
            for (JsonElement el : body.getAsJsonArray("options")) {
                JsonObject oo = el.getAsJsonObject();
                Question.Option opt = new Question.Option();
                opt.id   = oo.has("id")   ? oo.get("id").getAsString()   : UUID.randomUUID().toString();
                opt.text = oo.has("text") ? oo.get("text").getAsString() : "";
                q.options.add(opt);
            }
        }

        try {
            Question saved = quizRepo.createQuestion(q);
            JsonObject out = new JsonObject();
            out.addProperty("id", saved != null ? saved.id : "");
            res.getWriter().write(JsonResponse.ok(out.toString()));
        } catch (Exception e) {
            getServletContext().log("Create question error", e);
            res.setStatus(500);
            res.getWriter().write(JsonResponse.error("Could not save question."));
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        res.setContentType("application/json;charset=UTF-8");
        String id = req.getParameter("id");
        if (id == null) { res.setStatus(400); res.getWriter().write(JsonResponse.error("Missing id.")); return; }
        try {
            quizRepo.deleteQuestion(id);
            res.getWriter().write(JsonResponse.okMessage("Question deleted."));
        } catch (Exception e) {
            getServletContext().log("Delete question error", e);
            res.setStatus(500); res.getWriter().write(JsonResponse.error("Could not delete question."));
        }
    }
}
