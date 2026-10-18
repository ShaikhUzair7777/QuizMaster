package com.quizmaster.util;

/**
 * HTML output-encoding utilities to prevent XSS.
 * Use these whenever rendering untrusted text into HTML.
 */
public final class HtmlUtils {

    private HtmlUtils() {}

    /** Escapes characters that have special meaning in HTML. */
    public static String escape(String value) {
        if (value == null) return "";
        return value
                .replace("&",  "&amp;")
                .replace("<",  "&lt;")
                .replace(">",  "&gt;")
                .replace("\"", "&quot;")
                .replace("'",  "&#x27;");
    }

    /** Same as escape() but also replaces newlines with <br>. */
    public static String escapeBr(String value) {
        return escape(value).replace("\n", "<br>");
    }
}
