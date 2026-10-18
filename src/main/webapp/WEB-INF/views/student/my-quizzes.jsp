<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, com.quizmaster.model.Quiz, com.quizmaster.util.HtmlUtils" %>
<%
    List<Quiz> quizzes = (List<Quiz>) request.getAttribute("quizzes");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="<%= HtmlUtils.escape((String) request.getAttribute("csrfToken")) %>">
    <title>My AI Quizzes | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css">
</head>
<body>
<header class="topbar">
    <a href="${pageContext.request.contextPath}/" class="topbar-brand"><span class="logo-icon">Q</span><span>QuizMaster</span></a>
    <nav class="topbar-nav"><a href="${pageContext.request.contextPath}/student/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/student/quizzes">Exam Catalog</a>
        <a href="${pageContext.request.contextPath}/student/my-quizzes" class="active">My AI Quizzes</a>
        <a href="${pageContext.request.contextPath}/student/history">My History</a></nav>
    <div class="topbar-end"><form method="post" action="${pageContext.request.contextPath}/logout"><input type="hidden" name="_csrf" value="<%= HtmlUtils.escape((String) session.getAttribute("csrfToken")) %>"><button class="btn btn-ghost btn-sm" type="submit">Sign Out</button></form></div>
</header>
<main class="container" style="padding-block: 36px 64px;">
    <div class="flex justify-between items-center" style="gap: 12px; flex-wrap: wrap; margin-bottom: 24px;">
        <div><span class="badge badge-warn">PRIVATE TO YOU</span><h1 style="margin-top: 8px;">My AI quizzes</h1>
            <p>Only quizzes created by your account are listed here.</p></div>
        <a class="btn btn-primary" href="${pageContext.request.contextPath}/student/ai-quizzes">Generate a quiz</a>
    </div>
    <div class="grid-auto">
        <% if (quizzes != null && !quizzes.isEmpty()) {
            for (Quiz quiz : quizzes) { %>
            <article class="card flex flex-col">
                <div class="flex justify-between items-center">
                    <span class="badge badge-info"><%= HtmlUtils.escape(quiz.subject) %></span>
                    <span class="badge badge-warn">Private</span>
                </div>
                <h2 style="font-size: 20px; margin-top: 14px;"><%= HtmlUtils.escape(quiz.title) %></h2>
                <p style="margin-top: 8px; flex: 1;"><%= HtmlUtils.escape(quiz.description) %></p>
                <p class="fz-sm c-muted" style="margin-block: 14px;"><%= quiz.questionCount %> questions · <%= quiz.durationMinutes %> minutes</p>
                <div class="flex gap-2" style="flex-wrap: wrap;">
                    <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/student/ai-quizzes/preview?id=<%= HtmlUtils.escape(quiz.id) %>">Preview</a>
                    <a class="btn btn-primary btn-sm" href="${pageContext.request.contextPath}/student/exam?quizId=<%= HtmlUtils.escape(quiz.id) %>">Take quiz</a>
                    <form method="post" action="${pageContext.request.contextPath}/student/my-quizzes/delete"
                          onsubmit="return confirm('Delete this private quiz and its attempts?');">
                        <input type="hidden" name="_csrf" value="<%= HtmlUtils.escape((String) request.getAttribute("csrfToken")) %>">
                        <input type="hidden" name="id" value="<%= HtmlUtils.escape(quiz.id) %>">
                        <button class="btn btn-ghost btn-sm" type="submit">Delete</button>
                    </form>
                </div>
            </article>
        <%  }
        } else { %>
            <div class="card text-center" style="grid-column: 1 / -1; padding: 48px 20px;">
                <h2>No saved AI quizzes yet</h2><p style="margin-block: 8px 18px;">Generate a private practice quiz and it will appear here.</p>
                <a class="btn btn-primary" href="${pageContext.request.contextPath}/student/ai-quizzes">Generate your first quiz</a>
            </div>
        <% } %>
    </div>
</main>
</body>
</html>
