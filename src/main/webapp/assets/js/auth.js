/**
 * QuizMaster — Authentication & Client-side Form Validation
 */
document.addEventListener('DOMContentLoaded', () => {
    // Password visibility toggles
    document.querySelectorAll('.input-eye').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = btn.getAttribute('data-target') || 'password';
            const input = document.getElementById(targetId);
            if (!input) return;
            const isPassword = input.type === 'password';
            input.type = isPassword ? 'text' : 'password';
            btn.setAttribute('aria-label', isPassword ? 'Hide password' : 'Show password');
            btn.innerHTML = isPassword
                ? `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>`
                : `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>`;
        });
    });

    // Register Form validation (password confirmation & strength)
    const registerForm = document.querySelector('form[action*="/register"]');
    if (registerForm) {
        const pwd = document.getElementById('password');
        const confirm = document.getElementById('confirmPassword');
        const errBanner = document.getElementById('js-client-error');

        registerForm.addEventListener('submit', (e) => {
            if (pwd && confirm && pwd.value !== confirm.value) {
                e.preventDefault();
                showError('Passwords do not match. Please re-enter.');
                confirm.focus();
                return;
            }
            if (pwd && pwd.value.length < 8) {
                e.preventDefault();
                showError('Password must be at least 8 characters long.');
                pwd.focus();
                return;
            }
            // Add loading indicator to submit button
            const submitBtn = registerForm.querySelector('button[type="submit"]');
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span class="spinner"></span> Creating account...';
            }
        });

        function showError(msg) {
            if (errBanner) {
                errBanner.textContent = msg;
                errBanner.style.display = 'block';
            } else {
                alert(msg);
            }
        }
    }

    // Login Form double submit prevention
    const loginForm = document.querySelector('form[action*="/login"]');
    if (loginForm) {
        loginForm.addEventListener('submit', () => {
            const submitBtn = loginForm.querySelector('button[type="submit"]');
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span class="spinner"></span> Signing in...';
            }
        });
    }
});
