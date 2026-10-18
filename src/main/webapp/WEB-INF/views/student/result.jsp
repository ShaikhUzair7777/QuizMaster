<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, com.quizmaster.model.*" %>
<%
    QuizAttempt attempt = (QuizAttempt) request.getAttribute("attempt");
    Quiz quiz = (Quiz) request.getAttribute("quiz");
    List<AttemptAnswer> answers = (List<AttemptAnswer>) request.getAttribute("answers");
    List<Question> questions = (List<Question>) request.getAttribute("questions");
    String error = (String) request.getAttribute("error");
    String userName = (String) session.getAttribute("userName");

    // Build map: questionId -> selectedOptionId
    Map<String, String> answerMap = new HashMap<>();
    if (answers != null) {
        for (AttemptAnswer a : answers) {
            if (a.questionId != null) answerMap.put(a.questionId, a.selectedOptionId);
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Assessment Result | QuizMaster</title>
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
        <a href="${pageContext.request.contextPath}/student/history" class="active">My History</a>
    </nav>
    <div class="topbar-end">
        <div class="flex items-center gap-2">
            <span class="badge badge-neutral"><%= userName != null ? userName.replace("<", "&lt;") : "Candidate" %></span>
            <form method="post" action="${pageContext.request.contextPath}/logout"><input type="hidden" name="_csrf" value="<%= session.getAttribute("csrfToken") %>"><button class="btn btn-ghost btn-sm" type="submit">Sign Out</button></form>
        </div>
    </div>
</header>

<main class="container" style="padding-top: 32px; padding-bottom: 60px; max-width: 900px;">

    <% if (error != null && !error.isBlank()) { %>
        <div class="alert alert-error" style="margin-bottom: 24px;">
            <div><strong>Error:</strong> <%= error.replace("<", "&lt;") %></div>
        </div>
    <% } %>

    <% if (attempt != null && quiz != null) { %>

        <!-- Score Hero Card -->
        <section class="score-hero">
            <div class="score-circle-wrap">
                <div class="score-pct"><%= String.format("%.0f", attempt.percentage) %>%</div>
                <div class="score-pct-label">Score</div>
            </div>

            <div style="margin-bottom: 16px;">
                <% if (attempt.passed) { %>
                    <span class="badge badge-success" style="font-size: 14px; padding: 6px 18px;">🎉 PASSED (Pass Mark: <%= quiz.passMark %>%)</span>
                <% } else { %>
                    <span class="badge badge-error" style="font-size: 14px; padding: 6px 18px;">FAILED (Pass Mark: <%= quiz.passMark %>%)</span>
                <% } %>
            </div>

            <h1 style="font-size: 26px; margin-bottom: 6px; color: white;"><%= quiz.title.replace("<", "&lt;") %></h1>
            <p style="color: #cbd5e1; font-size: 14px;">Assessment completed on <%= attempt.submittedAt != null ? attempt.submittedAt.toString().substring(0, 16).replace("T", " ") : "Recent" %></p>
        </section>

        <!-- Metrics Row -->
        <div class="grid-auto" style="grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); margin-bottom: 36px;">
            <div class="stat-card">
                <div class="stat-label">Correct Answers</div>
                <div class="stat-value c-success" style="font-size: 24px;"><%= attempt.score %> / <%= attempt.totalQuestions %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Marks Scored</div>
                <div class="stat-value" style="font-size: 24px;"><%= attempt.marksObtained %> / <%= attempt.totalMarks %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Incorrect / Missed</div>
                <div class="stat-value c-error" style="font-size: 24px;"><%= (attempt.totalQuestions - attempt.score) %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Passing Requirement</div>
                <div class="stat-value" style="font-size: 24px;"><%= quiz.passMark %>%</div>
            </div>
        </div>

        <!-- Navigation Buttons -->
        <div class="flex justify-between items-center" style="margin-bottom: 32px; flex-wrap: wrap; gap: 12px;">
            <div class="flex gap-2">
                <a href="${pageContext.request.contextPath}/student/exam?quizId=<%= quiz.id %>" class="btn btn-primary btn-sm">Retake Examination</a>
                <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-secondary btn-sm">Browse Other Quizzes</a>
                <a href="${pageContext.request.contextPath}/student/history" class="btn btn-secondary btn-sm">View My History</a>
            </div>
            <a href="${pageContext.request.contextPath}/student/dashboard" class="btn btn-ghost btn-sm">← Back to Dashboard</a>
        </div>

        <!-- Question Review Section -->
        <section>
            <div style="margin-bottom: 20px;">
                <h2>Comprehensive Question Review</h2>
                <p class="fz-sm c-muted">Compare your chosen answers with verified solution keys</p>
            </div>

            <% if (questions != null && !questions.isEmpty()) { 
                int qIdx = 1;
                for (Question q : questions) {
                    String chosenOptId = answerMap.get(q.id);
                    boolean isCorrect = (q.correctOptionId != null && q.correctOptionId.equals(chosenOptId));
                    boolean isUnanswered = (chosenOptId == null || chosenOptId.isBlank());
            %>
                <article class="review-card <%= isCorrect ? "correct" : (isUnanswered ? "unanswered" : "incorrect") %>">
                    <div class="flex justify-between items-center mb-2">
                        <span class="question-number-tag">Question <%= qIdx++ %></span>
                        <div class="flex items-center gap-2">
                            <span class="fz-xs c-muted"><%= q.marks %> mark<%= q.marks > 1 ? "s" : "" %></span>
                            <% if (isCorrect) { %>
                                <span class="badge badge-success">✓ Correct (+<%= q.marks %>)</span>
                            <% } else if (isUnanswered) { %>
                                <span class="badge badge-neutral">Unanswered (0)</span>
                            <% } else { %>
                                <span class="badge badge-error">✗ Incorrect (0)</span>
                            <% } %>
                        </div>
                    </div>

                    <div style="font-size: 16px; font-weight: 600; color: var(--c-navy); margin-bottom: 16px; line-height: 1.5;">
                        <%= q.questionText.replace("<", "&lt;") %>
                    </div>
                    <% if (q.explanation != null && !q.explanation.isBlank()) { %>
                        <p class="form-hint" style="margin-top: 10px;"><strong>Explanation:</strong>
                            <%= q.explanation.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;") %>
                        </p>
                    <% } %>

                    <div>
                        <% if (q.options != null) {
                            int oIdx = 0;
                            for (Question.Option opt : q.options) {
                                char optLetter = (char) ('A' + oIdx++);
                                boolean isThisCorrect = (q.correctOptionId != null && q.correctOptionId.equals(opt.id));
                                boolean isThisChosen = (chosenOptId != null && chosenOptId.equals(opt.id));

                                String optClass = "opt-neutral";
                                String statusBadge = "";

                                if (isThisCorrect && isThisChosen) {
                                    optClass = "opt-correct";
                                    statusBadge = "✓ Your Choice (Correct)";
                                } else if (isThisCorrect) {
                                    optClass = "opt-correct";
                                    statusBadge = "✓ Correct Answer";
                                } else if (isThisChosen) {
                                    optClass = "opt-wrong";
                                    statusBadge = "✗ Your Choice";
                                }
                        %>
                            <div class="review-opt <%= optClass %>">
                                <span><strong><%= optLetter %>.</strong> <%= opt.text.replace("<", "&lt;") %></span>
                                <% if (!statusBadge.isEmpty()) { %>
                                    <span class="fz-xs fw-700"><%= statusBadge %></span>
                                <% } %>
                            </div>
                        <%  } 
                        } %>
                    </div>
                </article>
            <%  } 
            } %>
        </section>

    <% } %>

</main>

</body>
</html>
