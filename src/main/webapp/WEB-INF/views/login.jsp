<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign In | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/auth.css">
</head>
<body>
<main class="auth-layout">
    <section class="auth-intro">
        <a class="brand" href="${pageContext.request.contextPath}/">
            <span class="brand-icon">Q</span> QuizMaster
        </a>
        <div class="intro-content">
            <span class="eyebrow">ONLINE EXAMINATION PLATFORM</span>
            <h1>Knowledge is your greatest advantage.</h1>
            <p>Practice smarter, test your mastery with timed exams, and track your performance trends with QuizMaster.</p>
            <div class="feature"><span>✓</span> Timed interactive examinations</div>
            <div class="feature"><span>✓</span> Real-time question autosave</div>
            <div class="feature"><span>✓</span> Instant scoring & comprehensive answer review</div>
        </div>
        <p class="intro-footer">QuizMaster Enterprise Examination Engine</p>
    </section>

    <section class="auth-panel">
        <div class="auth-card">
            <div class="mobile-brand">Q <span>QuizMaster</span></div>
            <span class="eyebrow">WELCOME BACK</span>
            <h2>Sign in to your account</h2>
            <p class="subtext">Continue your assessments and learning journey.</p>

            <% if (request.getAttribute("error") != null) { %>
                <p class="form-error" role="alert"><%= ((String) request.getAttribute("error")).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;") %></p>
            <% } %>
            <% if (request.getAttribute("success") != null) { %>
                <p class="form-success" role="status"><%= ((String) request.getAttribute("success")).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;") %></p>
            <% } %>

            <form method="post" action="${pageContext.request.contextPath}/login">
                <input type="hidden" name="_csrf" value="<%= request.getAttribute("csrfToken") %>">
                <label for="email">Email address</label>
                <input id="email" name="email" type="email"
                       placeholder="you@example.com" autocomplete="email" required autofocus>

                <label for="password">Password</label>
                <div class="input-wrap">
                    <input id="password" name="password" type="password"
                           placeholder="Enter your password"
                           autocomplete="current-password" required>
                    <button type="button" class="input-eye" data-target="password" aria-label="Toggle password visibility">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </button>
                </div>

                <button type="submit">Sign in <span>→</span></button>
            </form>

            <p class="switch-auth">New to QuizMaster?
                <a href="${pageContext.request.contextPath}/register">Create an account</a>
            </p>
            <a class="back-home" href="${pageContext.request.contextPath}/">← Back to home</a>
        </div>
    </section>
</main>
<script src="${pageContext.request.contextPath}/assets/js/auth.js"></script>
</body>
</html>
