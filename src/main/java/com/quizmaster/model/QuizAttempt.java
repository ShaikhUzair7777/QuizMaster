package com.quizmaster.model;

import java.time.Instant;

/** Represents a student quiz attempt. */
public class QuizAttempt {
    public String  id;
    public String  quizId;
    public String  userId;
    public Instant startedAt;
    public Instant submittedAt;
    public Instant deadline;
    public String  status;        // "in_progress", "submitted", "expired"
    public int     score;         // correct answers
    public int     totalQuestions;
    public int     totalMarks;
    public int     marksObtained;
    public double  percentage;
    public boolean passed;
}
