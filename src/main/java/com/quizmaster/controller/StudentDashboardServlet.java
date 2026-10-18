package com.quizmaster.controller;

import com.quizmaster.model.*;
import com.quizmaster.repository.*;
import com.quizmaster.service.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.*;
import java.util.List;

/**
 * Student dashboard — /student/dashboard
 * Shows welcome info, quiz stats, and recent attempts.
 */
@WebServlet("/student/dashboard")
public class StudentDashboardServlet extends HttpServlet {

    private SupabaseDbService   db;
    private QuizRepository      quizRepo;
    private AttemptRepository   attemptRepo;
    private LearningTopicRepository learningTopicRepo;

    @Override
    public void init() {
        db          = new SupabaseDbService();
        quizRepo    = new QuizRepository(db);
        attemptRepo = new AttemptRepository(db);
        learningTopicRepo = new LearningTopicRepository(db);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        String userId = (String) session.getAttribute("userId");
        String email  = (String) session.getAttribute("userEmail");
        String name   = (String) session.getAttribute("userName");

        if (!db.isConfigured()) {
            req.setAttribute("dbError",
                    "Database not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.");
            req.getRequestDispatcher("/WEB-INF/views/student/dashboard.jsp").forward(req, res);
            return;
        }

        try {
            List<Quiz>        quizzes  = quizRepo.findPublished();
            List<LearningTopic> learningTopics = List.of();
            try {
                learningTopics = learningTopicRepo.findActive();
            } catch (Exception catalogException) {
                getServletContext().log("Learning topic catalog could not be loaded.", catalogException);
                req.setAttribute("catalogError",
                        "The learning library is temporarily unavailable. Apply migration 002 and try again.");
            }
            List<Quiz>        ownedQuizzes = userId != null
                    ? quizRepo.findOwnedBy(userId) : List.of();
            Map<String, Quiz> accessibleQuizzes = new HashMap<>();
            for (Quiz quiz : quizzes) accessibleQuizzes.put(quiz.id, quiz);
            for (Quiz quiz : ownedQuizzes) accessibleQuizzes.put(quiz.id, quiz);
            List<QuizAttempt> attempts = userId != null
                    ? attemptRepo.findByUser(userId)
                    : List.of();

            List<QuizAttempt> completed = attempts.stream()
                    .filter(attempt -> "submitted".equals(attempt.status))
                    .toList();
            int attempted = completed.size();
            double avgScore = completed.stream()
                    .mapToDouble(a -> a.percentage).average().orElse(0.0);

            Map<String, List<Double>> topicScores = new HashMap<>();
            for (QuizAttempt attempt : completed) {
                Quiz quiz = accessibleQuizzes.get(attempt.quizId);
                if (quiz != null && quiz.subject != null && !quiz.subject.isBlank()) {
                    topicScores.computeIfAbsent(quiz.subject, ignored -> new ArrayList<>())
                            .add(attempt.percentage);
                }
            }
            Map<String, Double> revisionTopics = new LinkedHashMap<>();
            topicScores.entrySet().stream()
                    .map(entry -> Map.entry(entry.getKey(), entry.getValue().stream()
                            .mapToDouble(Double::doubleValue).average().orElse(0.0)))
                    .filter(entry -> entry.getValue() < 70.0)
                    .sorted(Map.Entry.comparingByValue())
                    .limit(3)
                    .forEach(entry -> revisionTopics.put(entry.getKey(), entry.getValue()));

            req.setAttribute("quizzes",    quizzes);
            req.setAttribute("learningTopics", learningTopics);
            req.setAttribute("featuredTopics", learningTopics.stream()
                    .filter(topic -> topic.featured).limit(6).toList());
            req.setAttribute("recentTopics", learningTopics.stream().limit(6).toList());
            req.setAttribute("attempts",   attempts.subList(0, Math.min(5, attempts.size())));
            req.setAttribute("attempted",  attempted);
            req.setAttribute("avgScore",   String.format("%.1f", avgScore));
            req.setAttribute("totalQuizzes", quizzes.size());
            req.setAttribute("revisionTopics", revisionTopics);
            req.setAttribute("recommendedDifficulty",
                    attempted == 0 || avgScore < 60.0 ? "Easy"
                            : avgScore >= 80.0 ? "Hard" : "Medium");

        } catch (Exception e) {
            getServletContext().log("Dashboard load error", e);
            req.setAttribute("dbError", "Could not load dashboard data. Please try again.");
        }

        req.setAttribute("userEmail", email);
        req.setAttribute("userName",  name != null ? name : email);
        req.getRequestDispatcher("/WEB-INF/views/student/dashboard.jsp").forward(req, res);
    }
}
