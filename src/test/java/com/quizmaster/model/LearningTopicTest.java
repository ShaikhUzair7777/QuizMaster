package com.quizmaster.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class LearningTopicTest {

    @Test
    void filtersBySearchCategoryAndDifficulty() {
        LearningTopic topic = new LearningTopic();
        topic.title = "Python Functions & Recursion";
        topic.category = "Programming";
        topic.difficulty = "Intermediate";
        topic.description = "Practice base cases and recursive calls.";

        assertTrue(topic.matches("recursive calls", "", ""));
        assertTrue(topic.matches("python", "Programming", "Intermediate"));
        assertFalse(topic.matches("python", "Psychology", ""));
        assertFalse(topic.matches("", "", "Beginner"));
    }
}
