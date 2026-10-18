<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, com.quizmaster.model.Quiz, com.quizmaster.model.Question" %>
<%
    Quiz quiz = (Quiz) request.getAttribute("quiz");
    List<Question> questions = (List<Question>) request.getAttribute("questions");
    String dbError = (String) request.getAttribute("dbError");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="<%= session.getAttribute("csrfToken") %>">
    <title>Question Bank | <%= quiz != null ? quiz.title.replace("<", "&lt;") : "Quiz" %> | QuizMaster Admin</title>
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
        <a href="${pageContext.request.contextPath}/admin/dashboard">Overview</a>
        <a href="${pageContext.request.contextPath}/admin/quizzes" class="active">Quiz Management</a>
        <a href="${pageContext.request.contextPath}/student/dashboard">Student View</a>
    </nav>
    <div class="topbar-end">
        <span class="badge badge-error">ADMINISTRATOR</span>
        <form method="post" action="${pageContext.request.contextPath}/logout"><input type="hidden" name="_csrf" value="<%= session.getAttribute("csrfToken") %>"><button class="btn btn-ghost btn-sm" type="submit">Sign Out</button></form>
    </div>
</header>

<main class="container" style="padding-top: 32px; padding-bottom: 60px; max-width: 960px;">

    <!-- Quiz Header Banner -->
    <div class="card" style="margin-bottom: 24px; padding: 24px 28px; background: white;">
        <div class="flex justify-between items-center flex-wrap gap-3">
            <div>
                <a href="${pageContext.request.contextPath}/admin/quizzes" class="fz-sm c-accent" style="display: inline-block; margin-bottom: 6px;">
                    ← Back to Quiz Catalog
                </a>
                <h1 style="font-size: 24px; margin-bottom: 4px;">
                    <%= quiz != null ? quiz.title.replace("<", "&lt;") : "Question Bank" %>
                </h1>
                <p class="fz-sm c-muted">
                    Subject: <strong><%= quiz != null && quiz.subject != null ? quiz.subject.replace("<", "&lt;") : "General" %></strong> &bull;
                    Duration: <strong><%= quiz != null ? quiz.durationMinutes : 0 %> mins</strong> &bull;
                    Pass Mark: <strong><%= quiz != null ? quiz.passMark : 0 %>%</strong>
                </p>
            </div>
            <button type="button" id="btn-new-question" class="btn btn-primary btn-sm">
                + Add Question
            </button>
        </div>
    </div>

    <% if (dbError != null && !dbError.isBlank()) { %>
        <div class="alert alert-error" style="margin-bottom: 24px;">
            <div><strong>Notice:</strong> <%= dbError.replace("<", "&lt;") %></div>
        </div>
    <% } %>

    <!-- Question List -->
    <div style="margin-bottom: 24px;">
        <div class="flex justify-between items-center mb-3">
            <h2>Questions in Bank (<%= questions != null ? questions.size() : 0 %>)</h2>
        </div>

        <% if (questions != null && !questions.isEmpty()) { 
            int qNum = 1;
            for (Question q : questions) {
        %>
            <article class="card mb-4" style="border-left: 4px solid var(--c-accent);">
                <div class="flex justify-between items-center mb-2">
                    <div class="flex items-center gap-2">
                        <span class="question-number-tag">Q<%= qNum++ %></span>
                        <span class="fz-xs fw-600 c-muted"><%= q.marks %> mark<%= q.marks > 1 ? "s" : "" %></span>
                    </div>
                    <button type="button" class="btn btn-ghost btn-sm btn-delete-question" style="color: var(--c-error);"
                            data-id="<%= q.id %>"
                            data-context-path="${pageContext.request.contextPath}">
                        Delete Question
                    </button>
                </div>

                <div style="font-size: 16px; font-weight: 600; color: var(--c-navy); margin-bottom: 14px; line-height: 1.5;">
                    <%= q.questionText != null ? q.questionText.replace("<", "&lt;") : "" %>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
                    <% if (q.options != null) {
                        int oIdx = 0;
                        for (Question.Option opt : q.options) {
                            char letter = (char) ('A' + oIdx++);
                            boolean isCorrect = (q.correctOptionId != null && q.correctOptionId.equals(opt.id));
                    %>
                        <div class="review-opt <%= isCorrect ? "opt-correct" : "opt-neutral" %>" style="margin-top: 0;">
                            <span><strong><%= letter %>.</strong> <%= opt.text != null ? opt.text.replace("<", "&lt;") : "" %></span>
                            <% if (isCorrect) { %>
                                <span class="fz-xs fw-700">✓ Correct</span>
                            <% } %>
                        </div>
                    <%  } 
                    } %>
                </div>
            </article>
        <%  } 
        } else { %>
            <div class="card" style="text-align: center; padding: 48px 20px;">
                <h3 style="margin-bottom: 8px;">Question Bank is Empty</h3>
                <p class="c-muted" style="margin-bottom: 20px;">No questions have been configured for this quiz yet.</p>
                <button type="button" onclick="document.getElementById('btn-new-question').click()" class="btn btn-primary btn-sm">
                    + Add the First Question
                </button>
            </div>
        <% } %>
    </div>

