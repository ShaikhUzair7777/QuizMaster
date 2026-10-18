package com.quizmaster.model;

import java.time.Instant;

/** User profile (mirrors the Supabase profiles table). */
public class UserProfile {
    public String  id;            // UUID, same as auth.users.id
    public String  fullName;
    public String  email;
    public String  role;          // "student" or "admin"
    public Instant createdAt;
}
