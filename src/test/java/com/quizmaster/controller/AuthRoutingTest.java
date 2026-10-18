package com.quizmaster.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.Test;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import java.nio.file.Files;
import java.io.InputStream;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuthRoutingTest {

    @Test
    void loginAndRegistrationAreExplicitlyMappedToPostCapableServlet() throws Exception {
        var factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
        factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
        org.w3c.dom.Document document;
        try (InputStream input = Files.newInputStream(
                Path.of("src", "main", "webapp", "WEB-INF", "web.xml"))) {
            document = factory.newDocumentBuilder().parse(input);
        }

        var mappings = document.getElementsByTagNameNS(
                "https://jakarta.ee/xml/ns/jakartaee", "servlet-mapping");
        Set<String> authPaths = new HashSet<>();
        for (int i = 0; i < mappings.getLength(); i++) {
            var mapping = (org.w3c.dom.Element) mappings.item(i);
            var name = mapping.getElementsByTagNameNS(
                    "https://jakarta.ee/xml/ns/jakartaee", "servlet-name").item(0);
            if (name != null && "authPage".equals(name.getTextContent())) {
                var patterns = mapping.getElementsByTagNameNS(
                        "https://jakarta.ee/xml/ns/jakartaee", "url-pattern");
                for (int j = 0; j < patterns.getLength(); j++) {
                    authPaths.add(patterns.item(j).getTextContent());
                }
            }
        }

        assertEquals(Set.of("/login", "/register", "/logout"), authPaths);
        assertNotNull(AuthPageServlet.class.getDeclaredMethod(
                "doGet", HttpServletRequest.class, HttpServletResponse.class));
        assertNotNull(AuthPageServlet.class.getDeclaredMethod(
                "doPost", HttpServletRequest.class, HttpServletResponse.class));
    }

    @Test
    void loginAndRegistrationFormsUseContextRelativePostActions() throws Exception {
        String login = Files.readString(Path.of(
                "src", "main", "webapp", "WEB-INF", "views", "login.jsp"));
        String register = Files.readString(Path.of(
                "src", "main", "webapp", "WEB-INF", "views", "register.jsp"));

        assertTrue(login.contains(
                "method=\"post\" action=\"${pageContext.request.contextPath}/login\""));
        assertTrue(register.contains(
                "method=\"post\" action=\"${pageContext.request.contextPath}/register\""));
    }
}
