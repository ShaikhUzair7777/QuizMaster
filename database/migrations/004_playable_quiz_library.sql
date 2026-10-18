-- Add a repeatable library of real, playable quizzes without changing existing records.
-- Apply after schema.sql and migrations 001-003 in the Supabase SQL Editor.

BEGIN;

-- Keep this seed safe to run on installations where migration 001 was skipped.
ALTER TABLE public.questions
    ADD COLUMN IF NOT EXISTS explanation TEXT;

INSERT INTO public.quizzes (
    id, title, description, subject, duration_minutes, question_count,
    published, max_attempts, pass_mark, created_by
) VALUES
    ('44444444-4444-4444-8444-444444444401', 'Python Fundamentals: Core Concepts',
     'Practice variables, types, control flow, collections, and common Python behavior.',
     'Programming', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444402', 'Python Functions and Recursion',
     'Review function arguments, return values, scope, recursion, and base cases.',
     'Programming', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444403', 'Java OOP and Polymorphism',
     'Test Java knowledge of classes, inheritance, interfaces, overriding, and polymorphism.',
     'Programming', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444404', 'SQL Joins and Grouping',
     'Practice relational joins, aggregate functions, grouping, and filtering grouped results.',
     'Programming', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444405', 'Data Structures and Complexity',
     'Explore common data structures, algorithmic complexity, and appropriate use cases.',
     'Programming', 15, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444406', 'Psychology: Memory and Attention',
     'Check your understanding of working memory, encoding, retrieval, and selective attention.',
     'Psychology', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444407', 'Developmental Psychology: Attachment',
     'Review attachment theory, caregiver sensitivity, and patterns of early relationships.',
     'Psychology', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444408', 'Social Psychology: Groups and Influence',
     'Practice concepts in conformity, social influence, attribution, and group behavior.',
     'Psychology', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444409', 'Psychological Research Methods',
     'Assess research design, variables, sampling, reliability, and ethical practice.',
     'Psychology', 15, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444410', 'Machine Learning: Classification',
     'Review classification tasks, evaluation metrics, overfitting, and data preparation.',
     'AI and Data Science', 15, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444411', 'Generative AI and Prompting',
     'Understand generative models, prompts, grounding, and responsible use of AI outputs.',
     'AI and Data Science', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444412', 'Computer Networks: HTTP and TCP/IP',
     'Test foundational knowledge of transport, addressing, HTTP, and client-server networks.',
     'Computer Science and IT', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444413', 'Operating Systems Fundamentals',
     'Practice process scheduling, memory management, concurrency, and operating-system roles.',
     'Computer Science and IT', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444414', 'Cybersecurity Fundamentals',
     'Review authentication, least privilege, encryption, and common web security defenses.',
     'Computer Science and IT', 12, 0, TRUE, 3, 60, NULL),
    ('44444444-4444-4444-8444-444444444415', 'Logical Reasoning and Quantitative Aptitude',
     'Practice numerical reasoning, ratios, sequences, and basic logical inference.',
     'Mathematics and Reasoning', 12, 0, TRUE, 3, 60, NULL)
ON CONFLICT (id) DO NOTHING;

