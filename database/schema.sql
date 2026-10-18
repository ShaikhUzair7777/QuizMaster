-- =============================================================================
-- QuizMaster — Supabase & PostgreSQL Database Schema and Seed Data
-- =============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Quizzes Table
CREATE TABLE IF NOT EXISTS public.quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    subject VARCHAR(100) NOT NULL DEFAULT 'General',
    duration_minutes INTEGER NOT NULL DEFAULT 30,
    question_count INTEGER NOT NULL DEFAULT 0,
    published BOOLEAN NOT NULL DEFAULT false,
    max_attempts INTEGER NOT NULL DEFAULT 1,
    pass_mark INTEGER NOT NULL DEFAULT 50,
    created_by UUID,
    available_from TIMESTAMPTZ,
    available_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Questions Table
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL DEFAULT '[]'::jsonb,
    correct_option_id VARCHAR(100),
    explanation TEXT,
    order_index INTEGER NOT NULL DEFAULT 0,
    marks INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Quiz Attempts Table
CREATE TABLE IF NOT EXISTS public.quiz_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'in_progress', -- 'in_progress', 'submitted', 'expired'
    score INTEGER NOT NULL DEFAULT 0,
    total_questions INTEGER NOT NULL DEFAULT 0,
    marks_obtained INTEGER NOT NULL DEFAULT 0,
    total_marks INTEGER NOT NULL DEFAULT 0,
    percentage NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    passed BOOLEAN NOT NULL DEFAULT false,
    deadline TIMESTAMPTZ,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at TIMESTAMPTZ
);

-- 5. Attempt Answers Table
CREATE TABLE IF NOT EXISTS public.attempt_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attempt_id UUID NOT NULL REFERENCES public.quiz_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    selected_option_id VARCHAR(100),
    correct BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(attempt_id, question_id)
);

