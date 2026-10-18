<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.quizmaster.model.Quiz, com.quizmaster.model.QuizAttempt" %>
<%
    Quiz quiz = (Quiz) request.getAttribute("quiz");
    QuizAttempt attempt = (QuizAttempt) request.getAttribute("attempt");
    Boolean resumed = (Boolean) request.getAttribute("resumed");
    String error = (String) request.getAttribute("error");
    String userName = (String) session.getAttribute("userName");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= quiz != null ? quiz.title.replace("<", "&lt;") : "Examination" %> | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css?v=20261019">
</head>
<body style="background: #f1f5f9; min-height: 100vh;">

<!-- Anti Cheat Warning Banner -->
<div id="anti-cheat-warning" class="anti-cheat-banner">
    ⚠️ Tab switch detected. Examinations are actively monitored.
</div>

<% if (error != null && !error.isBlank()) { %>
    <main class="container" style="padding: 60px 20px; max-width: 600px;">
        <div class="card" style="text-align: center; padding: 40px 24px;">
            <div style="font-size: 40px; margin-bottom: 16px;">⚠️</div>
            <h2 style="color: var(--c-error); margin-bottom: 12px;">Unable to Start Examination</h2>
            <p class="c-muted" style="margin-bottom: 24px;"><%= error.replace("<", "&lt;") %></p>
            <div class="flex justify-center gap-3">
                <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-primary">Return to Catalog</a>
                <a href="${pageContext.request.contextPath}/student/dashboard" class="btn btn-secondary">Dashboard</a>
            </div>
        </div>
    </main>
<% } else if (quiz != null && attempt != null) { %>

    <!-- Exam Root for JS Configuration -->
    <div id="exam-root"
         data-quiz-id="<%= quiz.id %>"
         data-attempt-id="<%= attempt.id %>"
         data-context-path="${pageContext.request.contextPath}"
         data-csrf-token="<%= session.getAttribute("csrfToken") %>">

        <!-- Exam Header -->
        <header class="exam-header">
            <div class="exam-title-wrap">
                <h1><%= quiz.title.replace("<", "&lt;") %></h1>
                <p>Candidate: <%= userName != null ? userName.replace("<", "&lt;") : "Student" %> &bull; <%= quiz.subject != null ? quiz.subject.replace("<", "&lt;") : "Exam" %></p>
            </div>

            <!-- Timer Display -->
            <div class="flex items-center gap-4">
                <div id="exam-timer" class="timer-badge timer-normal">
                    --:--
                </div>
                <button type="button" id="btn-submit-exam" class="btn btn-primary btn-sm">
                    Submit Exam
                </button>
            </div>
        </header>

        <!-- Loading State -->
        <div id="exam-loading" class="flex flex-col items-center justify-center" style="min-height: 60vh;">
            <div class="spinner" style="width: 36px; height: 36px; color: var(--c-accent); margin-bottom: 16px;"></div>
            <p class="c-muted">Securing examination environment & loading question bank...</p>
        </div>

        <!-- Main Exam Room Layout -->
        <main id="exam-content" class="exam-layout" style="display: none;">
            
            <!-- Question Box & Options Area -->
            <section class="question-area">
                <div class="question-top">
                    <span id="question-counter" class="question-number-tag">Question 1</span>
                    <div class="flex items-center gap-3">
                        <span id="question-marks" class="question-marks-tag">1 mark</span>
                        <button type="button" id="btn-review" class="btn btn-secondary btn-sm" style="font-size: 12px; padding: 5px 10px;">
                            ☆ Mark for Review
                        </button>
                    </div>
                </div>

                <div id="question-text" class="question-prompt">
                    Loading question...
                </div>

                <div id="options-container" class="options-list">
                    <!-- Option cards rendered dynamically via exam.js -->
                </div>

                <div class="question-footer">
                    <div class="flex items-center gap-3">
                        <button type="button" id="btn-clear" class="btn btn-ghost btn-sm">
                            Clear Selection
                        </button>
                        <span id="save-status" class="save-status"></span>
                    </div>

                    <div class="flex items-center gap-2">
                        <button type="button" id="btn-prev" class="btn btn-secondary btn-sm">
                            ← Previous
                        </button>
                        <button type="button" id="btn-next" class="btn btn-primary btn-sm">
                            Next Question →
                        </button>
                    </div>
                </div>
            </section>

            <!-- Question Palette Sidebar -->
            <aside class="palette-sidebar">
                <div class="palette-title">Question Navigator</div>
                <div class="palette-stats" id="answered-stats">0 Answered</div>

                <div class="progress-bar" style="margin-bottom: 20px;">
                    <div id="answered-progress-bar" class="progress-fill" style="width: 0%;"></div>
                </div>

                <div id="question-palette" class="palette-grid">
                    <!-- Palette buttons 1..N rendered dynamically -->
                </div>

                <div class="palette-legend">
                    <div class="legend-item">
                        <span class="legend-dot dot-answered"></span>
                        <span>Answered</span>
                    </div>
                    <div class="legend-item">
                        <span class="legend-dot dot-unanswered"></span>
                        <span>Unanswered</span>
                    </div>
                    <div class="legend-item">
                        <span class="legend-dot dot-marked"></span>
                        <span>Marked for Review</span>
                    </div>
                    <div class="legend-item">
                        <span class="legend-dot dot-current"></span>
                        <span>Current</span>
                    </div>
                </div>
            </aside>
        </main>
    </div>

    <!-- Submit Confirmation Modal -->
    <div id="submit-modal-backdrop" class="modal-backdrop">
        <div class="modal">
            <h3 class="modal-title">Confirm Exam Submission</h3>
            <p class="fz-sm c-muted" style="margin-bottom: 20px;">
                Are you ready to submit your exam for evaluation? Once submitted, you cannot modify your answers.
            </p>

            <div style="background: #f8fafc; border: 1px solid var(--c-border); border-radius: var(--r-md); padding: 16px; margin-bottom: 20px; font-size: 13px;">
                <div class="flex justify-between mb-2">
                    <span class="c-muted">Total Questions:</span>
                    <strong id="modal-stat-total">0</strong>
                </div>
                <div class="flex justify-between mb-2">
                    <span class="c-muted">Answered:</span>
                    <strong id="modal-stat-answered" class="c-success">0</strong>
                </div>
                <div class="flex justify-between mb-2">
                    <span class="c-muted">Unanswered:</span>
                    <strong id="modal-stat-unanswered" class="c-error">0</strong>
                </div>
                <div class="flex justify-between">
                    <span class="c-muted">Marked for Review:</span>
                    <strong id="modal-stat-review" style="color: var(--c-warn);">0</strong>
                </div>
            </div>

            <div class="modal-actions">
                <button type="button" id="modal-cancel" class="btn btn-secondary btn-sm">Keep Working</button>
                <button type="button" id="modal-confirm" class="btn btn-primary btn-sm">Yes, Submit Now</button>
            </div>
        </div>
    </div>

    <!-- Exam Engine Script -->
    <script src="${pageContext.request.contextPath}/assets/js/exam.js?v=20261019"></script>

<% } %>

</body>
</html>
