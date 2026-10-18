-- Make a retried private-quiz save return its original quiz rather than creating a duplicate.
-- The request identifier is generated with each server-side session draft.

ALTER TABLE public.quizzes
    ADD COLUMN IF NOT EXISTS generation_request_id UUID;

CREATE UNIQUE INDEX IF NOT EXISTS idx_quizzes_generation_request_id
    ON public.quizzes (generation_request_id)
    WHERE generation_request_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.create_private_ai_quiz_idempotent(
    p_quiz JSONB,
    p_questions JSONB,
    p_request_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE
    saved_quiz public.quizzes%ROWTYPE;
    question_data JSONB;
    inserted_count INTEGER := 0;
BEGIN
    IF p_request_id IS NULL OR COALESCE(jsonb_typeof(p_quiz), '') <> 'object'
       OR p_quiz->>'created_by' IS NULL THEN
        RAISE EXCEPTION 'Invalid generated quiz request';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::TEXT, 0));
    SELECT * INTO saved_quiz
    FROM public.quizzes
    WHERE generation_request_id = p_request_id;

    IF FOUND THEN
        IF saved_quiz.created_by IS DISTINCT FROM (p_quiz->>'created_by')::UUID THEN
            RAISE EXCEPTION 'Generation request belongs to another user';
        END IF;
        RETURN to_jsonb(saved_quiz);
    END IF;

    IF COALESCE(jsonb_typeof(p_questions), '') <> 'array'
       OR jsonb_array_length(p_questions) < 1
       OR jsonb_array_length(p_questions) > 20
       OR p_quiz->>'title' IS NULL
       OR p_quiz->>'subject' IS NULL
       OR COALESCE((p_quiz->>'duration_minutes')::INTEGER, 0) NOT BETWEEN 1 AND 300 THEN
        RAISE EXCEPTION 'Invalid generated quiz details';
    END IF;

    INSERT INTO public.quizzes (
        title, description, subject, duration_minutes, question_count,
        published, max_attempts, pass_mark, created_by, generation_request_id
    ) VALUES (
        p_quiz->>'title',
        p_quiz->>'description',
        p_quiz->>'subject',
        (p_quiz->>'duration_minutes')::INTEGER,
        0,
        FALSE,
        1,
        COALESCE((p_quiz->>'pass_mark')::INTEGER, 50),
        (p_quiz->>'created_by')::UUID,
        p_request_id
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

    UPDATE public.quizzes
    SET question_count = inserted_count
    WHERE id = saved_quiz.id
    RETURNING * INTO saved_quiz;

    RETURN to_jsonb(saved_quiz);
END;
$$;

REVOKE ALL ON FUNCTION public.create_private_ai_quiz_idempotent(JSONB, JSONB, UUID)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_private_ai_quiz_idempotent(JSONB, JSONB, UUID)
    TO service_role;

NOTIFY pgrst, 'reload schema';
