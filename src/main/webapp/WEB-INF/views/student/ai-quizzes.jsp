<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, com.quizmaster.util.HtmlUtils, com.quizmaster.model.LearningTopic" %>
<%
    String initialTopic = request.getParameter("topic");
    String initialCategory = request.getParameter("category");
    String initialDifficulty = request.getParameter("difficulty");
    boolean validInitialCategory = initialCategory != null
            && LearningTopic.CATEGORIES.contains(initialCategory);
    boolean validInitialDifficulty = initialDifficulty != null
            && List.of("Beginner", "Intermediate", "Advanced").contains(initialDifficulty);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="<%= HtmlUtils.escape((String) request.getAttribute("csrfToken")) %>">
    <title>Generate AI Quiz | QuizMaster</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/main.css?v=20261019">
</head>
<body>
<header class="topbar">
    <a href="${pageContext.request.contextPath}/" class="topbar-brand"><span class="logo-icon">Q</span><span>QuizMaster</span></a>
    <nav class="topbar-nav">
        <a href="${pageContext.request.contextPath}/student/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/student/quizzes">Exam Catalog</a>
        <a href="${pageContext.request.contextPath}/student/my-quizzes">My AI Quizzes</a>
        <a href="${pageContext.request.contextPath}/student/history">My History</a>
    </nav>
    <div class="topbar-end"><form method="post" action="${pageContext.request.contextPath}/logout"><input type="hidden" name="_csrf" value="<%= HtmlUtils.escape((String) session.getAttribute("csrfToken")) %>"><button class="btn btn-ghost btn-sm" type="submit">Sign Out</button></form></div>
