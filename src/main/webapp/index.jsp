<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userRole = (String) session.getAttribute("userRole");
    boolean isLoggedIn = (userId != null && !userId.isBlank());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QuizMaster | Online Examination & Assessment Platform</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css">
    <style>
        .hero-section {
            padding: 80px 0 60px;
            text-align: center;
            background: radial-gradient(circle at 50% 20%, rgba(79, 70, 229, 0.08) 0%, transparent 60%);
        }
        .hero-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: #eef2ff;
            color: #4338ca;
            border: 1px solid #c7d2fe;
            padding: 6px 16px;
            border-radius: var(--r-full);
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 0.8px;
            text-transform: uppercase;
            margin-bottom: 24px;
        }
        .hero-title {
            font-size: clamp(34px, 5.5vw, 56px);
            font-weight: 800;
            line-height: 1.15;
            letter-spacing: -0.03em;
            color: var(--c-navy);
            max-width: 840px;
            margin: 0 auto 20px;
        }
        .hero-title .gradient-text {
            background: linear-gradient(135deg, #4f46e5 0%, #9333ea 50%, #2563eb 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero-subtitle {
            font-size: clamp(16px, 2vw, 19px);
            color: var(--c-muted);
            max-width: 660px;
            margin: 0 auto 36px;
            line-height: 1.6;
        }
        .hero-cta {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 16px;
            flex-wrap: wrap;
            margin-bottom: 50px;
        }
        .stats-strip {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            background: var(--c-surface);
            border: 1px solid var(--c-border);
            border-radius: var(--r-xl);
            padding: 28px;
            box-shadow: var(--sh-md);
            max-width: 960px;
            margin: 0 auto;
        }
        .stat-item {
            text-align: center;
        }
        .stat-number {
            font-size: 28px;
            font-weight: 800;
            color: var(--c-accent);
            line-height: 1;
            margin-bottom: 6px;
        }
        .stat-label {
            font-size: 13px;
            color: var(--c-muted);
            font-weight: 500;
        }
        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 24px;
            margin: 60px 0;
        }
        .feature-card {
            background: var(--c-surface);
            border: 1px solid var(--c-border);
            border-radius: var(--r-xl);
            padding: 32px 28px;
            transition: all var(--t-base);
            display: flex;
            flex-direction: column;
        }
        .feature-card:hover {
            transform: translateY(-4px);
            box-shadow: var(--sh-lg);
            border-color: #cbd5e1;
        }
        .feature-icon-box {
            width: 48px;
            height: 48px;
            border-radius: var(--r-md);
            display: grid;
            place-items: center;
            font-size: 22px;
            margin-bottom: 20px;
            background: #eef2ff;
            color: var(--c-accent);
        }
        .feature-card h3 {
            font-size: 19px;
            color: var(--c-navy);
            margin-bottom: 12px;
        }
        .feature-card p {
            font-size: 14px;
            color: var(--c-muted);
            line-height: 1.6;
        }
        .cta-banner {
            background: linear-gradient(135deg, #0f172a 0%, #1e1b4b 60%, #31104b 100%);
            border-radius: var(--r-xl);
            padding: 60px 40px;
            color: white;
            text-align: center;
            margin: 60px 0;
            box-shadow: var(--sh-xl);
        }
        .cta-banner h2 {
            font-size: 32px;
            font-weight: 800;
            margin-bottom: 16px;
            color: white;
        }
        .cta-banner p {
            color: #cbd5e1;
            max-width: 600px;
            margin: 0 auto 30px;
            font-size: 16px;
        }
        footer {
            border-top: 1px solid var(--c-border);
            padding: 36px 0;
            color: var(--c-muted);
            font-size: 13px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 16px;
        }
    </style>
</head>
<body>

<!-- Navigation Bar -->
<header class="topbar">
    <a href="${pageContext.request.contextPath}/" class="topbar-brand">
        <span class="logo-icon">Q</span>
        <span>QuizMaster</span>
    </a>
    <nav class="topbar-nav">
        <a href="#features">Features</a>
        <a href="#quizzes">Exam Catalog</a>
        <a href="#security">Security</a>
        <% if ("admin".equals(userRole)) { %>
            <a href="${pageContext.request.contextPath}/admin/dashboard">Admin Panel</a>
        <% } %>
    </nav>
    <div class="topbar-end">
        <% if (isLoggedIn) { %>
            <a href="${pageContext.request.contextPath}/student/dashboard" class="btn btn-secondary btn-sm">
                Dashboard (<%= userName != null ? userName.replace("<", "&lt;") : "Student" %>)
            </a>
            <form method="post" action="${pageContext.request.contextPath}/logout"><input type="hidden" name="_csrf" value="<%= session.getAttribute("csrfToken") %>"><button class="btn btn-ghost btn-sm" type="submit">Sign Out</button></form>
        <% } else { %>
            <a href="${pageContext.request.contextPath}/login" class="btn btn-secondary btn-sm">Sign In</a>
            <a href="${pageContext.request.contextPath}/register" class="btn btn-primary btn-sm">Get Started Free</a>
        <% } %>
    </div>
</header>

<main class="container">
    <!-- Hero Section -->
    <section class="hero-section">
        <div class="hero-badge">
            <span>✨</span> Next-Gen Online Examination Engine
        </div>
        <h1 class="hero-title">
            Assess with confidence.<br>
            <span class="gradient-text">Validate potential with precision.</span>
        </h1>
        <p class="hero-subtitle">
            A high-performance online examination system featuring live countdown timers,
            real-time answer autosave, anti-cheat detection, and instant server-side scoring.
        </p>

        <div class="hero-cta">
            <% if (isLoggedIn) { %>
                <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-primary btn-lg">
                    <span>Browse Exam Catalog</span> <span>→</span>
                </a>
                <a href="${pageContext.request.contextPath}/student/dashboard" class="btn btn-secondary btn-lg">
                    Go to Dashboard
                </a>
            <% } else { %>
                <a href="${pageContext.request.contextPath}/register" class="btn btn-primary btn-lg">
                    <span>Create Candidate Account</span> <span>→</span>
                </a>
                <a href="${pageContext.request.contextPath}/login" class="btn btn-secondary btn-lg">
                    Sign In
                </a>
            <% } %>
        </div>

        <!-- Live Metrics Strip -->
        <div class="stats-strip">
            <div class="stat-item">
                <div class="stat-number">100%</div>
                <div class="stat-label">Real-Time Autosave</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">&lt; 50ms</div>
                <div class="stat-label">Evaluation Latency</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">256-bit</div>
                <div class="stat-label">Server-Side Scoring</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">OWASP</div>
                <div class="stat-label">Hardened Security</div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section id="features" style="padding-top: 40px;">
        <div class="text-center">
            <span class="badge badge-info" style="margin-bottom: 12px;">ENGINE ARCHITECTURE</span>
            <h2>Built for Academic & Enterprise Assessments</h2>
            <p style="max-width: 580px; margin: 8px auto 0;">Every component engineered to ensure fairness, reliability, and zero data loss.</p>
        </div>

        <div class="feature-grid">
            <div class="feature-card">
                <div class="feature-icon-box">⏱️</div>
                <h3>Live Synchronized Timer</h3>
                <p>Enforces strict server-side deadlines with visual countdown cues, amber warnings, and automatic submission when time expires.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon-box">💾</div>
                <h3>Asynchronous Autosave</h3>
                <p>Every option selection is saved immediately to the cloud database. Page reloads and network hiccups never lose candidate work.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon-box">🛡️</div>
                <h3>Anti-Cheat & Tab Monitoring</h3>
                <p>Active proctoring hooks monitor browser visibility changes and tab switching, prompting warnings and logging candidate actions.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon-box">📊</div>
                <h3>Instant Score Breakdown</h3>
                <p>Zero client-side trust: questions are scored against server answer keys with immediate percentage, pass/fail evaluation, and full reviews.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon-box">🏷️</div>
                <h3>Question Review & Palette</h3>
                <p>Candidates can mark tricky questions for review, monitor answered vs unanswered counts, and navigate between questions effortlessly.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon-box">🔐</div>
                <h3>Role-Based Access Control</h3>
                <p>Strict boundaries separating students and instructors. Protected routes guarantee candidate result privacy and admin authorization.</p>
            </div>
        </div>
    </section>

    <!-- Quizzes Catalog Preview -->
    <section id="quizzes" style="padding-top: 30px;">
        <div class="text-center" style="margin-bottom: 36px;">
            <span class="badge badge-success" style="margin-bottom: 12px;">AVAILABLE CERTIFICATIONS</span>
            <h2>Featured Assessment Tracks</h2>
            <p style="max-width: 560px; margin: 8px auto 0;">Standardized examinations ready for testing and practice.</p>
        </div>

        <div class="grid-auto">
            <div class="card card-hover flex flex-col">
                <div class="flex justify-between items-center mb-4">
                    <span class="badge badge-info">Java Development</span>
                    <span class="fz-xs c-muted">20 Mins</span>
                </div>
                <h3 style="font-size: 18px; margin-bottom: 8px;">Jakarta Servlets & EE Architecture</h3>
                <p class="fz-sm" style="flex: 1; margin-bottom: 20px;">Mastery of Jakarta EE Servlet 6.0 lifecycle, HTTP filters, session state, and MVC architecture.</p>
                <div class="flex justify-between items-center" style="border-top: 1px solid var(--c-border); padding-top: 14px;">
                    <span class="fz-xs fw-600 c-muted">5 Questions • 60% Pass</span>
                    <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-primary btn-sm">Take Exam →</a>
                </div>
            </div>

            <div class="card card-hover flex flex-col">
                <div class="flex justify-between items-center mb-4">
                    <span class="badge badge-warn">Cybersecurity</span>
                    <span class="fz-xs c-muted">15 Mins</span>
                </div>
                <h3 style="font-size: 18px; margin-bottom: 8px;">Web Security & OWASP Top 10</h3>
                <p class="fz-sm" style="flex: 1; margin-bottom: 20px;">Assess CSRF defense mechanisms, XSS mitigation, secure cookie policies, and CSP directives.</p>
                <div class="flex justify-between items-center" style="border-top: 1px solid var(--c-border); padding-top: 14px;">
                    <span class="fz-xs fw-600 c-muted">5 Questions • 70% Pass</span>
                    <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-primary btn-sm">Take Exam →</a>
                </div>
            </div>

            <div class="card card-hover flex flex-col">
                <div class="flex justify-between items-center mb-4">
                    <span class="badge badge-success">Database Systems</span>
                    <span class="fz-xs c-muted">25 Mins</span>
                </div>
                <h3 style="font-size: 18px; margin-bottom: 8px;">Relational Databases & SQL</h3>
                <p class="fz-sm" style="flex: 1; margin-bottom: 20px;">Principles of ACID transactions, composite indexing strategies, 3NF normalization, and PostgREST.</p>
                <div class="flex justify-between items-center" style="border-top: 1px solid var(--c-border); padding-top: 14px;">
                    <span class="fz-xs fw-600 c-muted">5 Questions • 60% Pass</span>
                    <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-primary btn-sm">Take Exam →</a>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA Banner -->
    <section class="cta-banner">
        <h2>Ready to Validate Your Knowledge?</h2>
        <p>Join thousands of students and certification candidates taking online examinations with QuizMaster.</p>
        <% if (isLoggedIn) { %>
            <a href="${pageContext.request.contextPath}/student/quizzes" class="btn btn-primary btn-lg">Go to Exam Room →</a>
        <% } else { %>
            <a href="${pageContext.request.contextPath}/register" class="btn btn-primary btn-lg">Create Free Account →</a>
        <% } %>
    </section>

    <!-- Footer -->
    <footer>
        <div class="flex items-center gap-2">
            <span class="logo-icon" style="width: 24px; height: 24px; font-size: 13px; border-radius: 6px; display: inline-grid; place-items: center; background: var(--c-accent); color: white; font-weight: 800;">Q</span>
            <strong>QuizMaster</strong> &copy; 2026. All rights reserved.
        </div>
        <div class="flex gap-4">
            <a href="${pageContext.request.contextPath}/login">Candidate Login</a>
            <a href="${pageContext.request.contextPath}/register">Candidate Register</a>
            <a href="${pageContext.request.contextPath}/admin/dashboard">Administration</a>
        </div>
    </footer>
</main>

</body>
</html>
