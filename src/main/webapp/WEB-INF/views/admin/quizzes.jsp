<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, com.quizmaster.model.Quiz" %>
<%
    List<Quiz> quizzes = (List<Quiz>) request.getAttribute("quizzes");
    String dbError = (String) request.getAttribute("dbError");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="<%= session.getAttribute("csrfToken") %>">
    <title>Quiz Management | QuizMaster Admin</title>
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

<main class="container" style="padding-top: 32px; padding-bottom: 60px;">

    <div class="flex justify-between items-center" style="margin-bottom: 24px; flex-wrap: wrap; gap: 12px;">
        <div>
            <h1>Quiz & Examination Management</h1>
            <p class="fz-sm c-muted">Create, configure, and manage published assessment tracks</p>
        </div>
        <button type="button" id="btn-new-quiz" class="btn btn-primary btn-sm">
            + Create New Quiz
        </button>
    </div>

    <% if (dbError != null && !dbError.isBlank()) { %>
        <div class="alert alert-error" style="margin-bottom: 24px;">
            <div><strong>Notice:</strong> <%= dbError.replace("<", "&lt;") %></div>
        </div>
    <% } %>

    <!-- Quizzes Table -->
    <div class="card" style="padding: 0; overflow: hidden;">
        <div class="table-wrap" style="border: none;">
            <table>
                <thead>
                    <tr>
                        <th>Title & Subject</th>
                        <th>Duration</th>
                        <th>Pass Mark</th>
                        <th>Max Attempts</th>
                        <th>Questions</th>
                        <th>Status</th>
                        <th style="text-align: right;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (quizzes != null && !quizzes.isEmpty()) { %>
                        <% for (Quiz q : quizzes) { %>
                            <tr>
                                <td>
                                    <strong><%= q.title != null ? q.title.replace("<", "&lt;") : "Untitled" %></strong>
                                    <div class="fz-xs c-muted"><%= q.subject != null ? q.subject.replace("<", "&lt;") : "General" %></div>
                                </td>
                                <td><%= q.durationMinutes %> mins</td>
                                <td><%= q.passMark %>%</td>
                                <td><%= q.maxAttempts > 0 ? q.maxAttempts : "Unlimited" %></td>
                                <td>
                                    <span class="badge badge-neutral"><%= q.questionCount %> questions</span>
                                </td>
                                <td>
                                    <% if (q.published) { %>
                                        <span class="badge badge-success">● Published</span>
                                    <% } else { %>
                                        <span class="badge badge-warn">○ Draft</span>
                                    <% } %>
                                </td>
                                <td style="text-align: right;">
                                    <div class="flex items-center justify-center gap-2" style="justify-content: flex-end;">
                                        <a href="${pageContext.request.contextPath}/admin/questions?quizId=<%= q.id %>" class="btn btn-secondary btn-sm" title="Manage questions in bank">
                                            Questions (<%= q.questionCount %>)
                                        </a>
                                        <button type="button" class="btn btn-ghost btn-sm btn-edit-quiz"
                                                data-id="<%= q.id %>"
                                                data-title="<%= q.title != null ? q.title.replace("\"", "&quot;") : "" %>"
                                                data-subject="<%= q.subject != null ? q.subject.replace("\"", "&quot;") : "" %>"
                                                data-duration="<%= q.durationMinutes %>"
                                                data-passmark="<%= q.passMark %>"
                                                data-attempts="<%= q.maxAttempts %>"
                                                data-desc="<%= q.description != null ? q.description.replace("\"", "&quot;") : "" %>"
                                                data-published="<%= q.published %>">
                                            Edit
                                        </button>
                                        <button type="button" class="btn btn-ghost btn-sm btn-delete-quiz" style="color: var(--c-error);"
                                                data-id="<%= q.id %>"
                                                data-title="<%= q.title != null ? q.title.replace("\"", "&quot;") : "" %>"
                                                data-context-path="${pageContext.request.contextPath}">
                                            Delete
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        <% } %>
                    <% } else { %>
                        <tr>
                            <td colspan="7" style="text-align: center; padding: 48px; color: var(--c-muted);">
                                No quizzes created yet. Click "+ Create New Quiz" to add your first assessment.
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

</main>

<!-- Create / Edit Quiz Modal -->
<div id="quiz-modal-backdrop" class="modal-backdrop">
    <div class="modal" style="max-width: 540px;">
        <h3 id="quiz-modal-title" class="modal-title">Create New Quiz</h3>

        <form id="quiz-form" method="post" action="${pageContext.request.contextPath}/admin/quizzes">
            <input type="hidden" id="quiz-id" name="id" value="">

            <div class="form-group mb-3">
                <label class="form-label" for="quiz-title">Quiz Title *</label>
                <input class="form-input" id="quiz-title" name="title" type="text" placeholder="e.g. Advanced Java Concurrency" required>
            </div>

            <div class="form-group mb-3">
                <label class="form-label" for="quiz-subject">Subject / Category *</label>
                <input class="form-input" id="quiz-subject" name="subject" type="text" placeholder="e.g. Computer Science" required>
            </div>

            <div class="grid-auto" style="grid-template-columns: 1fr 1fr 1fr; gap: 12px; margin-bottom: 14px;">
                <div class="form-group">
                    <label class="form-label" for="quiz-duration">Duration (mins)</label>
                    <input class="form-input" id="quiz-duration" name="durationMinutes" type="number" min="1" max="300" value="30" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="quiz-passmark">Pass Mark (%)</label>
                    <input class="form-input" id="quiz-passmark" name="passMark" type="number" min="0" max="100" value="50" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="quiz-attempts">Max Attempts</label>
                    <input class="form-input" id="quiz-attempts" name="maxAttempts" type="number" min="1" max="10" value="1" required>
                </div>
            </div>

            <div class="form-group mb-3">
                <label class="form-label" for="quiz-desc">Description</label>
                <textarea class="form-input" id="quiz-desc" name="description" rows="3" placeholder="Brief outline of syllabus and goals..."></textarea>
            </div>

            <div class="flex items-center gap-2 mb-4">
                <input type="checkbox" id="quiz-published" name="published" value="true">
                <label for="quiz-published" style="font-size: 14px; font-weight: 600; cursor: pointer;">
                    Publish Quiz (makes visible in student exam catalog)
                </label>
            </div>

            <div class="modal-actions">
                <button type="button" id="btn-cancel-quiz" class="btn btn-secondary btn-sm">Cancel</button>
                <button type="submit" class="btn btn-primary btn-sm">Save Quiz</button>
            </div>
        </form>
    </div>
</div>

<script src="${pageContext.request.contextPath}/assets/js/admin.js"></script>
</body>
</html>
