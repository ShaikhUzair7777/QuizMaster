package com.quizmaster.controller;

import com.quizmaster.service.SupabaseAuthService;
import com.quizmaster.service.SupabaseAuthService.AuthResult;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HexFormat;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

public class AuthPageServlet extends HttpServlet {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final java.util.regex.Pattern EMAIL_PATTERN =
            java.util.regex.Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    private SupabaseAuthService authService;

    @Override
    public void init() {
        authService = new SupabaseAuthService();
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {
        String path = request.getServletPath();
        if ("/login".equals(path) || "/register".equals(path)) {
            request.setAttribute("csrfToken", csrfToken(request.getSession(true)));
        }

        // If user is already authenticated, send them straight to the dashboard
        HttpSession existingSession = request.getSession(false);
        boolean authenticated = existingSession != null
                && existingSession.getAttribute("accessToken") != null;
        String role = authenticated
                ? (String) existingSession.getAttribute("userRole") : null;
        String dashboard = "admin".equals(role)
                ? "/admin/dashboard" : "/student/dashboard";

        switch (path) {
            case "/login" -> {
                if (authenticated) {
                    response.sendRedirect(request.getContextPath() + dashboard);
                    return;
                }
                request.getRequestDispatcher("/WEB-INF/views/login.jsp")
                       .forward(request, response);
            }
            case "/register" -> {
                if (authenticated) {
                    response.sendRedirect(request.getContextPath() + dashboard);
                    return;
                }
                request.getRequestDispatcher("/WEB-INF/views/register.jsp")
                       .forward(request, response);
            }
            case "/logout" -> {
                response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            }
            default -> response.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setContentType("text/html; charset=UTF-8");

        String path = request.getServletPath();
        if ("/logout".equals(path)) {
            HttpSession session = request.getSession(false);
            String expected = session == null ? null : (String) session.getAttribute("csrfToken");
            String supplied = request.getParameter("_csrf");
            if (expected == null || supplied == null || !MessageDigest.isEqual(
                    expected.getBytes(StandardCharsets.UTF_8),
                    supplied.getBytes(StandardCharsets.UTF_8))) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "Request verification failed. Refresh and try again.");
                return;
            }
            session.invalidate();
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
        HttpSession authSession = request.getSession(false);
        String expectedToken = authSession == null
                ? null : (String) authSession.getAttribute("csrfToken");
        String suppliedToken = request.getParameter("_csrf");
        if (expectedToken == null || suppliedToken == null || !MessageDigest.isEqual(
                expectedToken.getBytes(StandardCharsets.UTF_8),
                suppliedToken.getBytes(StandardCharsets.UTF_8))) {
            request.setAttribute("csrfToken", expectedToken);
            request.setAttribute("error", "Request verification failed. Refresh the page and try again.");
            forwardForm(request, response, path);
            return;
        }
        request.setAttribute("csrfToken", expectedToken);
        String email = clean(request.getParameter("email"));
        String password = request.getParameter("password");

        if (email == null || email.length() > 254
                || !EMAIL_PATTERN.matcher(email).matches()
                || password == null || password.isEmpty() || password.length() > 1024) {
            request.setAttribute("error", "Enter a valid email address and password.");
            forwardForm(request, response, path);
            return;
        }

        try {
            AuthResult result;

            if ("/register".equals(path)) {
                String fullName = clean(request.getParameter("fullName"));
                String confirm  = request.getParameter("confirmPassword");
                if (fullName == null || fullName.length() > 255) {
                    request.setAttribute("error", "Enter your name (up to 255 characters).");
                    forwardForm(request, response, path);
                    return;
                }
                if (password.length() < 8) {
                    request.setAttribute("error", "Password must be at least 8 characters.");
                    forwardForm(request, response, path);
                    return;
                }
                if (confirm == null || !confirm.equals(password)) {
                    request.setAttribute("error", "Passwords do not match.");
                    forwardForm(request, response, path);
                    return;
                }
                result = authService.register(fullName, email, password);
                if (result.success) {
                    if (result.accessToken != null && result.userId != null) {
                        HttpSession session = request.getSession(true);
                        request.changeSessionId();
                        rotateCsrfToken(session);
                        session.setMaxInactiveInterval(30 * 60);
                        session.setAttribute("accessToken", result.accessToken);
                        session.setAttribute("userId",      result.userId);
                        session.setAttribute("userEmail",   result.email);
                        session.setAttribute("userName",    result.fullName != null ? result.fullName : result.email);
                        String role = "admin".equals(result.role) ? "admin" : "student";
                        session.setAttribute("userRole", role);
                        String dest = "admin".equals(role)
                                ? "/admin/dashboard" : "/student/dashboard";
                        response.sendRedirect(request.getContextPath() + dest);
                        return;
                    }
                    if (result.accessToken != null) {
                        request.setAttribute("error",
                                "The account was created, but its identity could not be verified. Please sign in.");
                        forwardForm(request, response, path);
                        return;
                    }
                    request.setAttribute("success", result.message);
                    request.getRequestDispatcher("/WEB-INF/views/register.jsp")
                           .forward(request, response);
                    return;
                }

            } else if ("/login".equals(path)) {
                result = authService.login(email, password);
                if (result.success && result.accessToken != null && result.userId != null) {
                    HttpSession session = request.getSession(true);
                    request.changeSessionId();
                    rotateCsrfToken(session);
                    session.setMaxInactiveInterval(30 * 60);
                    session.setAttribute("accessToken", result.accessToken);
                    session.setAttribute("userId",      result.userId);
                    session.setAttribute("userEmail",   result.email);
                    session.setAttribute("userName",    result.fullName != null ? result.fullName : result.email);
                    String role = "admin".equals(result.role) ? "admin" : "student";
                    session.setAttribute("userRole", role);
                    String dest = "admin".equals(role)
                            ? "/admin/dashboard" : "/student/dashboard";
                    response.sendRedirect(request.getContextPath() + dest);
                    return;
                }
                if (result.success) {
                    request.setAttribute("error",
                            "We couldn't verify this account. Please try again later.");
                    forwardForm(request, response, path);
                    return;
                }
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            request.setAttribute("error", result.message);
            forwardForm(request, response, path);

        } catch (SupabaseAuthService.SupabaseConfigurationException ex) {
            request.setAttribute("error",
                    "Authentication is not configured yet. Add the Supabase environment variables and restart Tomcat.");
            forwardForm(request, response, path);
        } catch (Exception ex) {
            getServletContext().log("QuizMaster authentication request failed.", ex);
            request.setAttribute("error",
                    "We couldn't complete that request. Check the configuration and try again.");
            forwardForm(request, response, path);
        }
    }

    private void forwardForm(HttpServletRequest request,
                             HttpServletResponse response, String path)
            throws ServletException, IOException {
        String view = "/WEB-INF/views/login.jsp";
        if ("/register".equals(path)) {
            view = "/WEB-INF/views/register.jsp";
        }
        request.getRequestDispatcher(view).forward(request, response);
    }

    private String clean(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String csrfToken(HttpSession session) {
        synchronized (session) {
            String token = (String) session.getAttribute("csrfToken");
            if (token != null) return token;
            return rotateCsrfToken(session);
        }
    }

    private String rotateCsrfToken(HttpSession session) {
        byte[] token = new byte[32];
        RANDOM.nextBytes(token);
        String value = HexFormat.of().formatHex(token);
        session.setAttribute("csrfToken", value);
        return value;
    }
}
