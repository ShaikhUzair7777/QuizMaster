package com.quizmaster.model;

import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.ArrayList;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;

public class ModelTest {

    @Test
    public void testQuizModel() {
        Quiz q = new Quiz();
        q.id = UUID.randomUUID().toString();
        q.title = "Jakarta Enterprise Architecture";
        q.subject = "Java";
        q.durationMinutes = 45;
        q.passMark = 75;
        q.published = true;
        q.maxAttempts = 3;

        assertEquals("Jakarta Enterprise Architecture", q.title);
        assertEquals(45, q.durationMinutes);
        assertEquals(75, q.passMark);
        assertTrue(q.published);
        assertEquals(3, q.maxAttempts);
    }

    @Test
    public void testQuestionAndOptions() {
        Question q = new Question();
        q.id = "q-1";
        q.quizId = "quiz-1";
        q.questionText = "What is the role of a Filter?";
        q.marks = 2;
        q.orderIndex = 1;
        q.correctOptionId = "opt-1";
        q.options = new ArrayList<>();

        Question.Option opt1 = new Question.Option();
        opt1.id = "opt-1";
        opt1.text = "Intercept request and response";
        q.options.add(opt1);

        Question.Option opt2 = new Question.Option();
        opt2.id = "opt-2";
        opt2.text = "Render JSP pages";
        q.options.add(opt2);

        assertEquals(2, q.options.size());
        assertEquals("opt-1", q.correctOptionId);
        assertEquals("Intercept request and response", q.options.get(0).text);
    }

    @Test
    public void testQuizAttemptCalculations() {
        QuizAttempt a = new QuizAttempt();
        a.id = "att-1";
        a.score = 4;
        a.totalQuestions = 5;
        a.percentage = (4.0 / 5.0) * 100.0;
        a.passed = a.percentage >= 60.0;
        a.startedAt = Instant.now();

        assertEquals(80.0, a.percentage, 0.001);
        assertTrue(a.passed);
        assertNotNull(a.startedAt);
    }
}
