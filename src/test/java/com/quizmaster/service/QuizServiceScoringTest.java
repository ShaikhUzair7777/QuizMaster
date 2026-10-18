package com.quizmaster.service;

import com.quizmaster.model.AttemptAnswer;
import com.quizmaster.model.Question;
import com.quizmaster.model.Quiz;
import com.quizmaster.model.QuizAttempt;
import com.quizmaster.repository.AttemptRepository;
import com.quizmaster.repository.QuizRepository;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class QuizServiceScoringTest {

    @Test
    void scoresFromSavedAnswersAndPersistsWeightedResultForHistory() throws Exception {
        String quizId = UUID.randomUUID().toString();
        String attemptId = UUID.randomUUID().toString();
        Quiz quiz = new Quiz();
        quiz.id = quizId;
        quiz.passMark = 70;

        Question first = question(quizId, 1, 2, "a");
        Question second = question(quizId, 2, 1, "b");
        Question third = question(quizId, 3, 1, "c");
        QuizRepository quizzes = new QuizRepository(null) {
            @Override
            public List<Question> findQuestionsWithAnswers(String id) {
                return List.of(first, second, third);
            }
        };

        QuizAttempt attempt = new QuizAttempt();
        attempt.id = attemptId;
        attempt.quizId = quizId;
        attempt.status = "in_progress";
        int[][] persisted = new int[1][4];
        boolean[] persistedPass = new boolean[1];
        AttemptRepository attempts = new AttemptRepository(null) {
            @Override
            public QuizAttempt findById(String id) {
                return attempt;
            }

            @Override
            public List<AttemptAnswer> findAnswers(String id) {
                return List.of(
                        answer(attemptId, first.id, "a"),
                        answer(attemptId, second.id, "wrong"),
                        answer(attemptId, third.id, "c"));
            }

            @Override
            public void submit(String id, int score, int totalQuestions, int marksObtained,
                               int totalMarks, double percentage, boolean passed) {
                persisted[0] = new int[]{score, totalQuestions, marksObtained, totalMarks};
                persistedPass[0] = passed;
            }
        };

        QuizAttempt result = new QuizService(quizzes, attempts)
                .scoreAndSubmit(attemptId, quizId, quiz);

        assertEquals("submitted", result.status);
        assertEquals(2, result.score);
        assertEquals(3, result.totalQuestions);
        assertEquals(3, result.marksObtained);
        assertEquals(4, result.totalMarks);
        assertEquals(75.0, result.percentage);
        assertTrue(result.passed);
        assertArrayEquals(new int[]{2, 3, 3, 4}, persisted[0]);
        assertTrue(persistedPass[0]);
    }

    private static Question question(String quizId, int order, int marks, String correctOptionId) {
        Question question = new Question();
        question.id = UUID.randomUUID().toString();
        question.quizId = quizId;
        question.orderIndex = order;
        question.marks = marks;
        question.correctOptionId = correctOptionId;
        return question;
    }

    private static AttemptAnswer answer(String attemptId, String questionId, String optionId) {
        AttemptAnswer answer = new AttemptAnswer();
        answer.attemptId = attemptId;
        answer.questionId = questionId;
        answer.selectedOptionId = optionId;
        return answer;
    }
}
