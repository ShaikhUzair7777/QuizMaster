<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, java.util.Map, com.quizmaster.model.QuizAttempt" %>
<%
    List<QuizAttempt> attempts = (List<QuizAttempt>) request.getAttribute("attempts");
    Map<String, String> quizTitles = (Map<String, String>) request.getAttribute("quizTitles");
    String dbError = (String) request.getAttribute("dbError");
    String userName = (String) session.getAttribute("userName");

    int totalAttempts = (attempts != null) ? attempts.size() : 0;
    long passedAttempts = (attempts != null) ? attempts.stream().filter(a -> a.passed).count() : 0;
    double bestScore = (attempts != null && !attempts.isEmpty())
            ? attempts.stream().mapToDouble(a -> a.percentage).max().orElse(0.0)
            : 0.0;
    double avgScore = (attempts != null && !attempts.isEmpty())
            ? attempts.stream().mapToDouble(a -> a.percentage).average().orElse(0.0)
            : 0.0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Examination History | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css">
</head>
<body>

<!-- Navigation -->
<header class="topbar">
    <a href="${pageContext.request.contextPath}/" class="topbar-brand">
        <span class="logo-icon">Q</span>
        <span>QuizMaster</span>
    </a>
    <nav class="topbar-nav">
        <a href="${pageContext.request.contextPath}/student/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/student/quizzes">Exam Catalog</a>
        <a href="${pageContext.request.contextPath}/student/ai-quizzes">Generate AI Quiz</a>
        <a href="${pageContext.request.contextPath}/student/my-quizzes">My AI Quizzes</a>
        <a href="${pageContext.request.contextPath}/student/history" class="active">My History</a>
    </nav>
    <div class="topbar-end">
        <div class="flex items-center gap-2">
            <span class="badge badge-neutral"><%= userName != null ? userName.replace("<", "&lt;") : "Candidate" %></span>
            <form method="post" action="${pageContext.request.contextPath}/logout"><input type="hidden" name="_csrf" value="<%= session.getAttribute("csrfToken") %>"><button class="btn btn-ghost btn-sm" type="submit">Sign Out</button></form>
        </div>
    </div>
</header>

<main class="container" style="padding-top: 32px; padding-bottom: 60px;">

    <div class="flex justify-between items-center" style="margin-bottom: 24px;">
        <div>
            <h1>Assessment Records & History</h1>
            <p class="fz-sm c-muted">Review performance across all completed examination sessions</p>
        </div>
        <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-primary btn-sm">Take Another Exam →</a>
    </div>

    <% if (dbError != null && !dbError.isBlank()) { %>
        <div class="alert alert-warn" style="margin-bottom: 24px;">
            <div><strong>Notice:</strong> <%= dbError.replace("<", "&lt;") %></div>
        </div>
    <% } %>

    <!-- Summary Metrics -->
    <div class="grid-auto" style="margin-bottom: 36px;">
        <div class="stat-card">
            <div class="stat-icon" style="background: #eef2ff; color: var(--c-accent);">📝</div>
            <div class="stat-value"><%= totalAttempts %></div>
            <div class="stat-label">Total Submissions</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #f0fdf4; color: var(--c-success);">🏆</div>
            <div class="stat-value"><%= passedAttempts %></div>
            <div class="stat-label">Certifications Passed</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #eff6ff; color: var(--c-info);">🌟</div>
            <div class="stat-value"><%= String.format("%.1f", bestScore) %>%</div>
            <div class="stat-label">Highest Score</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #faf5ff; color: var(--c-violet);">📈</div>
            <div class="stat-value"><%= String.format("%.1f", avgScore) %>%</div>
            <div class="stat-label">Average Performance</div>
        </div>
    </div>

    <!-- Attempt Records Table -->
    <div class="card" style="padding: 0; overflow: hidden;">
        <div class="table-wrap" style="border: none;">
            <table>
                <thead>
                    <tr>
                        <th>Examination Title</th>
                        <th>Submitted At</th>
                        <th>Correct Answers</th>
                        <th>Marks Obtained</th>
                        <th>Percentage</th>
                        <th>Status</th>
                        <th style="text-align: right;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (attempts != null && !attempts.isEmpty()) { %>
                        <% for (QuizAttempt a : attempts) { 
                            String title = (quizTitles != null && quizTitles.containsKey(a.quizId))
                                    ? quizTitles.get(a.quizId)
                                    : "Quiz Assessment";
                        %>
                            <tr>
                                <td>
                                    <strong><%= title.replace("<", "&lt;") %></strong>
                                </td>
                                <td class="fz-sm c-muted">
                                    <%= a.submittedAt != null ? a.submittedAt.toString().substring(0, 16).replace("T", " ") : "Recent" %>
                                </td>
                                <td>
                                    <%= a.score %> / <%= a.totalQuestions %>
                                </td>
                                <td>
                                    <%= a.marksObtained %> / <%= a.totalMarks %>
                                </td>
                                <td>
                                    <strong><%= String.format("%.1f", a.percentage) %>%</strong>
                                </td>
                                <td>
                                    <% if (a.passed) { %>
                                        <span class="badge badge-success">PASSED</span>
                                    <% } else { %>
                                        <span class="badge badge-error">FAILED</span>
                                    <% } %>
                                </td>
                                <td style="text-align: right;">
                                    <a href="${pageContext.request.contextPath}/student/result?attemptId=<%= a.id %>" class="btn btn-secondary btn-sm">
                                        View Report →
                                    </a>
                                </td>
                            </tr>
                        <% } %>
                    <% } else { %>
                        <tr>
                            <td colspan="7" style="text-align: center; padding: 48px; color: var(--c-muted);">
                                No completed examination records found. Explore the catalog to begin your first test!
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

</main>

</body>
</html>