</main>

<!-- Add Question Modal -->
<div id="question-modal-backdrop" class="modal-backdrop">
    <div class="modal" style="max-width: 600px;">
        <h3 class="modal-title">Add Multiple Choice Question</h3>

        <form id="question-form" method="post" action="${pageContext.request.contextPath}/admin/questions">
            <input type="hidden" id="q-quiz-id" value="<%= quiz != null ? quiz.id : "" %>">

            <div class="form-group mb-3">
                <label class="form-label" for="q-text">Question Prompt *</label>
                <textarea class="form-input" id="q-text" rows="3" placeholder="Enter clear, concise question prompt..." required></textarea>
            </div>

            <div class="form-group mb-3" style="max-width: 140px;">
                <label class="form-label" for="q-marks">Marks</label>
                <input class="form-input" id="q-marks" type="number" min="1" max="10" value="1" required>
            </div>

            <div class="form-group mb-3">
                <label class="form-label">Answer Options (Select the correct answer option radio) *</label>
                
                <div class="flex items-center gap-2 mb-2">
                    <input type="radio" name="correctOpt" value="0" checked id="radio-opt-0">
                    <label for="radio-opt-0" style="font-weight: 700; width: 24px;">A.</label>
                    <input class="form-input" id="q-opt-0" type="text" placeholder="Option A text..." required>
                </div>

                <div class="flex items-center gap-2 mb-2">
                    <input type="radio" name="correctOpt" value="1" id="radio-opt-1">
                    <label for="radio-opt-1" style="font-weight: 700; width: 24px;">B.</label>
                    <input class="form-input" id="q-opt-1" type="text" placeholder="Option B text..." required>
                </div>

                <div class="flex items-center gap-2 mb-2">
                    <input type="radio" name="correctOpt" value="2" id="radio-opt-2">
                    <label for="radio-opt-2" style="font-weight: 700; width: 24px;">C.</label>
                    <input class="form-input" id="q-opt-2" type="text" placeholder="Option C text..." required>
                </div>

                <div class="flex items-center gap-2 mb-2">
                    <input type="radio" name="correctOpt" value="3" id="radio-opt-3">
                    <label for="radio-opt-3" style="font-weight: 700; width: 24px;">D.</label>
                    <input class="form-input" id="q-opt-3" type="text" placeholder="Option D text..." required>
                </div>
            </div>

            <div class="modal-actions">
                <button type="button" id="btn-cancel-question" class="btn btn-secondary btn-sm">Cancel</button>
                <button type="submit" class="btn btn-primary btn-sm">Save Question</button>
            </div>
        </form>
    </div>
</div>

<script src="${pageContext.request.contextPath}/assets/js/admin.js"></script>
</body>
</html>
