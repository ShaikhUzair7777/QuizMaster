package com.quizmaster.controller;

import com.quizmaster.model.*;
import com.quizmaster.repository.*;
import com.quizmaster.service.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Results page — /student/result?attemptId=<id>
 * Shows the scored result for a submitted attempt.
 * Ownership is verified — students only see their own results.
 */
@WebServlet("/student/result")
public class ResultServlet extends HttpServlet {

    private static final Pattern UUID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

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

        String attemptId = req.getParameter("attemptId");
        if (attemptId == null || !UUID_PATTERN.matcher(attemptId).matches()) {
            res.sendRedirect(req.getContextPath() + "/student/history");
            return;
        }

        HttpSession session = req.getSession(false);
        String userId = (String) session.getAttribute("userId");

        try {
            QuizAttempt attempt = attemptRepo.findByIdForUser(attemptId, userId);

            // Ownership check — critical security control
            if (attempt == null || userId == null || !userId.equals(attempt.userId)) {
                res.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "You do not have access to this result.");
                return;
            }

            if ("in_progress".equals(attempt.status)) {
                res.sendRedirect(req.getContextPath() + "/student/exam?quizId=" + attempt.quizId);
                return;
            }

            Quiz quiz = quizRepo.findAccessibleById(attempt.quizId, userId);
            if (quiz == null) {
                res.sendError(HttpServletResponse.SC_NOT_FOUND, "Quiz not found.");
                return;
            }
            List<AttemptAnswer> answers = attemptRepo.findAnswers(attemptId);
            List<Question> questions = quizRepo.findQuestionsWithAnswers(attempt.quizId);

            req.setAttribute("attempt",   attempt);
            req.setAttribute("quiz",      quiz);
            req.setAttribute("answers",   answers);
            req.setAttribute("questions", questions);

        } catch (Exception e) {
            getServletContext().log("Result load error", e);
            req.setAttribute("error", "Could not load result: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/views/student/result.jsp").forward(req, res);
    }
}