</header>
<main class="container" style="padding-block: 36px 64px; max-width: 960px;">
    <div style="margin-bottom: 28px;">
        <span class="badge badge-info">AI STUDY TOOL</span>
        <h1 style="margin-top: 10px;">Generate a practice quiz</h1>
        <p>Generate a private practice quiz from a topic using Gemini's general knowledge, or prioritize your own study material. Review the complete answer key before saving.</p>
    </div>
    <div id="generation-error" class="alert alert-error" role="alert" tabindex="-1" hidden></div>
    <form id="generation-form" class="card" method="post" enctype="multipart/form-data"
          action="${pageContext.request.contextPath}/student/ai-quizzes/generate">
        <input type="hidden" name="_csrf" value="<%= HtmlUtils.escape((String) request.getAttribute("csrfToken")) %>">
        <fieldset class="form-group" style="border: 0; padding: 0; margin: 0 0 20px;">
            <legend class="form-label">Choose a generation mode</legend>
            <div class="grid-auto" style="grid-template-columns: repeat(auto-fit,minmax(240px,1fr));">
                <label class="card" style="cursor: pointer;">
                    <input type="radio" name="mode" value="TOPIC" checked>
                    <strong>Mode A · Generate from a topic</strong>
                    <span class="form-hint" style="display:block;">No upload or pasted notes required. Gemini uses its generated knowledge.</span>
                </label>
                <label class="card" style="cursor: pointer;">
                    <input type="radio" name="mode" value="MATERIAL">
                    <strong>Mode B · Generate from study material</strong>
                    <span class="form-hint" style="display:block;">Paste notes or upload a supported document. Questions should be grounded in that material.</span>
                </label>
            </div>
        </fieldset>
        <div class="grid-auto" style="grid-template-columns: repeat(auto-fit,minmax(240px,1fr));">
            <div class="form-group">
                <label class="form-label" for="subject">Topic <span id="topic-required-note">*</span></label>
                <input class="form-input" id="subject" name="subject" maxlength="120"
                       value="<%= HtmlUtils.escape(initialTopic) %>"
                       placeholder="e.g. Python functions and recursion">
                <span id="material-subject-hint" class="form-hint" hidden>Optional focus area for questions from your notes.</span>
            </div>
            <div class="form-group">
                <label class="form-label" for="category">Subject category <span class="c-muted">(optional)</span></label>
                <select class="form-input" id="category" name="category">
                    <option value="">Any category</option>
                    <% for (String category : LearningTopic.CATEGORIES) { %>
                        <option value="<%= HtmlUtils.escape(category) %>" <%= validInitialCategory && category.equals(initialCategory) ? "selected" : "" %>><%= HtmlUtils.escape(category) %></option>
                    <% } %>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="difficulty">Difficulty</label>
                <select class="form-input" id="difficulty" name="difficulty">
                    <option <%= "Beginner".equals(initialDifficulty) ? "selected" : "" %>>Beginner</option>
                    <option <%= !validInitialDifficulty || "Intermediate".equals(initialDifficulty) ? "selected" : "" %>>Intermediate</option>
                    <option <%= "Advanced".equals(initialDifficulty) ? "selected" : "" %>>Advanced</option>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="questionType">Question type</label>
                <select class="form-input" id="questionType" name="questionType">
                    <option value="MULTIPLE_CHOICE" selected>Multiple Choice</option>
                </select>
                <span class="form-hint">The current quiz format stores four-option multiple-choice questions.</span>
            </div>
            <div class="form-group">
                <label class="form-label" for="questionCount">Number of questions (1–20)</label>
                <input class="form-input" id="questionCount" name="questionCount" type="number" min="1" max="20" value="10" required>
            </div>
            <div class="form-group">
                <label class="form-label" for="durationMinutes">Quiz duration (minutes)</label>
                <input class="form-input" id="durationMinutes" name="durationMinutes" type="number" min="1" max="300" value="30" required>
            </div>
        </div>
        <div class="form-group" style="margin-top: 18px;">
            <label class="form-label" for="instructions">Additional instructions <span class="c-muted">(optional)</span></label>
            <textarea class="form-input" id="instructions" name="instructions" rows="3" maxlength="2000"
                      placeholder="Mention concepts, learning goals, or preferred focus."></textarea>
        </div>
        <div id="material-fields" hidden>
        <div class="form-group" style="margin-top: 18px;">
            <label class="form-label" for="studyNotes">Paste study notes <span class="c-muted">(optional if a file is uploaded)</span></label>
            <textarea class="form-input" id="studyNotes" name="studyNotes" rows="6" maxlength="300000"
                      placeholder="Paste notes, course material, or a passage to use as the source."></textarea>
            <span class="form-hint">Up to 300,000 characters. Material mode requires notes or a readable file.</span>
        </div>
        <div class="form-group" style="margin-top: 18px;">
            <label class="form-label" for="sourceFile">Study notes <span class="c-muted">(optional)</span></label>
            <input class="form-input" id="sourceFile" name="sourceFile" type="file"
                   accept=".txt,.md,.csv,.pdf,text/plain,text/markdown,text/csv,application/pdf">
            <span class="form-hint">UTF-8 text or Markdown up to 100 KB; CSV up to 200 KB; text-based PDF up to 10 MB. Pasted and extracted text is limited to 300,000 characters. Scanned PDFs require OCR and are not supported. Files are processed temporarily, not saved; extracted text is sent to Gemini, so upload only material you are allowed to share.</span>
        </div>
        </div>
        <div class="flex items-center gap-3" style="margin-top: 24px; flex-wrap: wrap;">
            <button id="generate-button" class="btn btn-primary" type="submit">Generate quiz</button>
            <a class="btn btn-secondary" href="${pageContext.request.contextPath}/student/my-quizzes">My AI Quizzes</a>
            <span id="generation-status" class="fz-sm c-muted" role="status"></span>
        </div>
    </form>
    <section id="preview" class="card" style="margin-top: 28px;" hidden aria-live="polite">
        <div class="flex justify-between items-center" style="gap: 12px; flex-wrap: wrap;">
            <div><span class="badge badge-warn">PRIVATE DRAFT</span><h2 id="preview-title" style="margin-top: 8px;"></h2><p id="preview-meta"></p></div>
            <div class="flex gap-2">
                <button type="button" id="regenerate-button" class="btn btn-secondary">Regenerate</button>
                <button type="button" id="save-button" class="btn btn-primary">Save &amp; take quiz</button>
            </div>
        </div>
        <p class="alert alert-info" style="margin-top: 18px;">This is a read-only preview. To answer questions, choose <strong>Save &amp; take quiz</strong> above. The interactive exam will open with selectable answers and a Submit Exam button.</p>
        <div id="preview-questions" style="margin-top: 24px;"></div>
        <p class="form-hint" style="margin-top: 20px;">Correct answers stay hidden until you submit the quiz. Your score is calculated and saved to My History after submission.</p>
    </section>
