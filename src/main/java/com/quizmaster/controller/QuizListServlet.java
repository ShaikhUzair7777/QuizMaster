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
 * Quiz listing page — /student/quizzes
 * Shows all published quizzes available to students.
 */
@WebServlet("/student/quizzes")
public class QuizListServlet extends HttpServlet {

    private SupabaseDbService db;
    private QuizRepository    quizRepo;
    private AttemptRepository attemptRepo;

    @Override
    public void init() {
        db          = new SupabaseDbService();
        quizRepo    = new QuizRepository(db);
        attemptRepo = new AttemptRepository(db);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        String userId = (String) session.getAttribute("userId");

        if (!db.isConfigured()) {
            req.setAttribute("dbError", "Database not configured.");
            req.getRequestDispatcher("/WEB-INF/views/student/quizzes.jsp").forward(req, res);
            return;
        }

        try {
            List<Quiz> quizzes = quizRepo.findPublished();
            req.setAttribute("quizzes", quizzes);

            // For each quiz, check how many attempts user has made
            if (userId != null) {
                java.util.Map<String,Integer> attemptCounts = new java.util.HashMap<>();
                for (Quiz q : quizzes) {
                    attemptCounts.put(q.id, attemptRepo.countAttempts(q.id, userId));
                }
                req.setAttribute("attemptCounts", attemptCounts);
            }

        } catch (Exception e) {
            getServletContext().log("Quiz list error", e);
            req.setAttribute("dbError", "Could not load quizzes: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/views/student/quizzes.jsp").forward(req, res);
    }
}
