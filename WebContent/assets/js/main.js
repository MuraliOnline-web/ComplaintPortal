// main.js - subtle cursor-aware interactions for inputs and buttons
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