</main>
<script>
(() => {
    const form = document.getElementById('generation-form');
    const errorBox = document.getElementById('generation-error');
    const status = document.getElementById('generation-status');
    const preview = document.getElementById('preview');
    const questionsEl = document.getElementById('preview-questions');
    const csrf = document.querySelector('meta[name="csrf-token"]').content;
    let draftId = null;

    const parseData = async response => {
        let payload;
        try {
            payload = await response.json();
        } catch {
            throw new Error(response.ok
                ? 'The server returned an unreadable response. Please try again.'
                : 'The request failed (HTTP ' + response.status
                    + '). Please sign in again if your session expired.');
        }
        if (!response.ok || payload.success === false) throw new Error(payload.error || 'Request failed.');
        const data = typeof payload.data === 'string' ? JSON.parse(payload.data) : payload.data;
        if (!data || typeof data !== 'object') {
            throw new Error('The server response was incomplete. Please try again.');
        }
        return data;
    };
    const showError = message => {
        errorBox.textContent = message;
        errorBox.hidden = false;
        errorBox.focus({preventScroll: true});
        errorBox.scrollIntoView({behavior: 'smooth', block: 'center'});
    };
    const render = data => {
        draftId = data.draftId;
        document.getElementById('preview-title').textContent = data.title;
        document.getElementById('preview-meta').textContent =
            (data.subject || 'Study material') + ' · ' + data.questions.length
            + ' questions · ' + data.durationMinutes + ' minutes';
        questionsEl.replaceChildren();
        data.questions.forEach((question, index) => {
            const article = document.createElement('article');
            article.className = 'generated-question';
            const number = document.createElement('span');
            number.className = 'question-number-tag';
            number.textContent = 'Question ' + (index + 1) + ' of ' + data.questions.length;
            const heading = document.createElement('h3');
            heading.textContent = question.questionText;
            article.append(number, heading);
            const list = document.createElement('div');
            list.className = 'generated-option-list';
            question.options.forEach((option, optionIndex) => {
                const item = document.createElement('div');
                item.className = 'generated-option';
                const letter = document.createElement('span');
                letter.className = 'generated-option-letter';
                letter.textContent = String.fromCharCode(65 + optionIndex);
                const text = document.createElement('span');
                text.textContent = option.text;
                item.append(letter, text);
                list.append(item);
            });
            article.append(list);
            questionsEl.append(article);
        });
        preview.hidden = false;
        preview.scrollIntoView({behavior: 'smooth', block: 'start'});
    };

    const topicInput = document.getElementById('subject');
    const modeInputs = [...document.querySelectorAll('input[name="mode"]')];
    const materialFields = document.getElementById('material-fields');
    const topicRequiredNote = document.getElementById('topic-required-note');
    const materialSubjectHint = document.getElementById('material-subject-hint');
    const updateMode = () => {
        const materialMode = modeInputs.find(input => input.checked)?.value === 'MATERIAL';
        materialFields.hidden = !materialMode;
        topicInput.required = !materialMode;
        topicRequiredNote.hidden = materialMode;
        materialSubjectHint.hidden = !materialMode;
        if (!materialMode) {
            document.getElementById('studyNotes').value = '';
            document.getElementById('sourceFile').value = '';
        }
    };
    modeInputs.forEach(input => input.addEventListener('change', updateMode));
    updateMode();

    form.addEventListener('submit', async event => {
        event.preventDefault();
        errorBox.hidden = true;
        const button = document.getElementById('generate-button');
        button.disabled = true;
        status.textContent = 'Generating and validating questions…';
        try {
            const response = await fetch(form.action, {
                method: 'POST', headers: {'Accept': 'application/json', 'X-CSRF-Token': csrf},
                body: new FormData(form)
            });
            render(await parseData(response));
            status.textContent = 'Review the draft before saving.';
        } catch (error) {
            showError(error.message);
            status.textContent = '';
        } finally {
            button.disabled = false;
        }
    });

    document.getElementById('regenerate-button').addEventListener('click', () => form.requestSubmit());
    document.getElementById('save-button').addEventListener('click', async event => {
        const button = event.currentTarget;
        if (!draftId) return;
        button.disabled = true;
        errorBox.hidden = true;
        status.textContent = 'Saving your private quiz…';
        try {
            const response = await fetch('<%= request.getContextPath() %>/student/ai-quizzes/save', {
                method: 'POST',
                headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-Token': csrf},
                body: JSON.stringify({draftId, durationMinutes: Number(document.getElementById('durationMinutes').value), passMark: 50})
            });
            const saved = await parseData(response);
            if (!saved.id) {
                throw new Error('The quiz was saved, but the exam could not be opened. Go to My AI Quizzes and choose Take quiz.');
            }
            window.location.assign('<%= request.getContextPath() %>/student/exam?quizId='
                + encodeURIComponent(saved.id));
        } catch (error) {
            showError(error.message);
            status.textContent = '';
            button.disabled = false;
        }
    });
})();
</script>
</body>
</html>
