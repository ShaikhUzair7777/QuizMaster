package com.quizmaster.controller;

import com.quizmaster.model.*;
import com.quizmaster.repository.*;
import com.quizmaster.service.SupabaseDbService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.List;

/**
 * Attempt history — /student/history
 * Shows all completed quiz attempts for the current user.
 */
@WebServlet("/student/history")
public class HistoryServlet extends HttpServlet {

    private SupabaseDbService db;
    private AttemptRepository attemptRepo;
    private QuizRepository    quizRepo;

    @Override
    public void init() {
        db          = new SupabaseDbService();
        attemptRepo = new AttemptRepository(db);
        quizRepo    = new QuizRepository(db);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        String userId = (String) session.getAttribute("userId");

        try {
            List<QuizAttempt> attempts = attemptRepo.findByUser(userId);
            // Attach quiz titles for display
            java.util.Map<String, String> quizTitles = new java.util.HashMap<>();
            for (QuizAttempt a : attempts) {
                if (!quizTitles.containsKey(a.quizId)) {
                    Quiz q = quizRepo.findAccessibleById(a.quizId, userId);
                    quizTitles.put(a.quizId, q != null ? q.title : "Private Quiz");
                }
            }
            req.setAttribute("attempts",   attempts);
            req.setAttribute("quizTitles", quizTitles);
        } catch (Exception e) {
            getServletContext().log("History load error", e);
            req.setAttribute("dbError", "Could not load history: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/views/student/history.jsp").forward(req, res);
    }
}
