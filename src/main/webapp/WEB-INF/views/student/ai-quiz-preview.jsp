<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, com.quizmaster.model.Quiz, com.quizmaster.model.Question, com.quizmaster.util.HtmlUtils" %>
<%
    Quiz quiz = (Quiz) request.getAttribute("quiz");
    List<Question> questions = (List<Question>) request.getAttribute("questions");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= HtmlUtils.escape(quiz.title) %> | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css?v=20261019">
</head>
<body>
<header class="topbar">
    <a href="${pageContext.request.contextPath}/" class="topbar-brand"><span class="logo-icon">Q</span><span>QuizMaster</span></a>
    <nav class="topbar-nav"><a href="${pageContext.request.contextPath}/student/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/student/my-quizzes">My AI Quizzes</a></nav>
    <div class="topbar-end"><form method="post" action="${pageContext.request.contextPath}/logout"><input type="hidden" name="_csrf" value="<%= HtmlUtils.escape((String) session.getAttribute("csrfToken")) %>"><button class="btn btn-ghost btn-sm" type="submit">Sign Out</button></form></div>
</header>
<main class="container" style="padding-block: 36px 64px; max-width: 900px;">
    <span class="badge badge-warn">PRIVATE QUIZ · READY TO TAKE</span>
    <h1 style="font-size: 32px; margin-top: 10px;"><%= HtmlUtils.escape(quiz.title) %></h1>
    <p><%= HtmlUtils.escape(quiz.subject) %> · <%= quiz.questionCount %> questions · <%= quiz.durationMinutes %> minutes</p>
    <div class="flex gap-2" style="margin-block: 20px;">
        <a class="btn btn-primary" href="${pageContext.request.contextPath}/student/exam?quizId=<%= HtmlUtils.escape(quiz.id) %>">Take quiz now</a>
        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/student/my-quizzes">Back to my quizzes</a>
    </div>
    <p class="alert alert-info">Answer choices are shown below. Correct answers and explanations stay hidden until you submit the quiz.</p>
    <% if (questions != null) {
        for (int index = 0; index < questions.size(); index++) {
            Question question = questions.get(index); %>
        <article class="card generated-question" style="margin-top: 16px;">
            <span class="question-number-tag">Question <%= index + 1 %> of <%= questions.size() %></span>
            <h2 style="font-size: 19px; margin-block: 12px;"><%= HtmlUtils.escape(question.questionText) %></h2>
            <div class="generated-option-list">
                <% if (question.options != null) {
                    int optionNumber = 0;
                    for (Question.Option option : question.options) { %>
                    <div class="generated-option">
                        <span class="generated-option-letter"><%= (char) ('A' + optionNumber++) %></span>
                        <span><%= HtmlUtils.escape(option.text) %></span>
                    </div>
                <%  }
                } %>
            </div>
        </article>
    <%  }
    } %>
</main>
</body>
</html>
