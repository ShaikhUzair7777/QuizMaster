package com.quizmaster.service;

import com.quizmaster.model.Question;

import java.time.Instant;
import java.util.List;

/** Validated quiz draft retained on the server until the owner saves it. */
public final class GeneratedQuiz {
    public final String draftId;
    public final String title;
    public final String subject;
    public final List<Question> questions;
    public final Instant createdAt;

    public GeneratedQuiz(String draftId, String title, String subject,
                         List<Question> questions, Instant createdAt) {
        this.draftId = draftId;
        this.title = title;
        this.subject = subject;
        this.questions = List.copyOf(questions);
        this.createdAt = createdAt;
    }
}
