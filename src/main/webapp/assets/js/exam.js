/**
 * QuizMaster — Live Examination Engine
 * Handles questions fetching, pagination, radio selection, auto-save,
 * countdown timer, review flags, tab-switch warning, and final submission.
 */

(function () {
    'use strict';

    // State
    let config = {
        quizId: '',
        attemptId: '',
        contextPath: '',
        csrfToken: ''
    };

    let questions = [];
    let savedAnswers = {};      // questionId -> optionId
    let markedForReview = new Set();
    let currentIndex = 0;
    let deadlineTime = null;
    let timerInterval = null;
    let isSubmitting = false;
    const pendingAnswerSaves = new Map();
    const answerSaveFailures = new Set();

    document.addEventListener('DOMContentLoaded', initExam);

    function initExam() {
        const root = document.getElementById('exam-root');
        if (!root) return;

        config.quizId = root.dataset.quizId || '';
        config.attemptId = root.dataset.attemptId || '';
        config.contextPath = root.dataset.contextPath || '';
        config.csrfToken = root.dataset.csrfToken || '';

        if (!config.quizId || !config.attemptId) {
            showExamError('Missing quiz or attempt parameters.');
            return;
        }

        bindNavigationEvents();
        setupAntiCheatListeners();
        loadQuestions();
    }

    // ── 1. Fetch Questions ─────────────────────────────────────────────────────

    async function loadQuestions() {
        showLoading(true);
        try {
            const url = `${config.contextPath}/student/exam/questions?attemptId=${encodeURIComponent(config.attemptId)}&quizId=${encodeURIComponent(config.quizId)}`;
            const res = await fetch(url, { headers: { 'Accept': 'application/json' } });

            if (res.status === 410) {
                // Expired
                const data = await res.json();
                alert(data.error || 'Exam deadline has expired.');
                window.location.href = `${config.contextPath}/student/result?attemptId=${encodeURIComponent(config.attemptId)}`;
                return;
            }

            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                throw new Error(err.error || `HTTP ${res.status}`);
            }

            const data = await res.json();
            const parsed = typeof data.data === 'string' ? JSON.parse(data.data) : data.data;

            questions = parsed.questions || [];
            if (questions.length === 0) {
                showExamError('No questions available in this examination.');
                return;
            }

            // Restore saved answers
            if (Array.isArray(parsed.savedAnswers)) {
                parsed.savedAnswers.forEach(ans => {
                    if (ans.questionId && ans.selectedOptionId) {
                        savedAnswers[ans.questionId] = ans.selectedOptionId;
                    }
                });
            }

            // Setup timer
            if (parsed.deadline) {
                deadlineTime = new Date(parsed.deadline).getTime();
                startTimer();
            }

            renderPalette();
            renderCurrentQuestion();
            showLoading(false);

        } catch (err) {
            console.error('Failed to load questions:', err);
            showExamError('Unable to load exam questions: ' + err.message);
        }
    }

    // ── 2. Timer Engine ────────────────────────────────────────────────────────

    function startTimer() {
        if (!deadlineTime) return;
        updateTimerDisplay();

        timerInterval = setInterval(() => {
            const now = Date.now();
            const remaining = Math.max(0, Math.floor((deadlineTime - now) / 1000));

            if (remaining <= 0) {
                clearInterval(timerInterval);
                onTimerExpired();
            } else {
                updateTimerDisplay(remaining);
            }
        }, 1000);
    }

    function updateTimerDisplay(remainingSeconds) {
        if (remainingSeconds === undefined) {
            const now = Date.now();
            remainingSeconds = Math.max(0, Math.floor((deadlineTime - now) / 1000));
        }

        const mins = Math.floor(remainingSeconds / 60);
        const secs = remainingSeconds % 60;
        const text = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

        const el = document.getElementById('exam-timer');
        if (!el) return;
        el.textContent = text;

        if (remainingSeconds < 60) {
            el.className = 'timer-badge timer-danger';
        } else if (remainingSeconds < 300) {
            el.className = 'timer-badge timer-warn';
        } else {
            el.className = 'timer-badge timer-normal';
        }
    }

    function onTimerExpired() {
        if (isSubmitting) return;
        alert('Time is up! Your examination is now being automatically submitted.');
        executeSubmit();
    }

    // ── 3. Render Question & Palette ──────────────────────────────────────────

    function renderCurrentQuestion() {
        const q = questions[currentIndex];
        if (!q) return;

        // Counter
        const counterEl = document.getElementById('question-counter');
        if (counterEl) {
            counterEl.textContent = `Question ${currentIndex + 1} of ${questions.length}`;
        }

        // Marks
        const marksEl = document.getElementById('question-marks');
        if (marksEl) {
            marksEl.textContent = `${q.marks || 1} mark${(q.marks || 1) > 1 ? 's' : ''}`;
        }

        // Text
        const textEl = document.getElementById('question-text');
        if (textEl) {
            textEl.textContent = q.questionText || '';
        }

        // Review button text
        const revBtn = document.getElementById('btn-review');
        if (revBtn) {
            const isMarked = markedForReview.has(q.id);
            revBtn.classList.toggle('active', isMarked);
            revBtn.innerHTML = isMarked
                ? '★ Marked for Review'
                : '☆ Mark for Review';
        }

        // Options
        const container = document.getElementById('options-container');
        if (container) {
            container.innerHTML = '';
            const opts = q.options || [];
            const selectedOpt = savedAnswers[q.id];

            opts.forEach((opt, idx) => {
                const label = document.createElement('label');
                label.className = 'option-card' + (selectedOpt === opt.id ? ' selected' : '');

                const letter = String.fromCharCode(65 + idx); // A, B, C, D
                const inputId = `answer-${q.id}-${idx}`;

                label.innerHTML = `
                    <input id="${escapeHtml(inputId)}" type="radio" name="optChoice"
                           value="${escapeHtml(opt.id)}"
                           aria-label="Option ${letter}: ${escapeHtml(opt.text)}"
                           ${isSubmitting ? 'disabled' : ''}
                           ${selectedOpt === opt.id ? 'checked' : ''}>
                    <span class="option-letter">${letter}</span>
                    <span class="option-text">${escapeHtml(opt.text)}</span>
                `;

                label.querySelector('input').addEventListener('change', () => {
                    selectAnswer(q.id, opt.id);
                });

                container.appendChild(label);
            });
        }

        // Update Prev / Next button states
        const prevBtn = document.getElementById('btn-prev');
        const nextBtn = document.getElementById('btn-next');
        if (prevBtn) prevBtn.disabled = currentIndex === 0;
        if (nextBtn) {
            if (currentIndex === questions.length - 1) {
                nextBtn.innerHTML = 'Review & Finish →';
            } else {
                nextBtn.innerHTML = 'Next Question →';
            }
        }

        updatePaletteSelection();
    }

    function renderPalette() {
        const palette = document.getElementById('question-palette');
        if (!palette) return;
        palette.innerHTML = '';

        questions.forEach((q, idx) => {
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'palette-btn';
            btn.textContent = String(idx + 1);
            btn.dataset.index = idx;

            btn.addEventListener('click', () => {
                currentIndex = idx;
                renderCurrentQuestion();
            });

            palette.appendChild(btn);
        });

        updatePaletteSelection();
    }

    function updatePaletteSelection() {
        const buttons = document.querySelectorAll('.palette-btn');
        buttons.forEach((btn, idx) => {
            const q = questions[idx];
            if (!q) return;

            btn.classList.remove('current', 'answered', 'marked');

            if (idx === currentIndex) {
                btn.classList.add('current');
            }

            if (markedForReview.has(q.id)) {
                btn.classList.add('marked');
            } else if (savedAnswers[q.id]) {
                btn.classList.add('answered');
            }
        });

        // Update answered count
        const answeredCount = Object.values(savedAnswers).filter(Boolean).length;
        const totalCount = questions.length;
        const progressEl = document.getElementById('answered-stats');
        if (progressEl) {
            progressEl.textContent = `${answeredCount} of ${totalCount} Answered`;
        }
        const bar = document.getElementById('answered-progress-bar');
        if (bar) {
            const pct = totalCount > 0 ? (answeredCount / totalCount) * 100 : 0;
            bar.style.width = `${pct}%`;
        }
    }

    // ── 4. Save Answer ─────────────────────────────────────────────────────────

    async function selectAnswer(questionId, optionId) {
        if (optionId) {
            savedAnswers[questionId] = optionId;
            answerSaveFailures.delete(questionId);
        } else {
            delete savedAnswers[questionId];
        }
        renderCurrentQuestion(); // refreshes UI card styling and palette

        const statusEl = document.getElementById('save-status');
        if (statusEl) {
            statusEl.textContent = 'Saving...';
            statusEl.className = 'save-status saving';
        }

        const previousSave = pendingAnswerSaves.get(questionId) || Promise.resolve();
        const pendingSave = previousSave.catch(() => {}).then(async () => {
            const body = new URLSearchParams();
            body.append('attemptId', config.attemptId);
            body.append('questionId', questionId);
            body.append('selectedOptionId', optionId);

            const res = await fetch(`${config.contextPath}/student/exam/save`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json',
                    'X-CSRF-Token': config.csrfToken
                },
                body: body.toString()
            });

            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                throw new Error(err.error || 'Failed to save');
            }

            answerSaveFailures.delete(questionId);
            if (statusEl) {
                statusEl.textContent = 'Saved ✓';
                statusEl.className = 'save-status saved';
            }
        }).catch(err => {
            answerSaveFailures.add(questionId);
            console.error('Autosave error:', err);
            if (statusEl) {
                statusEl.textContent = 'Save failed — reselect to retry';
                statusEl.className = 'save-status error';
            }
        }).finally(() => {
            if (pendingAnswerSaves.get(questionId) === pendingSave) {
                pendingAnswerSaves.delete(questionId);
            }
        });
        pendingAnswerSaves.set(questionId, pendingSave);
        await pendingSave;
    }

    // ── 5. Navigation & Actions ────────────────────────────────────────────────

    function bindNavigationEvents() {
        const prevBtn = document.getElementById('btn-prev');
        const nextBtn = document.getElementById('btn-next');
        const clearBtn = document.getElementById('btn-clear');
        const reviewBtn = document.getElementById('btn-review');
        const submitBtn = document.getElementById('btn-submit-exam');
        const modalCancel = document.getElementById('modal-cancel');
        const modalConfirm = document.getElementById('modal-confirm');

        if (prevBtn) {
            prevBtn.addEventListener('click', () => {
                if (currentIndex > 0) {
                    currentIndex--;
                    renderCurrentQuestion();
                }
            });
        }

        if (nextBtn) {
            nextBtn.addEventListener('click', () => {
                if (currentIndex < questions.length - 1) {
                    currentIndex++;
                    renderCurrentQuestion();
                } else {
                    openSubmitModal();
                }
            });
        }

        if (clearBtn) {
            clearBtn.addEventListener('click', () => {
                const q = questions[currentIndex];
                if (!q) return;
                delete savedAnswers[q.id];
                renderCurrentQuestion();
                selectAnswer(q.id, '');
            });
        }

        if (reviewBtn) {
            reviewBtn.addEventListener('click', () => {
                const q = questions[currentIndex];
                if (!q) return;
                if (markedForReview.has(q.id)) {
                    markedForReview.delete(q.id);
                } else {
                    markedForReview.add(q.id);
                }
                renderCurrentQuestion();
            });
        }

        if (submitBtn) {
            submitBtn.addEventListener('click', openSubmitModal);
        }

        if (modalCancel) {
            modalCancel.addEventListener('click', closeSubmitModal);
        }

        if (modalConfirm) {
            modalConfirm.addEventListener('click', () => {
                closeSubmitModal();
                executeSubmit();
            });
        }
    }

    // ── 6. Submission ──────────────────────────────────────────────────────────

    function openSubmitModal() {
        const modal = document.getElementById('submit-modal-backdrop');
        if (!modal) return;

        const total = questions.length;
        const answered = Object.keys(savedAnswers).filter(k => savedAnswers[k]).length;
        const unanswered = total - answered;
        const review = markedForReview.size;

        document.getElementById('modal-stat-total').textContent = String(total);
        document.getElementById('modal-stat-answered').textContent = String(answered);
        document.getElementById('modal-stat-unanswered').textContent = String(unanswered);
        document.getElementById('modal-stat-review').textContent = String(review);

        modal.classList.add('open');
    }

    function closeSubmitModal() {
        const modal = document.getElementById('submit-modal-backdrop');
        if (modal) modal.classList.remove('open');
    }

    async function executeSubmit() {
        if (isSubmitting) return;
        isSubmitting = true;

        const btn = document.getElementById('btn-submit-exam');
        document.querySelectorAll('input[name="optChoice"]').forEach(input => {
            input.disabled = true;
        });
        if (btn) {
            btn.disabled = true;
            btn.textContent = 'Saving answers...';
        }

        try {
            await Promise.all([...pendingAnswerSaves.values()]);
            if (answerSaveFailures.size > 0) {
                throw new Error('One or more answers could not be saved. Re-select those answers and submit again.');
            }
            if (timerInterval) clearInterval(timerInterval);
            if (btn) btn.innerHTML = '<span class="spinner"></span> Submitting...';

            const body = new URLSearchParams();
            body.append('attemptId', config.attemptId);
            body.append('quizId', config.quizId);

            const res = await fetch(`${config.contextPath}/student/exam/submit`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json',
                    'X-CSRF-Token': config.csrfToken
                },
                body: body.toString()
            });

            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                throw new Error(err.error || 'Failed to submit exam');
            }

            // Successfully scored — redirect to result page
            window.location.href = `${config.contextPath}/student/result?attemptId=${encodeURIComponent(config.attemptId)}`;

        } catch (err) {
            console.error('Submit error:', err);
            alert('Submission error: ' + err.message);
            isSubmitting = false;
            document.querySelectorAll('input[name="optChoice"]').forEach(input => {
                input.disabled = false;
            });
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = 'Submit Exam';
            }
        }
    }

    // ── 7. Anti-Cheat Monitoring ───────────────────────────────────────────────

    function setupAntiCheatListeners() {
        let warningCount = 0;
        const warnBanner = document.getElementById('anti-cheat-warning');

        document.addEventListener('visibilitychange', () => {
            if (document.hidden && !isSubmitting) {
                warningCount++;
                if (warnBanner) {
                    warnBanner.textContent = `⚠️ Tab switch detected (${warningCount}). Examinations are actively monitored.`;
                    warnBanner.style.display = 'block';
                    setTimeout(() => {
                        warnBanner.style.display = 'none';
                    }, 6000);
                }
            }
        });
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function showLoading(show) {
        const loading = document.getElementById('exam-loading');
        const content = document.getElementById('exam-content');
        if (loading) loading.style.display = show ? 'flex' : 'none';
        if (content) content.style.display = show ? 'none' : 'grid';
    }

    function showExamError(msg) {
        const root = document.getElementById('exam-root');
        if (!root) return;
        root.innerHTML = `
            <div class="empty-state" style="padding: 60px 20px;">
                <h3 style="color: var(--c-error);">Unable to Load Exam</h3>
                <p style="margin: 16px 0 24px;">${escapeHtml(msg)}</p>
                <a href="${escapeHtml(config.contextPath)}/student/quizzes" class="btn btn-primary">Return to Quiz Catalog</a>
            </div>
        `;
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }
})();
