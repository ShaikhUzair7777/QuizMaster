<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, com.quizmaster.model.QuizAttempt" %>
<%
    Integer quizCount = (Integer) request.getAttribute("quizCount");
    Integer attemptCount = (Integer) request.getAttribute("attemptCount");
    Long studentCount = (Long) request.getAttribute("studentCount");
    List<QuizAttempt> recentAttempts = (List<QuizAttempt>) request.getAttribute("recentAttempts");
    String dbError = (String) request.getAttribute("dbError");
    String userName = (String) session.getAttribute("userName");

    if (quizCount == null) quizCount = 0;
    if (attemptCount == null) attemptCount = 0;
    if (studentCount == null) studentCount = 0L;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Administration Console | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css">
</head>
<body>

<!-- Navigation -->
<header class="topbar">
    <a href="${pageContext.request.contextPath}/" class="topbar-brand">
        <span class="logo-icon" style="background: linear-gradient(135deg, #dc2626, #b91c1c);">A</span>
        <span>QuizMaster Admin</span>
    </a>
    <nav class="topbar-nav">
        <a href="${pageContext.request.contextPath}/admin/dashboard" class="active">Overview</a>
        <a href="${pageContext.request.contextPath}/admin/quizzes">Quiz Management</a>
        <a href="${pageContext.request.contextPath}/student/dashboard">Student View</a>
    </nav>
    <div class="topbar-end">
        <span class="badge badge-error">ADMINISTRATOR</span>
        <form method="post" action="${pageContext.request.contextPath}/logout"><input type="hidden" name="_csrf" value="<%= session.getAttribute("csrfToken") %>"><button class="btn btn-ghost btn-sm" type="submit">Sign Out</button></form>
    </div>
</header>

<main class="container" style="padding-top: 32px; padding-bottom: 60px;">

    <div class="flex justify-between items-center" style="margin-bottom: 24px; flex-wrap: wrap; gap: 12px;">
        <div>
            <h1>System Administration</h1>
            <p class="fz-sm c-muted">Platform telemetry, examination catalogs, and candidate assessment activity</p>
        </div>
        <div class="flex gap-2">
            <a href="${pageContext.request.contextPath}/admin/quizzes" class="btn btn-primary btn-sm">+ Manage & Create Quizzes</a>
        </div>
    </div>

    <% if (dbError != null && !dbError.isBlank()) { %>
        <div class="alert alert-error" style="margin-bottom: 24px;">
            <div><strong>Notice:</strong> <%= dbError.replace("<", "&lt;") %></div>
        </div>
    <% } %>

    <!-- Metrics Cards -->
    <div class="grid-auto" style="margin-bottom: 36px;">
        <div class="stat-card">
            <div class="stat-icon" style="background: #eff6ff; color: var(--c-info);">📚</div>
            <div class="stat-value"><%= quizCount %></div>
            <div class="stat-label">Active Quizzes in Bank</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #f0fdf4; color: var(--c-success);">🎯</div>
            <div class="stat-value"><%= attemptCount %></div>
            <div class="stat-label">Total Exam Attempts</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #faf5ff; color: var(--c-violet);">👥</div>
            <div class="stat-value"><%= studentCount %></div>
            <div class="stat-label">Unique Candidates</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #ecfdf5; color: #059669;">🛡️</div>
            <div class="stat-value">Secure</div>
            <div class="stat-label">Proctoring Status</div>
        </div>
    </div>

    <!-- Recent Platform Activity -->
    <div class="card" style="padding: 0; overflow: hidden;">
        <div style="padding: 20px 24px; border-bottom: 1px solid var(--c-border); display: flex; justify-content: space-between; align-items: center;">
            <h3 style="font-size: 16px;">Platform Examination Telemetry</h3>
            <span class="fz-xs c-muted">Latest submissions across candidates</span>
        </div>
        <div class="table-wrap" style="border: none;">
            <table>
                <thead>
                    <tr>
                        <th>Attempt ID</th>
                        <th>User ID</th>
                        <th>Status</th>
                        <th>Score</th>
                        <th>Percentage</th>
                        <th>Result</th>
                        <th>Started At</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (recentAttempts != null && !recentAttempts.isEmpty()) { %>
                        <% for (QuizAttempt a : recentAttempts) { %>
                            <tr>
                                <td class="fz-xs" style="font-family: monospace;"><%= a.id != null ? a.id.substring(0, 8) + "..." : "-" %></td>
                                <td class="fz-xs" style="font-family: monospace;"><%= a.userId != null ? a.userId.substring(0, 8) + "..." : "Anonymous" %></td>
                                <td>
                                    <% if ("submitted".equals(a.status)) { %>
                                        <span class="badge badge-success">Submitted</span>
                                    <% } else if ("in_progress".equals(a.status)) { %>
                                        <span class="badge badge-warn">In Progress</span>
                                    <% } else { %>
                                        <span class="badge badge-neutral"><%= a.status %></span>
                                    <% } %>
                                </td>
                                <td><%= a.score %> / <%= a.totalQuestions %></td>
                                <td><strong><%= String.format("%.1f", a.percentage) %>%</strong></td>
                                <td>
                                    <% if (a.passed) { %>
                                        <span class="badge badge-success">PASS</span>
                                    <% } else { %>
                                        <span class="badge badge-error">FAIL</span>
                                    <% } %>
                                </td>
                                <td class="fz-sm c-muted">
                                    <%= a.startedAt != null ? a.startedAt.toString().substring(0, 16).replace("T", " ") : "Recent" %>
                                </td>
                            </tr>
                        <% } %>
                    <% } else { %>
                        <tr>
                            <td colspan="7" style="text-align: center; padding: 40px; color: var(--c-muted);">
                                No candidate attempts recorded yet.
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
