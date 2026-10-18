package com.quizmaster.model;

/** A single answer stored for a quiz attempt. */
public class AttemptAnswer {
    public String attemptId;
    public String questionId;
    public String selectedOptionId;
    public boolean correct;
}
