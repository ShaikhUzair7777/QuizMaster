package com.quizmaster.model;

import java.time.Instant;

/** Represents a quiz record from the database. */
public class Quiz {
    public String  id;
    public String  title;
    public String  description;
    public String  subject;
    public int     durationMinutes;
    public int     questionCount;
    public boolean published;
    public int     maxAttempts;
    public String  createdBy;
    public Instant createdAt;
    public Instant availableFrom;
    public Instant availableUntil;
    public int     passMark;         // percentage, 0 = no pass threshold
}
