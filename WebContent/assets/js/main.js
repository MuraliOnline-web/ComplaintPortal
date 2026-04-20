// main.js - Enhanced with toasts, form loading states, and UI improvements

// ==================== TOAST NOTIFICATIONS ====================
// Show toast notifications for success/error messages
function showToast(message, type = 'success') {
    const toastContainer = document.getElementById('toastContainer');
    if (!toastContainer) {
        const container = document.createElement('div');
        container.id = 'toastContainer';
        container.style.cssText = 'position:fixed;top:20px;right:20px;z-index:9999;';
        document.body.appendChild(container);
    }
    
    const toastId = 'toast-' + Date.now();
    const bgClass = type === 'success' ? 'bg-success' : (type === 'error' ? 'bg-danger' : 'bg-info');
    
    const toastEl = document.createElement('div');
    toastEl.id = toastId;
    toastEl.className = 'toast align-items-center text-white border-0 shadow-lg mb-2';
    toastEl.setAttribute('role', 'alert');
    toastEl.setAttribute('aria-live', 'assertive');
    toastEl.setAttribute('aria-atomic', 'true');

    const row = document.createElement('div');
    row.className = 'd-flex';

    const body = document.createElement('div');
    body.className = 'toast-body ' + bgClass + ' rounded';

    const strong = document.createElement('strong');
    strong.textContent = type === 'success' ? '✓ Success: ' : (type === 'error' ? '✕ Error: ' : 'ℹ Info: ');
    body.appendChild(strong);
    body.appendChild(document.createTextNode(message));

    row.appendChild(body);
    toastEl.appendChild(row);

    document.getElementById('toastContainer').appendChild(toastEl);
    const toast = new bootstrap.Toast(toastEl);
    toast.show();
    
    toastEl.addEventListener('hidden.bs.toast', () => toastEl.remove());
}

// Auto-show toast from session attribute if present
document.addEventListener('DOMContentLoaded', function() {
    const successMessage = document.getElementById('successMessage');
    const errorMessage = document.getElementById('errorMessage');
    
    if (successMessage && successMessage.textContent.trim()) {
        showToast(successMessage.textContent.trim(), 'success');
        successMessage.remove();
    }
    if (errorMessage && errorMessage.textContent.trim()) {
        showToast(errorMessage.textContent.trim(), 'error');
        errorMessage.remove();
    }

    // Ensure visible button-like controls have accessible labels.
    document.querySelectorAll('button, a.btn, [role="button"]').forEach(function (element) {
        if (!element.hasAttribute('aria-label')) {
            const label = (element.textContent || '').replace(/\s+/g, ' ').trim();
            if (label) {
                element.setAttribute('aria-label', label);
            }
        }
    });

    // Generic password visibility toggles for inputs mapped via data-target.
    document.querySelectorAll('[data-password-toggle]').forEach(function (toggleButton) {
        const targetSelector = toggleButton.getAttribute('data-target');
        if (!targetSelector) {
            return;
        }

        const passwordInput = document.querySelector(targetSelector);
        if (!passwordInput) {
            return;
        }

        toggleButton.addEventListener('mousedown', function (event) {
            event.preventDefault();
        });

        toggleButton.addEventListener('click', function () {
            const showing = passwordInput.type === 'text';
            passwordInput.type = showing ? 'password' : 'text';
            toggleButton.classList.toggle('active', !showing);
            toggleButton.setAttribute('aria-pressed', String(!showing));
            passwordInput.focus();
        });
    });
});


// ==================== FORM LOADING STATES ====================
// Disable form submission and show loading state
function disableFormOnSubmit(formSelector = 'form') {
    document.querySelectorAll(formSelector).forEach(form => {
        form.addEventListener('submit', function(e) {
            if (e.defaultPrevented || this.hasAttribute('data-confirm-form') || this.classList.contains('no-loading')) {
                return;
            }

            const submitBtn = this.querySelector('button[type="submit"]');
            if (submitBtn) {
                if (!submitBtn.dataset.originalHtml) {
                    submitBtn.dataset.originalHtml = submitBtn.innerHTML;
                }
                submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Processing...';
                submitBtn.disabled = true;
            }
        });
    });
}

// Call on page load
document.addEventListener('DOMContentLoaded', function() {
    disableFormOnSubmit('form');
});

// ==================== EXISTING CURSOR EFFECTS ====================
document.addEventListener('mousemove', function(e){
    const container = document.querySelector('.container-3d');
    if(!container) return;
    const rect = container.getBoundingClientRect();
    const cx = rect.left + rect.width/2;
    const cy = rect.top + rect.height/2;
    const dx = (e.clientX - cx) / rect.width;
    const dy = (e.clientY - cy) / rect.height;
    container.style.transform = `perspective(1000px) rotateX(${ -dy * 6 }deg) rotateY(${ dx * 6 }deg)`;
});

