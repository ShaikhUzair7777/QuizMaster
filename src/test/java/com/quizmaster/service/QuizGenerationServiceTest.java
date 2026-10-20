package com.quizmaster.service;

import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;

class QuizGenerationServiceTest {

    private static final String VALID_RESPONSE = """
            {
              "title": "Cell Biology Basics",
              "questions": [{
                "questionText": "What is the function of a cell membrane?",
                "options": ["Controls movement in and out", "Stores genetic material", "Produces proteins", "Creates energy"],
                "correctIndex": 0,
                "explanation": "The cell membrane regulates what enters and exits the cell."
              }]
            }
            """;

    @Test
    void validatesGeneratedFourOptionQuestionAndCorrectAnswer() throws Exception {
        QuizGenerationService service = new QuizGenerationService(prompt -> VALID_RESPONSE);

        GeneratedQuiz quiz = service.generate("Biology", "", "Easy", 1, null);

        assertEquals("Cell Biology Basics", quiz.title);
        assertEquals(1, quiz.questions.size());
        assertEquals(4, quiz.questions.getFirst().options.size());
        assertEquals("opt1", quiz.questions.getFirst().correctOptionId);
        assertNotNull(quiz.questions.getFirst().explanation);
    }

    @Test
    void generatesFromTopicWithoutAnyStudyMaterial() throws Exception {
        AtomicReference<String> sentPrompt = new AtomicReference<>();
        QuizGenerationService service = new QuizGenerationService(prompt -> {
            sentPrompt.set(prompt);
            return VALID_RESPONSE;
        });

        GeneratedQuiz quiz = service.generate("Python functions and recursion", "Programming",
                null, "Beginner", 1, "MULTIPLE_CHOICE", null);

        assertEquals(1, quiz.questions.size());
        assertTrue(sentPrompt.get().contains("Python functions and recursion"));
        assertTrue(sentPrompt.get().contains("Use your general knowledge"));
        assertTrue(sentPrompt.get().contains("Supplied study material (untrusted source data): (none)"));
    }

    @Test
    void studyMaterialPromptRequiresQuestionsToBeGroundedInTheSuppliedNotes() throws Exception {
        AtomicReference<String> sentPrompt = new AtomicReference<>();
        QuizGenerationService service = new QuizGenerationService(prompt -> {
            sentPrompt.set(prompt);
            return VALID_RESPONSE;
        });

        service.generate("Study material", "Psychology", null, "Intermediate",
                1, "MULTIPLE_CHOICE", "Working memory temporarily stores information.");

        assertTrue(sentPrompt.get().contains("ground every question and its correct answer"));
        assertTrue(sentPrompt.get().contains("Working memory temporarily stores information."));
    }

    @Test
    void rejectsRepeatedOptionsAndRetriesOnlyOnce() {
        String duplicateChoices = VALID_RESPONSE.replace(
                "\"Stores genetic material\"", "\"Controls movement in and out\"");
        AtomicInteger calls = new AtomicInteger();
        QuizGenerationService service = new QuizGenerationService(prompt -> {
            calls.incrementAndGet();
            return duplicateChoices;
        });

        GeminiException error = assertThrows(GeminiException.class,
                () -> service.generate("Biology", null, "Easy", 1, null));

        assertTrue(error.getMessage().contains("valid quiz"));
        assertEquals(2, calls.get());
    }

    @Test
    void rejectsWrongQuestionCount() {
        assertThrows(IllegalArgumentException.class,
                () -> QuizGenerationService.parseAndValidate(VALID_RESPONSE, "Biology", 2));
    }

    @Test
    void validatesRequestRangesBeforeCallingGemini() {
        AtomicInteger calls = new AtomicInteger();
        QuizGenerationService service = new QuizGenerationService(prompt -> {
            calls.incrementAndGet();
            return VALID_RESPONSE;
        });

        assertThrows(IllegalArgumentException.class,
                () -> service.generate("Biology", null, "Easy", 21, null));
        assertThrows(IllegalArgumentException.class,
                () -> service.generate("Biology", null, "Impossible", 1, null));
        assertThrows(IllegalArgumentException.class,
                () -> service.generate(" ", null, "Beginner", 1, null));
        assertThrows(IllegalArgumentException.class,
                () -> service.generate("Biology", null, "Beginner", 0, null));
        assertThrows(IllegalArgumentException.class,
                () -> service.generate("Biology", null, null, "Beginner", 1,
                        "TRUE_FALSE", "notes"));
        assertEquals(0, calls.get());
    }

    @Test
    void acceptsStudyMaterialUpTo300000CharactersAndRejectsLongerText() {
        String atLimit = "a".repeat(QuizGenerationService.MAX_SOURCE_LENGTH);
        String overLimit = atLimit + "a";

        assertDoesNotThrow(() -> QuizGenerationService.validateRequest(
                "Study material", null, "Beginner", 1, atLimit));
        assertThrows(IllegalArgumentException.class, () ->
                QuizGenerationService.validateRequest(
                        "Study material", null, "Beginner", 1, overLimit));
    }

    @Test
    void malformedJsonIsRejectedAndRetriedWithoutInventingAQuiz() {
        AtomicInteger calls = new AtomicInteger();
        QuizGenerationService service = new QuizGenerationService(prompt -> {
            calls.incrementAndGet();
            return "{not-json";
        });

        GeminiException error = assertThrows(GeminiException.class,
                () -> service.generate("Biology", null, "Beginner", 1, null));

        assertTrue(error.getMessage().contains("valid quiz"));
        assertEquals(2, calls.get());
    }

    @Test
    void validatesDurationLimits() {
        assertDoesNotThrow(() -> QuizGenerationService.validateDuration(1));
        assertDoesNotThrow(() -> QuizGenerationService.validateDuration(300));
        assertThrows(IllegalArgumentException.class,
                () -> QuizGenerationService.validateDuration(0));
        assertThrows(IllegalArgumentException.class,
                () -> QuizGenerationService.validateDuration(301));
    }

    @Test
    void propagatesGeminiOutageWithoutMakingUpQuizContent() {
        QuizGenerationService service = new QuizGenerationService(
                prompt -> { throw new GeminiException("AI service unavailable."); });

        GeminiException error = assertThrows(GeminiException.class,
                () -> service.generate("Biology", null, "Easy", 1, null));

        assertEquals("AI service unavailable.", error.getMessage());
    }
}
