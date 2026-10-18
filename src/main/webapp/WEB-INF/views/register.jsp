<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Create Account | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/auth.css">
</head>
<body>
<main class="auth-layout">
    <section class="auth-intro">
        <a class="brand" href="${pageContext.request.contextPath}/">
            <span class="brand-icon">Q</span> QuizMaster
        </a>
        <div class="intro-content">
            <span class="eyebrow">STUDENT & CANDIDATE ONBOARDING</span>
            <h1>Every expert was once a beginner.</h1>
            <p>Create your candidate account and unlock access to timed certification exams, practice challenges, and instant score analytics.</p>
            <div class="feature"><span>✓</span> Comprehensive question banks</div>
            <div class="feature"><span>✓</span> Anti-cheat monitored exam sessions</div>
            <div class="feature"><span>✓</span> Full performance breakdown & history</div>
        </div>
        <p class="intro-footer">QuizMaster Enterprise Examination Engine</p>
    </section>

    <section class="auth-panel">
        <div class="auth-card">
            <div class="mobile-brand">Q <span>QuizMaster</span></div>
            <span class="eyebrow">GET STARTED</span>
            <h2>Create your account</h2>
            <p class="subtext">Join thousands of students and candidates.</p>

            <div id="js-client-error" class="form-error" style="display:none;" role="alert"></div>

            <% if (request.getAttribute("error") != null) { %>
                <p class="form-error" role="alert"><%= ((String) request.getAttribute("error")).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;") %></p>
            <% } %>
            <% if (request.getAttribute("success") != null) { %>
                <p class="form-success" role="status"><%= ((String) request.getAttribute("success")).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;") %></p>
            <% } %>

            <form method="post" action="${pageContext.request.contextPath}/register">
                <input type="hidden" name="_csrf" value="<%= request.getAttribute("csrfToken") %>">
                <label for="name">Full name</label>
                <input id="name" name="fullName" type="text"
                       placeholder="e.g. Alex Johnson" autocomplete="name" required autofocus>

                <label for="email">Email address</label>
                <input id="email" name="email" type="email"
                       placeholder="you@example.com" autocomplete="email" required>

                <label for="password">Password (min. 8 characters)</label>
                <div class="input-wrap">
                    <input id="password" name="password" type="password"
                           placeholder="Create a strong password" minlength="8"
                           autocomplete="new-password" required>
                    <button type="button" class="input-eye" data-target="password" aria-label="Toggle password visibility">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </button>
                </div>

                <label for="confirmPassword">Confirm password</label>
                <div class="input-wrap">
                    <input id="confirmPassword" name="confirmPassword" type="password"
                           placeholder="Re-enter your password" minlength="8"
                           autocomplete="new-password" required>
                    <button type="button" class="input-eye" data-target="confirmPassword" aria-label="Toggle confirm password visibility">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </button>
                </div>

                <button type="submit">Create account <span>→</span></button>
            </form>

            <p class="switch-auth">Already have an account?
                <a href="${pageContext.request.contextPath}/login">Sign in</a>
            </p>
            <a class="back-home" href="${pageContext.request.contextPath}/">← Back to home</a>
        </div>
    </section>
</main>
<script src="${pageContext.request.contextPath}/assets/js/auth.js"></script>
</body>
</html>
