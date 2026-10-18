package com.quizmaster.model;

import java.util.List;

/** Represents a question belonging to a quiz. */
public class Question {
    public String       id;
    public String       quizId;
    public String       questionText;
    public List<Option> options;
    public int          orderIndex;
    /** Correct option ID — never sent to the student before submission. */
    public String       correctOptionId;
    public int          marks;
    /** Explanation is withheld from the active exam payload. */
    public String       explanation;

    public static class Option {
        public String id;
        public String text;
    }
}
