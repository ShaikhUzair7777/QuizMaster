<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, java.net.URLEncoder, java.nio.charset.StandardCharsets, com.quizmaster.model.Quiz, com.quizmaster.model.QuizAttempt, com.quizmaster.model.LearningTopic, com.quizmaster.util.HtmlUtils" %>
<%
    String userName = (String) request.getAttribute("userName");
    String userEmail = (String) request.getAttribute("userEmail");
    String dbError = (String) request.getAttribute("dbError");
    Integer attempted = (Integer) request.getAttribute("attempted");
    String avgScore = (String) request.getAttribute("avgScore");
    Integer totalQuizzes = (Integer) request.getAttribute("totalQuizzes");
    List<Quiz> quizzes = (List<Quiz>) request.getAttribute("quizzes");
    List<QuizAttempt> attempts = (List<QuizAttempt>) request.getAttribute("attempts");
    List<LearningTopic> learningTopics = (List<LearningTopic>) request.getAttribute("learningTopics");
    List<LearningTopic> featuredTopics = (List<LearningTopic>) request.getAttribute("featuredTopics");
    List<LearningTopic> recentTopics = (List<LearningTopic>) request.getAttribute("recentTopics");
    String catalogError = (String) request.getAttribute("catalogError");
    if (attempted == null) attempted = 0;
    if (avgScore == null) avgScore = "0.0";
    if (totalQuizzes == null) totalQuizzes = 0;
    if (learningTopics == null) learningTopics = List.of();
    if (featuredTopics == null) featuredTopics = List.of();
    if (recentTopics == null) recentTopics = List.of();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Candidate Dashboard | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css">
    <style>
        .library-filters { display:flex; gap:12px; flex-wrap:wrap; align-items:end; margin:18px 0 22px; }
        .library-filters .form-group { flex:1 1 190px; margin:0; }
        .topic-highlight-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:12px; }
        .topic-highlight { border:1px solid var(--c-border); border-radius:var(--r-md); padding:14px; background:var(--c-bg); }
        .topic-highlight-card[hidden] { display:none !important; }
        .topic-card[hidden] { display:none !important; }
        .topic-card { min-width:0; }
        @media (max-width:600px) { .library-filters { align-items:stretch; } .library-filters .form-group { flex-basis:100%; } }
    </style>
</head>
<body>