WITH seed_questions (
    quiz_id, quiz_title, order_index, question_text, options, correct_option_id, explanation
) AS (
    VALUES
    ('44444444-4444-4444-8444-444444444401'::uuid, 'Python Fundamentals: Core Concepts', 1,
     'Which Python type is immutable?', '[{"id":"opt1","text":"List"},{"id":"opt2","text":"Dictionary"},{"id":"opt3","text":"Tuple"},{"id":"opt4","text":"Set"}]'::jsonb, 'opt3',
     'A tuple cannot be changed after it is created, unlike lists, dictionaries, and sets.'),
    ('44444444-4444-4444-8444-444444444401'::uuid, 'Python Fundamentals: Core Concepts', 2,
     'What does range(2, 5) produce when iterated?', '[{"id":"opt1","text":"2, 3, 4"},{"id":"opt2","text":"2, 3, 4, 5"},{"id":"opt3","text":"1, 2, 3, 4"},{"id":"opt4","text":"3, 4, 5"}]'::jsonb, 'opt1',
     'The stop value is exclusive, so the sequence contains 2, 3, and 4.'),
    ('44444444-4444-4444-8444-444444444401'::uuid, 'Python Fundamentals: Core Concepts', 3,
     'Which keyword begins a conditional branch in Python?', '[{"id":"opt1","text":"when"},{"id":"opt2","text":"if"},{"id":"opt3","text":"case"},{"id":"opt4","text":"check"}]'::jsonb, 'opt2',
     'Python uses if to start a conditional branch.'),

    ('44444444-4444-4444-8444-444444444402'::uuid, 'Python Functions and Recursion', 1,
     'What is the purpose of a base case in a recursive function?', '[{"id":"opt1","text":"To stop recursive calls"},{"id":"opt2","text":"To speed up imports"},{"id":"opt3","text":"To create a global variable"},{"id":"opt4","text":"To repeat the first call"}]'::jsonb, 'opt1',
     'A base case terminates recursion so calls do not continue indefinitely.'),
    ('44444444-4444-4444-8444-444444444402'::uuid, 'Python Functions and Recursion', 2,
     'What does a Python function return if it reaches its end without a return statement?', '[{"id":"opt1","text":"0"},{"id":"opt2","text":"False"},{"id":"opt3","text":"None"},{"id":"opt4","text":"An empty string"}]'::jsonb, 'opt3',
     'Python implicitly returns None when no return value is specified.'),
    ('44444444-4444-4444-8444-444444444402'::uuid, 'Python Functions and Recursion', 3,
     'Which syntax collects extra positional arguments into a tuple?', '[{"id":"opt1","text":"**args"},{"id":"opt2","text":"*args"},{"id":"opt3","text":"&args"},{"id":"opt4","text":"...args"}]'::jsonb, 'opt2',
     'A parameter prefixed with one asterisk collects extra positional arguments as a tuple.'),

    ('44444444-4444-4444-8444-444444444403'::uuid, 'Java OOP and Polymorphism', 1,
     'Which keyword declares that a Java class implements an interface?', '[{"id":"opt1","text":"extends"},{"id":"opt2","text":"implements"},{"id":"opt3","text":"inherits"},{"id":"opt4","text":"interface"}]'::jsonb, 'opt2',
     'A class uses implements to provide an interface implementation.'),
    ('44444444-4444-4444-8444-444444444403'::uuid, 'Java OOP and Polymorphism', 2,
     'What enables runtime method dispatch for an overridden instance method?', '[{"id":"opt1","text":"Dynamic polymorphism"},{"id":"opt2","text":"Method overloading only"},{"id":"opt3","text":"Static import"},{"id":"opt4","text":"A final class"}]'::jsonb, 'opt1',
     'Overridden instance methods are selected according to the runtime object type.'),
    ('44444444-4444-4444-8444-444444444403'::uuid, 'Java OOP and Polymorphism', 3,
     'Which access modifier restricts a member to its declaring class?', '[{"id":"opt1","text":"public"},{"id":"opt2","text":"protected"},{"id":"opt3","text":"private"},{"id":"opt4","text":"default"}]'::jsonb, 'opt3',
     'A private member is accessible only within its declaring class.'),

    ('44444444-4444-4444-8444-444444444404'::uuid, 'SQL Joins and Grouping', 1,
     'Which join returns only rows with matching values in both tables?', '[{"id":"opt1","text":"INNER JOIN"},{"id":"opt2","text":"LEFT JOIN"},{"id":"opt3","text":"CROSS JOIN"},{"id":"opt4","text":"FULL OUTER JOIN"}]'::jsonb, 'opt1',
     'An INNER JOIN returns rows that satisfy the join condition in both tables.'),
    ('44444444-4444-4444-8444-444444444404'::uuid, 'SQL Joins and Grouping', 2,
     'Which clause filters groups after aggregate calculations?', '[{"id":"opt1","text":"WHERE"},{"id":"opt2","text":"ORDER BY"},{"id":"opt3","text":"HAVING"},{"id":"opt4","text":"LIMIT"}]'::jsonb, 'opt3',
     'HAVING filters grouped rows, typically using aggregate expressions.'),
    ('44444444-4444-4444-8444-444444444404'::uuid, 'SQL Joins and Grouping', 3,
     'Which aggregate counts non-NULL values in a column?', '[{"id":"opt1","text":"COUNT(column_name)"},{"id":"opt2","text":"SUM(column_name)"},{"id":"opt3","text":"AVG(column_name)"},{"id":"opt4","text":"MAX(column_name)"}]'::jsonb, 'opt1',
     'COUNT(column_name) excludes NULL values; COUNT(*) counts rows.'),

    ('44444444-4444-4444-8444-444444444405'::uuid, 'Data Structures and Complexity', 1,
     'What is the average lookup time for a key in a well-distributed hash table?', '[{"id":"opt1","text":"O(1)"},{"id":"opt2","text":"O(log n)"},{"id":"opt3","text":"O(n)"},{"id":"opt4","text":"O(n log n)"}]'::jsonb, 'opt1',
     'Hash tables provide average constant-time lookup, although worst-case lookup can be linear.'),
    ('44444444-4444-4444-8444-444444444405'::uuid, 'Data Structures and Complexity', 2,
     'Which data structure follows last-in, first-out ordering?', '[{"id":"opt1","text":"Queue"},{"id":"opt2","text":"Stack"},{"id":"opt3","text":"Heap"},{"id":"opt4","text":"Graph"}]'::jsonb, 'opt2',
     'A stack removes the most recently added item first.'),
    ('44444444-4444-4444-8444-444444444405'::uuid, 'Data Structures and Complexity', 3,
     'What is the time complexity of binary search on a sorted array?', '[{"id":"opt1","text":"O(1)"},{"id":"opt2","text":"O(log n)"},{"id":"opt3","text":"O(n)"},{"id":"opt4","text":"O(n squared)"}]'::jsonb, 'opt2',
     'Binary search halves the remaining search interval at each step.'),

    ('44444444-4444-4444-8444-444444444406'::uuid, 'Psychology: Memory and Attention', 1,
     'Which memory system briefly holds and manipulates information for a current task?', '[{"id":"opt1","text":"Working memory"},{"id":"opt2","text":"Procedural memory"},{"id":"opt3","text":"Sensory adaptation"},{"id":"opt4","text":"Long-term semantic memory"}]'::jsonb, 'opt1',
     'Working memory temporarily maintains and manipulates information for ongoing cognition.'),
    ('44444444-4444-4444-8444-444444444406'::uuid, 'Psychology: Memory and Attention', 2,
     'What is retrieval in memory?', '[{"id":"opt1","text":"Taking in sensory energy"},{"id":"opt2","text":"Accessing stored information"},{"id":"opt3","text":"Repeating a motor action"},{"id":"opt4","text":"Reducing attention"}]'::jsonb, 'opt2',
     'Retrieval is the process of accessing information stored in memory.'),
    ('44444444-4444-4444-8444-444444444406'::uuid, 'Psychology: Memory and Attention', 3,
     'Selective attention primarily refers to the ability to:', '[{"id":"opt1","text":"Focus on selected information"},{"id":"opt2","text":"Store every sensory detail permanently"},{"id":"opt3","text":"Eliminate all distractions"},{"id":"opt4","text":"Recall events in exact order"}]'::jsonb, 'opt1',
     'Selective attention prioritizes some information while other available information receives less processing.'),

    ('44444444-4444-4444-8444-444444444407'::uuid, 'Developmental Psychology: Attachment', 1,
     'Attachment theory primarily examines the relationship between early caregiving and:', '[{"id":"opt1","text":"Close emotional bonds"},{"id":"opt2","text":"Visual perception"},{"id":"opt3","text":"Language grammar"},{"id":"opt4","text":"Numerical ability"}]'::jsonb, 'opt1',
     'Attachment theory studies enduring emotional bonds, especially between infants and caregivers.'),
    ('44444444-4444-4444-8444-444444444407'::uuid, 'Developmental Psychology: Attachment', 2,
     'In classic attachment research, which behavior is commonly associated with secure attachment during reunion?', '[{"id":"opt1","text":"Seeking comfort and settling"},{"id":"opt2","text":"Never noticing the caregiver"},{"id":"opt3","text":"Showing no response to separation"},{"id":"opt4","text":"Consistently avoiding all contact"}]'::jsonb, 'opt1',
     'Securely attached infants commonly seek contact after reunion and are comforted by the caregiver.'),
    ('44444444-4444-4444-8444-444444444407'::uuid, 'Developmental Psychology: Attachment', 3,
     'Which caregiving quality is generally associated with supporting secure attachment?', '[{"id":"opt1","text":"Sensitive responsiveness"},{"id":"opt2","text":"Unpredictable rejection"},{"id":"opt3","text":"Persistent unavailability"},{"id":"opt4","text":"Frequent unexplained separation"}]'::jsonb, 'opt1',
     'Consistent, sensitive responses to a child’s signals support the development of secure attachment.'),

    ('44444444-4444-4444-8444-444444444408'::uuid, 'Social Psychology: Groups and Influence', 1,
     'Conformity is best described as:', '[{"id":"opt1","text":"Changing behavior or judgment toward a group norm"},{"id":"opt2","text":"Forgetting a personal memory"},{"id":"opt3","text":"Learning only through rewards"},{"id":"opt4","text":"Avoiding all social contact"}]'::jsonb, 'opt1',
     'Conformity involves adjusting behavior or judgments in response to group norms or pressure.'),
    ('44444444-4444-4444-8444-444444444408'::uuid, 'Social Psychology: Groups and Influence', 2,
     'What is the fundamental attribution error?', '[{"id":"opt1","text":"Overemphasizing personal traits when explaining others\u2019 behavior"},{"id":"opt2","text":"Attributing all behavior to chance"},{"id":"opt3","text":"Ignoring situational factors in one\u2019s own behavior only"},{"id":"opt4","text":"Assuming groups have no influence"}]'::jsonb, 'opt1',
     'This bias gives too much weight to dispositional explanations and too little to situational influences when judging others.'),
    ('44444444-4444-4444-8444-444444444408'::uuid, 'Social Psychology: Groups and Influence', 3,
     'Normative social influence is often driven by a desire to:', '[{"id":"opt1","text":"Gain acceptance or avoid rejection"},{"id":"opt2","text":"Improve long-term memory"},{"id":"opt3","text":"Increase sensory acuity"},{"id":"opt4","text":"Avoid learning group rules"}]'::jsonb, 'opt1',
     'Normative influence reflects the motivation to be accepted and avoid social disapproval.'),

    ('44444444-4444-4444-8444-444444444409'::uuid, 'Psychological Research Methods', 1,
     'In an experiment, the independent variable is the factor that the researcher:', '[{"id":"opt1","text":"Manipulates or assigns"},{"id":"opt2","text":"Measures as the outcome"},{"id":"opt3","text":"Keeps secret from participants"},{"id":"opt4","text":"Uses only for recruitment"}]'::jsonb, 'opt1',
     'Researchers manipulate or assign the independent variable to examine its effect on an outcome.'),
    ('44444444-4444-4444-8444-444444444409'::uuid, 'Psychological Research Methods', 2,
     'Reliability of a measure refers primarily to its:', '[{"id":"opt1","text":"Consistency"},{"id":"opt2","text":"Popularity"},{"id":"opt3","text":"Complexity"},{"id":"opt4","text":"Cost"}]'::jsonb, 'opt1',
     'A reliable measure produces consistent results under comparable conditions.'),
    ('44444444-4444-4444-8444-444444444409'::uuid, 'Psychological Research Methods', 3,
     'Which practice is central to informed consent?', '[{"id":"opt1","text":"Explaining relevant study information and voluntary participation"},{"id":"opt2","text":"Guaranteeing every participant benefits"},{"id":"opt3","text":"Hiding all foreseeable risks"},{"id":"opt4","text":"Requiring participation without withdrawal"}]'::jsonb, 'opt1',
     'Informed consent includes relevant information and a voluntary choice to participate.'),

    ('44444444-4444-4444-8444-444444444410'::uuid, 'Machine Learning: Classification', 1,
     'Which metric is the fraction of all predictions that are correct?', '[{"id":"opt1","text":"Accuracy"},{"id":"opt2","text":"Recall"},{"id":"opt3","text":"Specificity"},{"id":"opt4","text":"Mean absolute error"}]'::jsonb, 'opt1',
     'Accuracy is the number of correct predictions divided by the total number of predictions.'),
    ('44444444-4444-4444-8444-444444444410'::uuid, 'Machine Learning: Classification', 2,
     'A model performs very well on training data but poorly on unseen data. This most strongly suggests:', '[{"id":"opt1","text":"Overfitting"},{"id":"opt2","text":"Underfitting"},{"id":"opt3","text":"Perfect generalization"},{"id":"opt4","text":"Data normalization"}]'::jsonb, 'opt1',
     'Overfitting occurs when a model learns training-specific patterns that do not generalize well.'),
    ('44444444-4444-4444-8444-444444444410'::uuid, 'Machine Learning: Classification', 3,
     'Which metric is especially useful when false negatives are costly?', '[{"id":"opt1","text":"Recall"},{"id":"opt2","text":"Accuracy alone"},{"id":"opt3","text":"Mean squared error"},{"id":"opt4","text":"R-squared"}]'::jsonb, 'opt1',
     'Recall measures the proportion of actual positive cases correctly identified.'),

    ('44444444-4444-4444-8444-444444444411'::uuid, 'Generative AI and Prompting', 1,
     'What does grounding a generated answer mean?', '[{"id":"opt1","text":"Connecting it to trusted source information"},{"id":"opt2","text":"Increasing its randomness"},{"id":"opt3","text":"Removing all context"},{"id":"opt4","text":"Making it longer"}]'::jsonb, 'opt1',
     'Grounding ties a response to supplied or retrieved information to improve relevance and verifiability.'),
    ('44444444-4444-4444-8444-444444444411'::uuid, 'Generative AI and Prompting', 2,
     'Why should important AI-generated facts be checked against reliable sources?', '[{"id":"opt1","text":"Models can produce plausible but incorrect output"},{"id":"opt2","text":"Models always cite every source"},{"id":"opt3","text":"Prompts prevent all errors"},{"id":"opt4","text":"Generated text is automatically peer reviewed"}]'::jsonb, 'opt1',
     'Generative models can produce fluent statements that are inaccurate, so important claims need verification.'),
    ('44444444-4444-4444-8444-444444444411'::uuid, 'Generative AI and Prompting', 3,
     'Which prompt is most likely to produce a useful structured result?', '[{"id":"opt1","text":"Specify the task, audience, constraints, and desired format"},{"id":"opt2","text":"Use only the word \u201canswer\u201d"},{"id":"opt3","text":"Remove all relevant context"},{"id":"opt4","text":"Ask for unrelated topics at once"}]'::jsonb, 'opt1',
     'Clear task details, audience, constraints, and output format help guide a more relevant response.'),

    ('44444444-4444-4444-8444-444444444412'::uuid, 'Computer Networks: HTTP and TCP/IP', 1,
     'Which transport protocol provides reliable, ordered byte delivery?', '[{"id":"opt1","text":"TCP"},{"id":"opt2","text":"UDP"},{"id":"opt3","text":"ARP"},{"id":"opt4","text":"DNS"}]'::jsonb, 'opt1',
     'TCP provides reliable, ordered delivery through acknowledgments and retransmission.'),
    ('44444444-4444-4444-8444-444444444412'::uuid, 'Computer Networks: HTTP and TCP/IP', 2,
     'What does an HTTP 404 status indicate?', '[{"id":"opt1","text":"The requested resource was not found"},{"id":"opt2","text":"The request succeeded"},{"id":"opt3","text":"The server is redirecting permanently"},{"id":"opt4","text":"The client is unauthorized"}]'::jsonb, 'opt1',
     'HTTP 404 indicates that the server could not find the requested resource.'),
    ('44444444-4444-4444-8444-444444444412'::uuid, 'Computer Networks: HTTP and TCP/IP', 3,
     'What is the primary role of DNS?', '[{"id":"opt1","text":"Translate domain names to network addresses"},{"id":"opt2","text":"Encrypt every web request"},{"id":"opt3","text":"Assign application passwords"},{"id":"opt4","text":"Compress HTML documents"}]'::jsonb, 'opt1',
     'DNS resolves domain names to records such as IP addresses used to locate network services.'),

    ('44444444-4444-4444-8444-444444444413'::uuid, 'Operating Systems Fundamentals', 1,
     'A process is best described as:', '[{"id":"opt1","text":"A program in execution"},{"id":"opt2","text":"A source-code comment"},{"id":"opt3","text":"A network cable"},{"id":"opt4","text":"A stored database row"}]'::jsonb, 'opt1',
     'A process is an executing instance of a program with associated state and resources.'),
    ('44444444-4444-4444-8444-444444444413'::uuid, 'Operating Systems Fundamentals', 2,
     'Which scheduling goal aims to give each task a fair share of CPU time?', '[{"id":"opt1","text":"Fairness"},{"id":"opt2","text":"Compilation"},{"id":"opt3","text":"Encryption"},{"id":"opt4","text":"Address resolution"}]'::jsonb, 'opt1',
     'Fair scheduling seeks to distribute processor time equitably among eligible tasks.'),
    ('44444444-4444-4444-8444-444444444413'::uuid, 'Operating Systems Fundamentals', 3,
     'What is virtual memory used for?', '[{"id":"opt1","text":"Providing processes with an address space backed by physical memory and storage"},{"id":"opt2","text":"Replacing the CPU scheduler"},{"id":"opt3","text":"Making every disk operation instantaneous"},{"id":"opt4","text":"Removing the need for physical memory"}]'::jsonb, 'opt1',
     'Virtual memory maps process address spaces to physical memory and may use storage to extend available capacity.'),

    ('44444444-4444-4444-8444-444444444414'::uuid, 'Cybersecurity Fundamentals', 1,
     'What does the principle of least privilege require?', '[{"id":"opt1","text":"Grant only the access needed for a task"},{"id":"opt2","text":"Give every account administrator access"},{"id":"opt3","text":"Share credentials across a team"},{"id":"opt4","text":"Disable authentication for internal users"}]'::jsonb, 'opt1',
     'Least privilege limits permissions to what is necessary for the user or process.'),
    ('44444444-4444-4444-8444-444444444414'::uuid, 'Cybersecurity Fundamentals', 2,
     'Which defense helps prevent cross-site request forgery?', '[{"id":"opt1","text":"A validated anti-CSRF token"},{"id":"opt2","text":"A longer page title"},{"id":"opt3","text":"A public database key"},{"id":"opt4","text":"Disabling output encoding"}]'::jsonb, 'opt1',
     'A server-validated CSRF token helps distinguish legitimate form submissions from forged cross-site requests.'),
    ('44444444-4444-4444-8444-444444444414'::uuid, 'Cybersecurity Fundamentals', 3,
     'Why should passwords be stored using a password-hashing function?', '[{"id":"opt1","text":"To make recovery of the original password computationally difficult"},{"id":"opt2","text":"To allow anyone to read passwords quickly"},{"id":"opt3","text":"To remove the need for authorization"},{"id":"opt4","text":"To expose credentials in logs"}]'::jsonb, 'opt1',
     'A slow, salted password hash reduces the risk of recovering passwords if a credential store is exposed.'),

    ('44444444-4444-4444-8444-444444444415'::uuid, 'Logical Reasoning and Quantitative Aptitude', 1,
     'A price of 80 increases by 25%. What is the new price?', '[{"id":"opt1","text":"90"},{"id":"opt2","text":"95"},{"id":"opt3","text":"100"},{"id":"opt4","text":"105"}]'::jsonb, 'opt3',
     'Twenty-five percent of 80 is 20, so the new price is 100.'),
    ('44444444-4444-4444-8444-444444444415'::uuid, 'Logical Reasoning and Quantitative Aptitude', 2,
     'What number comes next in the sequence 3, 6, 12, 24?', '[{"id":"opt1","text":"30"},{"id":"opt2","text":"36"},{"id":"opt3","text":"42"},{"id":"opt4","text":"48"}]'::jsonb, 'opt4',
     'Each term is doubled, so the next term is 48.'),
    ('44444444-4444-4444-8444-444444444415'::uuid, 'Logical Reasoning and Quantitative Aptitude', 3,
     'All tutors are readers. Some readers are writers. Which statement must be true?', '[{"id":"opt1","text":"All tutors are readers"},{"id":"opt2","text":"All tutors are writers"},{"id":"opt3","text":"No readers are tutors"},{"id":"opt4","text":"All writers are tutors"}]'::jsonb, 'opt1',
     'The first premise directly guarantees that every tutor belongs to the set of readers.')
)
INSERT INTO public.questions (
    id, quiz_id, question_text, options, correct_option_id, explanation, order_index, marks
)
SELECT
    uuid_generate_v5(seed_questions.quiz_id, 'question-' || seed_questions.order_index),
    seed_questions.quiz_id,
    seed_questions.question_text,
    seed_questions.options,
    seed_questions.correct_option_id,
    seed_questions.explanation,
    seed_questions.order_index,
    1
