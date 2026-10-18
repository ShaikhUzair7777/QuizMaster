package com.quizmaster.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HexFormat;

/**
 * Protects all /student/* and /admin/* routes.
 * Unauthenticated requests are redirected to /login.
 * Admin routes additionally require role == "admin".
 */
@WebFilter(urlPatterns = {"/student/*", "/admin/*"})
public class AuthFilter implements Filter {

    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;

        HttpSession session     = request.getSession(false);
        String      accessToken = (session != null) ? (String) session.getAttribute("accessToken") : null;

        if (accessToken == null || accessToken.isBlank()) {
            String loginUrl = request.getContextPath() + "/login";
            if (isAjax(request)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"success\":false,\"error\":\"Session expired. Please sign in again.\"}");
            } else {
                response.sendRedirect(loginUrl);
            }
            return;
        }

        // Admin routes require the "admin" role stored in the session.
        String path = request.getServletPath();
        if (path.startsWith("/admin")) {
            String role = (String) session.getAttribute("userRole");
            if (!"admin".equals(role)) {
                if (isAjax(request)) {
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().write("{\"success\":false,\"error\":\"Access denied.\"}");
                } else {
                    response.sendRedirect(request.getContextPath() + "/student/dashboard");
                }
                return;
            }
        }

        String csrfToken;
        synchronized (session) {
            csrfToken = (String) session.getAttribute("csrfToken");
            if (csrfToken == null) {
                byte[] token = new byte[32];
                RANDOM.nextBytes(token);
                csrfToken = HexFormat.of().formatHex(token);
                session.setAttribute("csrfToken", csrfToken);
            }
        }
        response.setHeader("Cache-Control", "no-store");
        request.setAttribute("csrfToken", csrfToken);

        String method = request.getMethod();
        if ("POST".equals(method) || "PUT".equals(method)
                || "PATCH".equals(method) || "DELETE".equals(method)) {
            String supplied = request.getHeader("X-CSRF-Token");
            boolean multipart = request.getContentType() != null
                    && request.getContentType().toLowerCase(java.util.Locale.ROOT)
                    .startsWith("multipart/form-data");
            if (supplied == null && !multipart) supplied = request.getParameter("_csrf");
            if (supplied == null || !MessageDigest.isEqual(
                    csrfToken.getBytes(StandardCharsets.UTF_8),
                    supplied.getBytes(StandardCharsets.UTF_8))) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                if (isAjax(request)) {
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().write(
                            "{\"success\":false,\"error\":\"Request verification failed. Refresh and try again.\"}");
                } else {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "Request verification failed. Refresh and try again.");
                }
                return;
            }
        }

        chain.doFilter(req, res);
    }

    private boolean isAjax(HttpServletRequest request) {
        return "XMLHttpRequest".equals(request.getHeader("X-Requested-With"))
                || "application/json".equals(request.getHeader("Accept"));
    }
}