<!-- Top Navigation -->
<header class="topbar">
    <a href="${pageContext.request.contextPath}/" class="topbar-brand">
        <span class="logo-icon">Q</span>
        <span>QuizMaster</span>
    </a>
    <nav class="topbar-nav">
        <a href="${pageContext.request.contextPath}/student/dashboard" class="active">Dashboard</a>
        <a href="${pageContext.request.contextPath}/student/quizzes">Exam Catalog</a>
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

    <!-- Welcome Hero -->
    <div class="card" style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 60%, #312e81 100%); color: white; padding: 36px 32px; border: none; margin-bottom: 32px;">
        <span class="badge badge-info" style="margin-bottom: 12px; background: rgba(255,255,255,0.15); color: white; border-color: rgba(255,255,255,0.25);">CANDIDATE WORKSPACE</span>
        <h1 style="font-size: 32px; margin-bottom: 8px; color: white;">Welcome back, <%= userName != null ? userName.replace("<", "&lt;") : "Student" %></h1>
        <p style="color: #cbd5e1; max-width: 600px; font-size: 15px;">Your examination center is ready. Review your stats, start a scheduled assessment, or explore new tracks.</p>
    </div>

    <section class="card" style="margin-bottom: 36px;">
        <h2 style="font-size: 21px; margin-bottom: 10px;">Your learning snapshot</h2>
        <% if (attempted == 0) { %>
            <p>No completed quizzes yet. Complete a quiz to see score-based practice suggestions here.</p>
        <% } else { %>
            <p>You have completed <strong><%= attempted %></strong> quizzes, averaging <strong><%= avgScore %>%</strong>.
                <% if ("Hard".equals(request.getAttribute("recommendedDifficulty"))) { %>
                    Your current results suggest trying a harder quiz.
                <% } else if ("Easy".equals(request.getAttribute("recommendedDifficulty"))) { %>
                    Start with an easier quiz to reinforce fundamentals.
                <% } else { %>
                    Medium difficulty is a balanced next step based on your scores.
                <% } %>
            </p>
            <% java.util.Map<String, Double> revisionTopics =
                    (java.util.Map<String, Double>) request.getAttribute("revisionTopics");
               if (revisionTopics != null && !revisionTopics.isEmpty()) { %>
                <p style="margin-top: 8px;"><strong>Consider revisiting:</strong>
                    <% int topicCount = 0; for (java.util.Map.Entry<String, Double> topic : revisionTopics.entrySet()) {
                        if (topicCount++ > 0) { %>, <% } %>
                        <%= topic.getKey().replace("&", "&amp;").replace("<", "&lt;") %>
                        (<%= String.format("%.0f", topic.getValue()) %>% average)
                    <% } %>
                </p>
            <% } %>
        <% } %>
        <p class="form-hint" style="margin-top: 8px;">Recommendations are simple rules based on your completed attempts, not machine learning.</p>
    </section>

    <% if (dbError != null && !dbError.isBlank()) { %>
        <div class="alert alert-warn" style="margin-bottom: 24px;">
            <div>
                <strong>Database Setup Notice:</strong> <%= dbError.replace("<", "&lt;") %>
                <p class="fz-xs" style="margin-top: 4px; color: inherit;">Please ensure your Supabase credentials are configured in your environment or <code>.env</code> file.</p>
            </div>
        </div>
    <% } %>

    <!-- Statistics Grid -->
    <div class="grid-auto" style="margin-bottom: 36px;">
        <div class="stat-card">
            <div class="stat-icon" style="background: #eef2ff; color: var(--c-accent);">📋</div>
            <div class="stat-value"><%= totalQuizzes %></div>
            <div class="stat-label">Available Examinations</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #f0fdf4; color: var(--c-success);">✍️</div>
            <div class="stat-value"><%= attempted %></div>
            <div class="stat-label">Exams Completed</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #eff6ff; color: var(--c-info);">🎯</div>
            <div class="stat-value"><%= avgScore %>%</div>
            <div class="stat-label">Average Score</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background: #faf5ff; color: var(--c-violet);">⚡</div>
            <div class="stat-value">Live</div>
            <div class="stat-label">Engine Status</div>
        </div>
    </div>

    <section class="card" aria-labelledby="library-heading" style="margin-bottom: 36px;">
        <div class="flex justify-between items-center" style="gap: 14px; flex-wrap: wrap;">
            <div>
                <span class="badge badge-info">50 CURATED TOPICS</span>
                <h2 id="library-heading" style="margin-top: 8px;">Explore the learning library</h2>
                <p class="fz-sm c-muted">These are topic guides, not preloaded exams. Generate a private quiz from any topic in one click.</p>
            </div>
            <a class="btn btn-primary" href="${pageContext.request.contextPath}/student/ai-quizzes">Generate an AI quiz</a>
        </div>
        <% if (catalogError != null) { %>
            <div class="alert alert-warn" role="status" style="margin-top:16px;"><%= HtmlUtils.escape(catalogError) %></div>
        <% } else if (!featuredTopics.isEmpty() || !recentTopics.isEmpty()) { %>
            <div id="topic-highlights" class="grid-auto" style="grid-template-columns:repeat(auto-fit,minmax(260px,1fr)); margin-top:20px;">
                <section class="topic-highlight-section" aria-labelledby="featured-topics-heading">
                    <h3 id="featured-topics-heading" style="margin-bottom:10px;">Featured topics</h3>
                    <div class="topic-highlight-grid">
                        <% for (LearningTopic topic : featuredTopics) {
                            String topicUrl = request.getContextPath() + "/student/ai-quizzes?topic="
                                    + URLEncoder.encode(topic.title, StandardCharsets.UTF_8)
                                    + "&category=" + URLEncoder.encode(topic.category, StandardCharsets.UTF_8)
                                    + "&difficulty=" + URLEncoder.encode(topic.difficulty, StandardCharsets.UTF_8); %>
                            <article class="topic-highlight topic-highlight-card"
                                     data-search="<%= HtmlUtils.escape((topic.title + " " + topic.category + " " + topic.description).toLowerCase(java.util.Locale.ROOT)) %>"
                                     data-category="<%= HtmlUtils.escape(topic.category) %>"
                                     data-difficulty="<%= HtmlUtils.escape(topic.difficulty) %>">
                                <span class="badge badge-info"><%= HtmlUtils.escape(topic.category) %></span>
                                <h4 style="margin:8px 0 4px;"><%= HtmlUtils.escape(topic.title) %></h4>
                                <p class="fz-xs c-muted"><%= HtmlUtils.escape(topic.difficulty) %> · No saved questions</p>
                                <a class="fz-sm" href="<%= HtmlUtils.escape(topicUrl) %>">Generate a private quiz →</a>
                            </article>
                        <% } %>
                    </div>
                </section>
                <section class="topic-highlight-section" aria-labelledby="recent-topics-heading">
                    <h3 id="recent-topics-heading" style="margin-bottom:10px;">Recently added topics</h3>
                    <div class="topic-highlight-grid">
                        <% for (LearningTopic topic : recentTopics) {
                            String topicUrl = request.getContextPath() + "/student/ai-quizzes?topic="
                                    + URLEncoder.encode(topic.title, StandardCharsets.UTF_8)
                                    + "&category=" + URLEncoder.encode(topic.category, StandardCharsets.UTF_8)
                                    + "&difficulty=" + URLEncoder.encode(topic.difficulty, StandardCharsets.UTF_8); %>
                            <article class="topic-highlight topic-highlight-card"
                                     data-search="<%= HtmlUtils.escape((topic.title + " " + topic.category + " " + topic.description).toLowerCase(java.util.Locale.ROOT)) %>"
                                     data-category="<%= HtmlUtils.escape(topic.category) %>"
                                     data-difficulty="<%= HtmlUtils.escape(topic.difficulty) %>">
                                <span class="badge badge-neutral"><%= HtmlUtils.escape(topic.category) %></span>
                                <h4 style="margin:8px 0 4px;"><%= HtmlUtils.escape(topic.title) %></h4>
                                <p class="fz-xs c-muted"><%= HtmlUtils.escape(topic.difficulty) %> · No saved questions</p>
                                <a class="fz-sm" href="<%= HtmlUtils.escape(topicUrl) %>">Generate a private quiz →</a>
                            </article>
                        <% } %>
                    </div>
                </section>
            </div>
        <% } %>

        <div class="library-filters">
            <div class="form-group">
                <label class="form-label" for="topic-search">Search title, category, or subject</label>
                <input class="form-input" type="search" id="topic-search" placeholder="Try “recursion” or “psychology”">
            </div>
            <div class="form-group">
                <label class="form-label" for="topic-category">Category</label>
                <select class="form-input" id="topic-category">
                    <option value="">All categories</option>
                    <% for (String category : LearningTopic.CATEGORIES) { %>
                        <option value="<%= HtmlUtils.escape(category) %>"><%= HtmlUtils.escape(category) %></option>
                    <% } %>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="topic-difficulty">Suggested level</label>
                <select class="form-input" id="topic-difficulty">
                    <option value="">All levels</option>
                    <option>Beginner</option><option>Intermediate</option><option>Advanced</option>
                </select>
            </div>
        </div>
        <p class="fz-sm c-muted" aria-live="polite"><span id="topic-count"><%= learningTopics.size() %></span> topics</p>
        <div id="topic-grid" class="grid-auto" style="margin-top:14px;">
            <% for (LearningTopic topic : learningTopics) {
                String topicUrl = request.getContextPath() + "/student/ai-quizzes?topic="
                        + URLEncoder.encode(topic.title, StandardCharsets.UTF_8)
                        + "&category=" + URLEncoder.encode(topic.category, StandardCharsets.UTF_8)
                        + "&difficulty=" + URLEncoder.encode(topic.difficulty, StandardCharsets.UTF_8);
                String searchText = topic.title + " " + topic.category + " " + topic.description; %>
                <article class="card card-hover flex flex-col topic-card"
                         data-search="<%= HtmlUtils.escape(searchText.toLowerCase(java.util.Locale.ROOT)) %>"
                         data-category="<%= HtmlUtils.escape(topic.category) %>"
                         data-difficulty="<%= HtmlUtils.escape(topic.difficulty) %>">
                    <div class="flex justify-between items-center mb-2">
                        <span class="badge badge-info"><%= HtmlUtils.escape(topic.category) %></span>
                        <% if (topic.featured) { %><span class="badge badge-warn">Featured</span><% } %>
                    </div>
                    <h3 style="font-size:17px; margin-bottom:6px;"><%= HtmlUtils.escape(topic.title) %></h3>
                    <p class="fz-sm" style="flex:1; margin-bottom:14px;"><%= HtmlUtils.escape(topic.description) %></p>
                    <div class="flex justify-between items-center" style="border-top:1px solid var(--c-border); padding-top:12px;">
                        <span class="fz-xs c-muted"><%= HtmlUtils.escape(topic.difficulty) %> · 0 stored questions</span>
                        <a class="btn btn-primary btn-sm" href="<%= HtmlUtils.escape(topicUrl) %>">Generate</a>
                    </div>
                </article>
            <% } %>
            <div id="topic-empty" class="card" style="grid-column:1/-1; text-align:center;" hidden>
                <p>No topics match these filters. Try another search or select “All”.</p>
            </div>
            <% if (learningTopics.isEmpty() && catalogError == null) { %>
                <div class="card" style="grid-column:1/-1; text-align:center;">
                    <p>No learning topics are available yet. Apply database migration 002 to load the curated library.</p>
                </div>
            <% } %>
        </div>
    </section>

    <!-- Quick Actions Banner -->
    <div class="flex justify-between items-center" style="margin-bottom: 20px;">
        <div>
            <h2>Published assessments</h2>
            <p class="fz-sm c-muted">These quizzes have stored questions and are ready to play</p>
        </div>
        <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-secondary btn-sm">View All Quizzes →</a>
    </div>

    <!-- Quizzes Grid -->
    <div class="grid-auto" style="margin-bottom: 48px;">
        <% if (quizzes != null && !quizzes.isEmpty()) { %>
            <% for (Quiz q : quizzes) { %>
                <div class="card card-hover flex flex-col">
                    <div class="flex justify-between items-center mb-2">
                        <span class="badge badge-info"><%= q.subject != null ? q.subject.replace("<", "&lt;") : "General" %></span>
                        <span class="fz-xs c-muted">⏱️ <%= q.durationMinutes %> min</span>
                    </div>
                    <h3 style="font-size: 17px; margin-bottom: 6px;"><%= q.title != null ? q.title.replace("<", "&lt;") : "Quiz" %></h3>
                    <p class="fz-sm" style="flex: 1; margin-bottom: 16px;">
                        <%= q.description != null ? q.description.replace("<", "&lt;") : "No description provided." %>
                    </p>
                    <div class="flex justify-between items-center" style="border-top: 1px solid var(--c-border); padding-top: 14px;">
                        <span class="fz-xs fw-600 c-muted"><%= q.questionCount %> questions • <%= q.passMark %>% pass</span>
                        <a href="${pageContext.request.contextPath}/student/exam?quizId=<%= q.id %>" class="btn btn-primary btn-sm">Start Exam</a>
                    </div>
                </div>
            <% } %>
        <% } else { %>
            <div class="card" style="grid-column: 1 / -1; text-align: center; padding: 40px 20px;">
                <p class="c-muted">No published examinations currently available.</p>
            </div>
        <% } %>
    </div>

    <!-- Recent Attempts Section -->
    <div class="flex justify-between items-center" style="margin-bottom: 20px;">
        <div>
            <h2>Recent Exam Attempts</h2>
            <p class="fz-sm c-muted">Your latest test scores and performance</p>
        </div>
        <a href="${pageContext.request.contextPath}/student/history" class="btn btn-secondary btn-sm">Complete History →</a>
    </div>

    <div class="card" style="padding: 0; overflow: hidden;">
        <div class="table-wrap" style="border: none;">
            <table>
                <thead>
                    <tr>
                        <th>Attempt Date</th>
                        <th>Status</th>
                        <th>Score</th>
                        <th>Percentage</th>
                        <th>Result</th>
                        <th style="text-align: right;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (attempts != null && !attempts.isEmpty()) { %>
                        <% for (QuizAttempt a : attempts) { %>
                            <tr>
                                <td><%= a.submittedAt != null ? a.submittedAt.toString().substring(0, 16).replace("T", " ") : (a.startedAt != null ? a.startedAt.toString().substring(0, 16).replace("T", " ") : "Recent") %></td>
                                <td>
                                    <% if ("submitted".equals(a.status)) { %>
                                        <span class="badge badge-success">Completed</span>
                                    <% } else if ("in_progress".equals(a.status)) { %>
                                        <span class="badge badge-warn">In Progress</span>
                                    <% } else { %>
                                        <span class="badge badge-neutral"><%= a.status %></span>
                                    <% } %>
                                </td>
                                <td><strong><%= a.score %></strong> / <%= a.totalQuestions %></td>
                                <td><strong><%= String.format("%.1f", a.percentage) %>%</strong></td>
                                <td>
                                    <% if (a.passed) { %>
                                        <span class="badge badge-success">PASS</span>
                                    <% } else { %>
                                        <span class="badge badge-error">FAIL</span>
                                    <% } %>
                                </td>
                                <td style="text-align: right;">
                                    <% if ("in_progress".equals(a.status)) { %>
                                        <a href="${pageContext.request.contextPath}/student/exam?quizId=<%= a.quizId %>" class="btn btn-primary btn-sm">Resume</a>
                                    <% } else { %>
                                        <a href="${pageContext.request.contextPath}/student/result?attemptId=<%= a.id %>" class="btn btn-secondary btn-sm">View Report</a>
                                    <% } %>
                                </td>
                            </tr>
                        <% } %>
                    <% } else { %>
                        <tr>
                            <td colspan="6" style="text-align: center; padding: 32px; color: var(--c-muted);">
                                No exam attempts yet. Select an examination above to test your skills!
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

</main>

<script>
(() => {
    const search = document.getElementById('topic-search');
    const category = document.getElementById('topic-category');
    const difficulty = document.getElementById('topic-difficulty');
    const cards = [...document.querySelectorAll('.topic-card')];
    const highlights = [...document.querySelectorAll('.topic-highlight-card')];
    const highlightSections = [...document.querySelectorAll('.topic-highlight-section')];
    const highlightContainer = document.getElementById('topic-highlights');
    const count = document.getElementById('topic-count');
    const empty = document.getElementById('topic-empty');
    const filter = () => {
        const query = search.value.trim().toLocaleLowerCase();
        let visible = 0;
        cards.forEach(card => {
            const matches = card.dataset.search.includes(query)
                && (!category.value || card.dataset.category === category.value)
                && (!difficulty.value || card.dataset.difficulty === difficulty.value);
            card.hidden = !matches;
            if (matches) visible++;
        });
        if (highlightContainer) {
            highlights.forEach(card => {
                card.hidden = !(card.dataset.search.includes(query)
                    && (!category.value || card.dataset.category === category.value)
                    && (!difficulty.value || card.dataset.difficulty === difficulty.value));
            });
            highlightSections.forEach(section => {
                section.hidden = !section.querySelector('.topic-highlight-card:not([hidden])');
            });
            highlightContainer.hidden = !highlightSections.some(section => !section.hidden);
        }
        count.textContent = visible;
        empty.hidden = visible !== 0;
    };
    search.addEventListener('input', filter);
    category.addEventListener('change', filter);
    difficulty.addEventListener('change', filter);
})();
</script>
</body>
</html>
