package com.quizmaster.util;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class HtmlUtilsTest {

    @Test
    public void testEscapeNullAndEmpty() {
        assertEquals("", HtmlUtils.escape(null));
        assertEquals("", HtmlUtils.escape(""));
    }

    @Test
    public void testEscapeSpecialCharacters() {
        String input = "<script>alert('XSS & \"test\"')</script>";
        String expected = "&lt;script&gt;alert(&#x27;XSS &amp; &quot;test&quot;&#x27;)&lt;/script&gt;";
        assertEquals(expected, HtmlUtils.escape(input));
    }

    @Test
    public void testEscapeBr() {
        String input = "Line 1\nLine 2";
        String expected = "Line 1<br>Line 2";
        assertEquals(expected, HtmlUtils.escapeBr(input));
    }

    @Test
    public void testPlainStringUnmodified() {
        String input = "Hello World 123";
        assertEquals(input, HtmlUtils.escape(input));
    }
}