// reset transform when leaving
document.querySelectorAll('.container-3d').forEach(c => {
    c.addEventListener('mouseleave', () => {
        c.style.transform = '';
    });
});

// focus glow for inputs
document.querySelectorAll('.input-3d').forEach(el => {
    el.addEventListener('focus', ()=> el.style.boxShadow = '18px 18px 36px rgba(100,110,150,0.18), -12px -12px 20px rgba(255,255,255,0.9)');
    el.addEventListener('blur', ()=> el.style.boxShadow = '');
});

// Select category function for complaint registration
function selectCategory(element, categoryName) {
    // Remove active class from all category cards
    document.querySelectorAll('.category-card').forEach(card => {
        card.style.borderColor = '';
        card.style.boxShadow = '';
    });
    
    // Add active style to selected card
    element.style.borderColor = '#4f46e5';
    element.style.boxShadow = '0 0 15px rgba(79, 70, 229, 0.4)';
    
    // Set the hidden category field value
    document.getElementById('selectedCategory').value = categoryName;
}

// Preview image function for photo upload
function previewImage(input) {
    const preview = document.getElementById('preview');
    const previewDiv = document.getElementById('imagePreview');
    
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            preview.src = e.target.result;
            previewDiv.style.display = 'block';
        };
        reader.readAsDataURL(input.files[0]);
    } else {
        previewDiv.style.display = 'none';
    }
}

// Temporary required-field validation feedback used across forms.
(function () {
    const HIGHLIGHT_CLASS = 'required-temp-invalid';
    const MESSAGE_CLASS = 'required-fields-msg';
    const MESSAGE_TEXT = 'please fill all required fields.';
    const DISPLAY_MS = 2500;

    function removeMessage(form) {
        const oldMessage = form.querySelector('.' + MESSAGE_CLASS);
        if (oldMessage) {
            oldMessage.remove();
        }
    }

    function clearStaleHighlights(form) {
        form.querySelectorAll('.' + HIGHLIGHT_CLASS).forEach(function (field) {
            // Remove stale highlight once the value is present.
            if (!(field.validity && field.validity.valueMissing)) {
                field.classList.remove(HIGHLIGHT_CLASS);
            }
        });
    }

    function clearFeedback(form, fields, messageEl) {
        fields.forEach(function (field) {
            field.classList.remove(HIGHLIGHT_CLASS);
        });
        if (messageEl && messageEl.parentNode) {
            messageEl.parentNode.removeChild(messageEl);
        }
    }

    function showMessage(form) {
        removeMessage(form);
        const messageEl = document.createElement('div');
        messageEl.className = MESSAGE_CLASS;
        messageEl.textContent = MESSAGE_TEXT;
        form.insertBefore(messageEl, form.firstChild);
        return messageEl;
    }

    function findMissingRequiredFields(form) {
        return Array.prototype.filter.call(form.querySelectorAll('[required]'), function (field) {
            return field.willValidate && field.validity && field.validity.valueMissing;
        });
    }

    document.querySelectorAll('form').forEach(function (form) {
        const requiredFields = form.querySelectorAll('[required]');
        if (!requiredFields.length) {
            return;
        }

        form.setAttribute('novalidate', 'novalidate');
        clearStaleHighlights(form);

        form.addEventListener('submit', function (event) {
            removeMessage(form);
            clearStaleHighlights(form);

            const missingFields = findMissingRequiredFields(form);
            if (!missingFields.length) {
                // Ensure no stale red style remains when submitting valid data.
                form.querySelectorAll('.' + HIGHLIGHT_CLASS).forEach(function (field) {
                    field.classList.remove(HIGHLIGHT_CLASS);
                });
                return;
            }

            event.preventDefault();

            missingFields.forEach(function (field) {
                field.classList.add(HIGHLIGHT_CLASS);
            });

            const messageEl = showMessage(form);

            setTimeout(function () {
                clearFeedback(form, missingFields, messageEl);
            }, DISPLAY_MS);
        });

        requiredFields.forEach(function (field) {
            if (!(field.validity && field.validity.valueMissing)) {
                field.classList.remove(HIGHLIGHT_CLASS);
            }

            field.addEventListener('input', function () {
                field.classList.remove(HIGHLIGHT_CLASS);
            });
            field.addEventListener('change', function () {
                field.classList.remove(HIGHLIGHT_CLASS);
            });
            field.addEventListener('blur', function () {
                if (!(field.validity && field.validity.valueMissing)) {
                    field.classList.remove(HIGHLIGHT_CLASS);
                }
            });
        });
    });
})();