FROM seed_questions
JOIN public.quizzes quiz
  ON quiz.id = seed_questions.quiz_id
 AND quiz.title = seed_questions.quiz_title
 AND quiz.created_by IS NULL
 AND quiz.published = TRUE
ON CONFLICT (id) DO NOTHING;

UPDATE public.quizzes quiz
SET question_count = (
    SELECT COUNT(*)::INTEGER
    FROM public.questions question
    WHERE question.quiz_id = quiz.id
)
WHERE quiz.id BETWEEN '44444444-4444-4444-8444-444444444401'::uuid
                  AND '44444444-4444-4444-8444-444444444415'::uuid
  AND quiz.created_by IS NULL
  AND quiz.published = TRUE
  AND quiz.title IN (
      'Python Fundamentals: Core Concepts',
      'Python Functions and Recursion',
      'Java OOP and Polymorphism',
      'SQL Joins and Grouping',
      'Data Structures and Complexity',
      'Psychology: Memory and Attention',
      'Developmental Psychology: Attachment',
      'Social Psychology: Groups and Influence',
      'Psychological Research Methods',
      'Machine Learning: Classification',
      'Generative AI and Prompting',
      'Computer Networks: HTTP and TCP/IP',
      'Operating Systems Fundamentals',
      'Cybersecurity Fundamentals',
      'Logical Reasoning and Quantitative Aptitude'
  );

COMMIT;

NOTIFY pgrst, 'reload schema';
