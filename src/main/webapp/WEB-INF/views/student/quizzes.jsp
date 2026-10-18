<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, java.util.Map, com.quizmaster.model.Quiz" %>
<%
    List<Quiz> quizzes = (List<Quiz>) request.getAttribute("quizzes");
    Map<String, Integer> attemptCounts = (Map<String, Integer>) request.getAttribute("attemptCounts");
    String dbError = (String) request.getAttribute("dbError");
    String userName = (String) session.getAttribute("userName");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exam Catalog | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css">
    <style>
        .filter-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 16px;
            margin-bottom: 32px;
            background: var(--c-surface);
            padding: 16px 20px;
            border-radius: var(--r-lg);
            border: 1px solid var(--c-border);
        }
        .search-box {
            display: flex;
            align-items: center;
            gap: 8px;
            background: var(--c-bg);
            border: 1px solid var(--c-border);
            border-radius: var(--r-md);
            padding: 8px 14px;
            width: min(340px, 100%);
        }
        .search-box input {
            border: none;
            background: transparent;
            outline: none;
            width: 100%;
            font-size: 14px;
        }
    </style>
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
        <a href="${pageContext.request.contextPath}/student/quizzes" class="active">Exam Catalog</a>
        <a href="${pageContext.request.contextPath}/student/ai-quizzes">Generate AI Quiz</a>
        <a href="${pageContext.request.contextPath}/student/my-quizzes">My AI Quizzes</a>
        <a href="${pageContext.request.contextPath}/student/history">My History</a>
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
            <h1>Examination Catalog</h1>
            <p class="fz-sm c-muted">Browse published certification and practice assessments</p>
        </div>
        <a href="${pageContext.request.contextPath}/student/dashboard" class="btn btn-secondary btn-sm">← Back to Dashboard</a>
    </div>

    <% if (dbError != null && !dbError.isBlank()) { %>
        <div class="alert alert-warn" style="margin-bottom: 24px;">
            <div>
                <strong>Notice:</strong> <%= dbError.replace("<", "&lt;") %>
            </div>
        </div>
    <% } %>

    <!-- Filter & Search Bar -->
    <div class="filter-bar">
        <div class="search-box">
            <span>🔍</span>
            <input type="text" id="quiz-search" placeholder="Search by title or subject..." onkeyup="filterQuizzes()">
        </div>
        <div class="fz-sm c-muted">
            Showing <strong id="visible-count"><%= quizzes != null ? quizzes.size() : 0 %></strong> assessments
        </div>
    </div>

    <!-- Quizzes Grid -->
    <div class="grid-auto" id="quizzes-grid">
        <% if (quizzes != null && !quizzes.isEmpty()) { %>
            <% for (Quiz q : quizzes) { 
                int usedAttempts = (attemptCounts != null && attemptCounts.containsKey(q.id)) ? attemptCounts.get(q.id) : 0;
                boolean isExhausted = (q.maxAttempts > 0 && usedAttempts >= q.maxAttempts);
            %>
                <div class="card card-hover flex flex-col quiz-item" data-title="<%= q.title != null ? q.title.toLowerCase() : "" %>" data-subject="<%= q.subject != null ? q.subject.toLowerCase() : "" %>">
                    <div class="flex justify-between items-center mb-2">
                        <span class="badge badge-info"><%= q.subject != null ? q.subject.replace("<", "&lt;") : "General" %></span>
                        <span class="fz-xs c-muted">⏱️ <%= q.durationMinutes %> min</span>
                    </div>

                    <h3 style="font-size: 18px; margin-bottom: 8px;"><%= q.title != null ? q.title.replace("<", "&lt;") : "Quiz" %></h3>
                    <p class="fz-sm" style="flex: 1; margin-bottom: 20px;">
                        <%= q.description != null ? q.description.replace("<", "&lt;") : "Comprehensive examination to test knowledge and earn completion certification." %>
                    </p>

                    <div style="background: #f8fafc; border-radius: var(--r-md); padding: 10px 14px; margin-bottom: 16px; font-size: 13px;">
                        <div class="flex justify-between mb-1">
                            <span class="c-muted">Questions:</span>
                            <strong><%= q.questionCount %></strong>
                        </div>
                        <div class="flex justify-between mb-1">
                            <span class="c-muted">Pass Mark:</span>
                            <strong><%= q.passMark %>%</strong>
                        </div>
                        <div class="flex justify-between">
                            <span class="c-muted">Attempts:</span>
                            <span>
                                <% if (q.maxAttempts > 0) { %>
                                    <%= usedAttempts %> / <%= q.maxAttempts %> used
                                <% } else { %>
                                    Unlimited
                                <% } %>
                            </span>
                        </div>
                    </div>

                    <div class="flex justify-between items-center" style="border-top: 1px solid var(--c-border); padding-top: 14px;">
                        <% if (isExhausted) { %>
                            <span class="badge badge-error">Attempts Limit Reached</span>
                            <button class="btn btn-secondary btn-sm" disabled>Exhausted</button>
                        <% } else { %>
                            <span class="fz-xs fw-600 c-success">● Ready to Start</span>
                            <a href="${pageContext.request.contextPath}/student/exam?quizId=<%= q.id %>" class="btn btn-primary btn-sm">
                                Start Examination →
                            </a>
                        <% } %>
                    </div>
                </div>
            <% } %>
        <% } else { %>
            <div class="card" style="grid-column: 1 / -1; text-align: center; padding: 60px 20px;">
                <h3 style="margin-bottom: 8px;">No Assessments Found</h3>
                <p class="c-muted">There are currently no published exams available. Please check back later or contact your administrator.</p>
            </div>
        <% } %>
    </div>

</main>

<script>
    function filterQuizzes() {
        const query = document.getElementById('quiz-search').value.toLowerCase().trim();
        const items = document.querySelectorAll('.quiz-item');
        let count = 0;

        items.forEach(item => {
            const title = item.dataset.title || '';
            const subject = item.dataset.subject || '';
            if (title.includes(query) || subject.includes(query)) {
                item.style.display = 'flex';
                count++;
            } else {
                item.style.display = 'none';
            }
        });

        const countEl = document.getElementById('visible-count');
        if (countEl) countEl.textContent = count;
    }
</script>

</body>
</html>
