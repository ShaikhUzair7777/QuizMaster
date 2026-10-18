-- AI quiz generation support.
-- Apply once in the Supabase SQL editor. This does not modify or publish existing quizzes.

ALTER TABLE public.questions
    ADD COLUMN IF NOT EXISTS explanation TEXT;

UPDATE public.quizzes q
SET question_count = (
    SELECT COUNT(*)
    FROM public.questions question
    WHERE question.quiz_id = q.id
)
WHERE question_count IS DISTINCT FROM (
    SELECT COUNT(*)
    FROM public.questions question
    WHERE question.quiz_id = q.id
);

CREATE OR REPLACE FUNCTION public.update_quiz_question_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.quizzes
        SET question_count = question_count + 1
        WHERE id = NEW.quiz_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.quizzes
        SET question_count = GREATEST(question_count - 1, 0)
        WHERE id = OLD.quiz_id;
    ELSIF OLD.quiz_id IS DISTINCT FROM NEW.quiz_id THEN
        UPDATE public.quizzes
        SET question_count = GREATEST(question_count - 1, 0)
        WHERE id = OLD.quiz_id;
        UPDATE public.quizzes
        SET question_count = question_count + 1
        WHERE id = NEW.quiz_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_quiz_question_count ON public.questions;
CREATE TRIGGER trg_quiz_question_count
AFTER INSERT OR UPDATE OR DELETE ON public.questions
FOR EACH ROW EXECUTE FUNCTION public.update_quiz_question_count();

CREATE OR REPLACE FUNCTION public.create_private_ai_quiz(p_quiz JSONB, p_questions JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE
    saved_quiz public.quizzes%ROWTYPE;
    question_data JSONB;
    inserted_count INTEGER := 0;
BEGIN
    IF jsonb_typeof(p_quiz) <> 'object'
       OR jsonb_typeof(p_questions) <> 'array'
       OR jsonb_array_length(p_questions) < 1
       OR jsonb_array_length(p_questions) > 20 THEN
        RAISE EXCEPTION 'Invalid generated quiz payload';
    END IF;

    IF p_quiz->>'created_by' IS NULL
       OR p_quiz->>'title' IS NULL
       OR p_quiz->>'subject' IS NULL
       OR COALESCE((p_quiz->>'duration_minutes')::INTEGER, 0) NOT BETWEEN 1 AND 300 THEN
        RAISE EXCEPTION 'Invalid generated quiz details';
    END IF;

    INSERT INTO public.quizzes (
        title, description, subject, duration_minutes, question_count,
        published, max_attempts, pass_mark, created_by
    ) VALUES (
        p_quiz->>'title',
        p_quiz->>'description',
        p_quiz->>'subject',
        (p_quiz->>'duration_minutes')::INTEGER,
        0,
        FALSE,
        1,
        COALESCE((p_quiz->>'pass_mark')::INTEGER, 50),
        (p_quiz->>'created_by')::UUID
    )
    RETURNING * INTO saved_quiz;

    FOR question_data IN SELECT value FROM jsonb_array_elements(p_questions)
    LOOP
        IF jsonb_typeof(question_data) <> 'object'
           OR jsonb_typeof(question_data->'options') <> 'array'
           OR jsonb_array_length(question_data->'options') <> 4
           OR question_data->>'question_text' IS NULL
           OR question_data->>'correct_option_id' IS NULL THEN
            RAISE EXCEPTION 'Invalid generated question payload';
        END IF;

        INSERT INTO public.questions (
            quiz_id, question_text, options, correct_option_id,
            order_index, marks, explanation
        ) VALUES (
            saved_quiz.id,
            question_data->>'question_text',
            question_data->'options',
            question_data->>'correct_option_id',
            (question_data->>'order_index')::INTEGER,
            (question_data->>'marks')::INTEGER,
            question_data->>'explanation'
        );
        inserted_count := inserted_count + 1;
    END LOOP;

    IF inserted_count <> jsonb_array_length(p_questions) THEN
        RAISE EXCEPTION 'Not all generated questions were saved';
    END IF;

    UPDATE public.quizzes
    SET question_count = inserted_count
    WHERE id = saved_quiz.id
    RETURNING * INTO saved_quiz;

    RETURN to_jsonb(saved_quiz);
END;
$$;

REVOKE ALL ON FUNCTION public.create_private_ai_quiz(JSONB, JSONB)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_private_ai_quiz(JSONB, JSONB)
    TO service_role;

NOTIFY pgrst, 'reload schema';
