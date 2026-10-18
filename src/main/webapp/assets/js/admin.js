/**
 * QuizMaster — Admin Management Panel JavaScript
 * Handles quiz creation/edit/deletion and question bank management.
 */

document.addEventListener('DOMContentLoaded', () => {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
    // ── 1. Quiz Management ─────────────────────────────────────────────────────

    const quizModal = document.getElementById('quiz-modal-backdrop');
    const btnNewQuiz = document.getElementById('btn-new-quiz');
    const btnCancelQuiz = document.getElementById('btn-cancel-quiz');
    const quizForm = document.getElementById('quiz-form');

    if (btnNewQuiz && quizModal) {
        btnNewQuiz.addEventListener('click', () => {
            if (quizForm) quizForm.reset();
            const idField = document.getElementById('quiz-id');
            if (idField) idField.value = '';
            const modalTitle = document.getElementById('quiz-modal-title');
            if (modalTitle) modalTitle.textContent = 'Create New Quiz';
            quizModal.classList.add('open');
        });
    }

    if (btnCancelQuiz && quizModal) {
        btnCancelQuiz.addEventListener('click', () => {
            quizModal.classList.remove('open');
        });
    }

    // Edit Quiz button click
    document.querySelectorAll('.btn-edit-quiz').forEach(btn => {
        btn.addEventListener('click', () => {
            if (!quizModal || !quizForm) return;
            document.getElementById('quiz-id').value = btn.dataset.id || '';
            document.getElementById('quiz-title').value = btn.dataset.title || '';
            document.getElementById('quiz-subject').value = btn.dataset.subject || '';
            document.getElementById('quiz-duration').value = btn.dataset.duration || '30';
            document.getElementById('quiz-passmark').value = btn.dataset.passmark || '50';
            document.getElementById('quiz-attempts').value = btn.dataset.attempts || '1';
            document.getElementById('quiz-desc').value = btn.dataset.desc || '';
            document.getElementById('quiz-published').checked = btn.dataset.published === 'true';

            const modalTitle = document.getElementById('quiz-modal-title');
            if (modalTitle) modalTitle.textContent = 'Edit Quiz';

            quizModal.classList.add('open');
        });
    });

    // Save Quiz Form Submit
    if (quizForm) {
        quizForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const submitBtn = quizForm.querySelector('button[type="submit"]');
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span class="spinner"></span> Saving...';
            }

            try {
                const formData = new FormData(quizForm);
                const params = new URLSearchParams(formData);

                const res = await fetch(quizForm.action, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                        'Accept': 'application/json',
                        'X-CSRF-Token': csrfToken
                    },
                    body: params.toString()
                });

                const data = await res.json().catch(() => ({}));
                if (!res.ok || data.success === false) {
                    throw new Error(data.error || 'Failed to save quiz');
                }

                window.location.reload();
            } catch (err) {
                alert('Error saving quiz: ' + err.message);
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Save Quiz';
                }
            }
        });
    }

    // Delete Quiz
    document.querySelectorAll('.btn-delete-quiz').forEach(btn => {
        btn.addEventListener('click', async () => {
            const id = btn.dataset.id;
            const title = btn.dataset.title || 'this quiz';
            if (!confirm(`Are you sure you want to delete "${title}"? All associated questions and student attempts will also be removed.`)) {
                return;
            }

            try {
                const contextPath = btn.dataset.contextPath || '';
                const res = await fetch(`${contextPath}/admin/quizzes?id=${encodeURIComponent(id)}`, {
                    method: 'DELETE',
                    headers: { 'Accept': 'application/json', 'X-CSRF-Token': csrfToken }
                });

                const data = await res.json().catch(() => ({}));
                if (!res.ok || data.success === false) {
                    throw new Error(data.error || 'Failed to delete');
                }

                window.location.reload();
            } catch (err) {
                alert('Delete error: ' + err.message);
            }
        });
    });

    // ── 2. Question Bank Management ────────────────────────────────────────────

    const questionModal = document.getElementById('question-modal-backdrop');
    const btnNewQuestion = document.getElementById('btn-new-question');
    const btnCancelQuestion = document.getElementById('btn-cancel-question');
    const questionForm = document.getElementById('question-form');

    if (btnNewQuestion && questionModal) {
        btnNewQuestion.addEventListener('click', () => {
            if (questionForm) questionForm.reset();
            questionModal.classList.add('open');
        });
    }

    if (btnCancelQuestion && questionModal) {
        btnCancelQuestion.addEventListener('click', () => {
            questionModal.classList.remove('open');
        });
    }

    // Save Question Submit (JSON body)
    if (questionForm) {
        questionForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const submitBtn = questionForm.querySelector('button[type="submit"]');
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span class="spinner"></span> Saving...';
            }

            try {
                const quizId = document.getElementById('q-quiz-id').value;
                const questionText = document.getElementById('q-text').value;
                const marks = parseInt(document.getElementById('q-marks').value, 10) || 1;
                const correctOptIndex = document.querySelector('input[name="correctOpt"]:checked')?.value || '0';

                // Build options array
                const optA = document.getElementById('q-opt-0').value.trim();
                const optB = document.getElementById('q-opt-1').value.trim();
                const optC = document.getElementById('q-opt-2').value.trim();
                const optD = document.getElementById('q-opt-3').value.trim();

                const rawOptions = [optA, optB, optC, optD];
                const options = [];
                let correctOptionId = '';

                rawOptions.forEach((txt, idx) => {
                    const id = 'opt_' + (idx + 1);
                    options.push({ id, text: txt });
                    if (String(idx) === correctOptIndex) {
                        correctOptionId = id;
                    }
                });

                const payload = {
                    quizId,
                    questionText,
                    marks,
                    correctOptionId,
                    orderIndex: 0,
                    options
                };

                const res = await fetch(questionForm.action, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json;charset=UTF-8',
                        'Accept': 'application/json',
                        'X-CSRF-Token': csrfToken
                    },
                    body: JSON.stringify(payload)
                });

                const data = await res.json().catch(() => ({}));
                if (!res.ok || data.success === false) {
                    throw new Error(data.error || 'Failed to save question');
                }

                window.location.reload();
            } catch (err) {
                alert('Error saving question: ' + err.message);
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Save Question';
                }
            }
        });
    }

    // Delete Question
    document.querySelectorAll('.btn-delete-question').forEach(btn => {
        btn.addEventListener('click', async () => {
            const id = btn.dataset.id;
            if (!confirm('Are you sure you want to delete this question?')) return;

            try {
                const contextPath = btn.dataset.contextPath || '';
                const res = await fetch(`${contextPath}/admin/questions?id=${encodeURIComponent(id)}`, {
                    method: 'DELETE',
                    headers: { 'Accept': 'application/json', 'X-CSRF-Token': csrfToken }
                });

                const data = await res.json().catch(() => ({}));
                if (!res.ok || data.success === false) {
                    throw new Error(data.error || 'Failed to delete question');
                }

                window.location.reload();
            } catch (err) {
                alert('Delete error: ' + err.message);
            }
        });
    });
});