-- 6. User Profiles Table (Linked with Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'student', -- 'student', 'admin'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Roles are stored outside user-editable auth metadata and default to student.
CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, full_name, role)
    VALUES (
        NEW.id,
        NULLIF(BTRIM(NEW.raw_user_meta_data ->> 'full_name'), ''),
        'student'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, auth;

DROP TRIGGER IF EXISTS trg_create_user_profile ON auth.users;
CREATE TRIGGER trg_create_user_profile
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.create_user_profile();

-- Backfill profiles for accounts created before this trigger was installed.
INSERT INTO public.user_profiles (id, full_name, role)
SELECT id, NULLIF(BTRIM(raw_user_meta_data ->> 'full_name'), ''), 'student'
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_quizzes_published ON public.quizzes(published, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_questions_quiz_id ON public.questions(quiz_id, order_index ASC);
CREATE INDEX IF NOT EXISTS idx_attempts_user_id ON public.quiz_attempts(user_id, status);
CREATE INDEX IF NOT EXISTS idx_attempts_quiz_user ON public.quiz_attempts(quiz_id, user_id);
CREATE INDEX IF NOT EXISTS idx_answers_attempt_id ON public.attempt_answers(attempt_id);

-- Automatic question_count update trigger
CREATE OR REPLACE FUNCTION update_quiz_question_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.quizzes SET question_count = question_count + 1 WHERE id = NEW.quiz_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.quizzes SET question_count = GREATEST(question_count - 1, 0) WHERE id = OLD.quiz_id;
    ELSIF OLD.quiz_id IS DISTINCT FROM NEW.quiz_id THEN
        UPDATE public.quizzes SET question_count = GREATEST(question_count - 1, 0) WHERE id = OLD.quiz_id;
        UPDATE public.quizzes SET question_count = question_count + 1 WHERE id = NEW.quiz_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_quiz_question_count ON public.questions;
CREATE TRIGGER trg_quiz_question_count
AFTER INSERT OR UPDATE OR DELETE ON public.questions
FOR EACH ROW EXECUTE FUNCTION update_quiz_question_count();

-- Row Level Security (RLS)
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Allow read of published quizzes to anyone authenticated / anon
CREATE POLICY "Public read published quizzes" ON public.quizzes
    FOR SELECT USING (published = true OR auth.role() = 'service_role');

-- Service role has full access to all tables
CREATE POLICY "Service role full access quizzes" ON public.quizzes
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access questions" ON public.questions
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access attempts" ON public.quiz_attempts
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access answers" ON public.attempt_answers
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access profiles" ON public.user_profiles
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- SEED DATA: Sample Quizzes & Comprehensive Questions
-- =============================================================================

DO $$
DECLARE
    q1_id UUID := '11111111-1111-1111-1111-111111111111';
    q2_id UUID := '22222222-2222-2222-2222-222222222222';
    q3_id UUID := '33333333-3333-3333-3333-333333333333';
BEGIN
    -- Quiz 1: Java Enterprise & Servlet Fundamentals
    INSERT INTO public.quizzes (id, title, description, subject, duration_minutes, question_count, published, max_attempts, pass_mark)
    VALUES (
        q1_id,
        'Java Enterprise & Jakarta Servlets',
        'Test your mastery of Jakarta EE Servlet 6.0 lifecycle, HTTP filters, session state, and MVC architecture.',
        'Java Development',
        20,
        5,
        true,
        3,
        60
    ) ON CONFLICT (id) DO NOTHING;

    -- Quiz 2: Modern Web Architecture & Security
    INSERT INTO public.quizzes (id, title, description, subject, duration_minutes, question_count, published, max_attempts, pass_mark)
    VALUES (
        q2_id,
        'Web Application Security & OWASP Top 10',
        'Assess your comprehension of CSRF defense, XSS mitigation, secure cookies, and cryptographic token verification.',
        'Cybersecurity',
        15,
        5,
        true,
        3,
        70
    ) ON CONFLICT (id) DO NOTHING;

    -- Quiz 3: Relational Database & SQL Design
    INSERT INTO public.quizzes (id, title, description, subject, duration_minutes, question_count, published, max_attempts, pass_mark)
    VALUES (
        q3_id,
        'Relational Databases & SQL Optimization',
        'Key principles of ACID transactions, indexing strategies, normalization, and PostgREST API design.',
        'Database Systems',
        25,
        5,
        true,
        2,
        60
    ) ON CONFLICT (id) DO NOTHING;

    -- Questions for Quiz 1: Java Enterprise
    INSERT INTO public.questions (quiz_id, question_text, options, correct_option_id, order_index, marks)
    VALUES 
    (
        q1_id,
        'What is the correct lifecycle invocation order of a Jakarta HttpServlet when handling an HTTP request for the first time?',
        '[{"id": "opt1", "text": "init() -> service() -> doGet()/doPost()"}, {"id": "opt2", "text": "service() -> init() -> destroy()"}, {"id": "opt3", "text": "constructor -> doGet() -> service()"}, {"id": "opt4", "text": "init() -> destroy() -> service()"}]'::jsonb,
        'opt1',
        1,
        2
    ),
    (
        q1_id,
        'Which HTTP response header is crucial for preventing cross-site framing and clickjacking attacks in a web application?',
        '[{"id": "opt1", "text": "X-Frame-Options: DENY"}, {"id": "opt2", "text": "Accept-Encoding: gzip"}, {"id": "opt3", "text": "Cache-Control: no-cache"}, {"id": "opt4", "text": "Access-Control-Allow-Origin: *"}]'::jsonb,
        'opt1',
        2,
        2
    ),
    (
        q1_id,
        'How does request.getRequestDispatcher("/path").forward(req, res) differ from response.sendRedirect("/path")?',
        '[{"id": "opt1", "text": "forward() is executed server-side without changing browser URL; sendRedirect() sends an HTTP 302 to client"}, {"id": "opt2", "text": "forward() sends an HTTP 301 permanently; sendRedirect() executes on server"}, {"id": "opt3", "text": "There is no difference; they are exact aliases"}, {"id": "opt4", "text": "forward() invalidates the session; sendRedirect() preserves it"}]'::jsonb,
        'opt1',
        3,
        2
    ),
    (
        q1_id,
        'What is the primary purpose of a servlet Filter implementing jakarta.servlet.Filter?',
        '[{"id": "opt1", "text": "To intercept and transform requests and responses before and after reaching the servlet"}, {"id": "opt2", "text": "To compile JSP files into bytecode on server startup"}, {"id": "opt3", "text": "To directly manage database JDBC connection pools"}, {"id": "opt4", "text": "To render HTML layouts in place of JSP"}]'::jsonb,
        'opt1',
        4,
        2
    ),
    (
        q1_id,
        'In Jakarta EE, which session method should be called to properly clear authentication tokens during user logout?',
        '[{"id": "opt1", "text": "session.invalidate()"}, {"id": "opt2", "text": "session.close()"}, {"id": "opt3", "text": "session.destroy()"}, {"id": "opt4", "text": "session.flush()"}]'::jsonb,
        'opt1',
        5,
        2
    ) ON CONFLICT DO NOTHING;

    -- Questions for Quiz 2: Web Security
    INSERT INTO public.questions (quiz_id, question_text, options, correct_option_id, order_index, marks)
    VALUES 
    (
        q2_id,
        'Which mechanism best prevents Cross-Site Request Forgery (CSRF) in state-changing POST requests?',
        '[{"id": "opt1", "text": "Synchronizer token pattern (cryptographically secure unpredictable token validated per session)"}, {"id": "opt2", "text": "Using HTTP Basic Authentication"}, {"id": "opt3", "text": "Setting server port to 443 only"}, {"id": "opt4", "text": "Checking the User-Agent header"}]'::jsonb,
        'opt1',
        1,
        2
    ),
    (
        q2_id,
        'What flags should be set on a session cookie in production to maximize security?',
        '[{"id": "opt1", "text": "HttpOnly, Secure, and SameSite=Strict (or Lax)"}, {"id": "opt2", "text": "Domain=* and MaxAge=0"}, {"id": "opt3", "text": "No flags are necessary"}, {"id": "opt4", "text": "Access-Control-Allow-Credentials=true only"}]'::jsonb,
        'opt1',
        2,
        2
    ),
    (
        q2_id,
        'Which type of Cross-Site Scripting (XSS) occurs when malicious JavaScript is permanently stored in the target database and rendered to other users?',
        '[{"id": "opt1", "text": "Stored (Persistent) XSS"}, {"id": "opt2", "text": "Reflected (Non-persistent) XSS"}, {"id": "opt3", "text": "DOM-based XSS"}, {"id": "opt4", "text": "Blind SQL Injection"}]'::jsonb,
        'opt1',
        3,
        2
    ),
    (
        q2_id,
        'Why should password hashes never be stored using simple MD5 or SHA-256 without a salted adaptive function?',
        '[{"id": "opt1", "text": "Fast hash algorithms are susceptible to rapid GPU-accelerated brute-force and rainbow table lookups"}, {"id": "opt2", "text": "MD5 output is too large to fit in a VARCHAR column"}, {"id": "opt3", "text": "SHA-256 cannot hash UTF-8 characters"}, {"id": "opt4", "text": "Modern browsers block HTTP responses containing SHA hashes"}]'::jsonb,
        'opt1',
        4,
        2
    ),
    (
        q2_id,
        'What does the Content-Security-Policy (CSP) header directive "default-src ''self''" accomplish?',
        '[{"id": "opt1", "text": "Restricts loading all subresources (scripts, images, styles) to the application origin by default"}, {"id": "opt2", "text": "Allows all external CDNs automatically"}, {"id": "opt3", "text": "Forces the browser to reload the page every second"}, {"id": "opt4", "text": "Enables cross-origin framing from any website"}]'::jsonb,
        'opt1',
        5,
        2
    ) ON CONFLICT DO NOTHING;

    -- Questions for Quiz 3: Database & SQL
    INSERT INTO public.questions (quiz_id, question_text, options, correct_option_id, order_index, marks)
    VALUES 
    (
        q3_id,
        'Which ACID property ensures that once a database transaction is committed, its changes survive system crashes or power failures?',
        '[{"id": "opt1", "text": "Durability"}, {"id": "opt2", "text": "Atomicity"}, {"id": "opt3", "text": "Consistency"}, {"id": "opt4", "text": "Isolation"}]'::jsonb,
        'opt1',
        1,
        2
    ),
    (
        q3_id,
        'When should a B-Tree composite index on columns (A, B) typically be used over two separate indexes on A and B?',
        '[{"id": "opt1", "text": "When frequent queries filter by both A and B in their WHERE clause together"}, {"id": "opt2", "text": "Only when column A contains exclusively NULL values"}, {"id": "opt3", "text": "Composite indexes should never be used in relational databases"}, {"id": "opt4", "text": "When table size is under 10 rows"}]'::jsonb,
        'opt1',
        2,
        2
    ),
    (
        q3_id,
        'What is the primary purpose of Third Normal Form (3NF) in relational database design?',
        '[{"id": "opt1", "text": "Eliminate transitive dependencies of non-key attributes on the primary key"}, {"id": "opt2", "text": "Ensure table contains at least 3 foreign keys"}, {"id": "opt3", "text": "Allow duplicate rows without a primary key"}, {"id": "opt4", "text": "Convert all integers to floating point numbers"}]'::jsonb,
        'opt1',
        3,
        2
    ),
    (
        q3_id,
        'What does PostgREST use to determine client access permissions when executing SQL queries?',
        '[{"id": "opt1", "text": "PostgreSQL Row Level Security (RLS) policies and the executing role derived from the JWT"}, {"id": "opt2", "text": "Static XML configuration files in Apache Tomcat"}, {"id": "opt3", "text": "Client-side cookies stored in local storage"}, {"id": "opt4", "text": "Hardcoded plain-text passwords in HTTP headers"}]'::jsonb,
        'opt1',
        4,
        2
    ),
    (
        q3_id,
        'In SQL, which clause is used to filter aggregated group results produced by GROUP BY?',
        '[{"id": "opt1", "text": "HAVING"}, {"id": "opt2", "text": "WHERE"}, {"id": "opt3", "text": "ORDER BY"}, {"id": "opt4", "text": "LIMIT"}]'::jsonb,
        'opt1',
        5,
        2
    ) ON CONFLICT DO NOTHING;

    -- Update question_count for each quiz based on inserted questions
    UPDATE public.quizzes q
    SET question_count = (SELECT COUNT(*) FROM public.questions WHERE quiz_id = q.id);
END $$;
