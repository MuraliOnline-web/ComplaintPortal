<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String waitValue = request.getParameter("wait");
    String expValue = request.getParameter("exp");
    int waitSeconds = 0;
    int expMinutes = 14;
    try {
        if (waitValue != null) waitSeconds = Integer.parseInt(waitValue);
    } catch (Exception ignore) {
        waitSeconds = 0;
    }
    try {
        if (expValue != null) expMinutes = Integer.parseInt(expValue);
    } catch (Exception ignore) {
        expMinutes = 14;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Reset Password</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    </style>
</head>
<body class="auth-page">
    <!-- Toast container for notifications -->
    <div id="toastContainer"></div>
    
    <nav class="navbar navbar-expand-lg bg-white bg-opacity-75 backdrop-blur-sm sticky-top border-bottom border-light-subtle">
                radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 30%),
                radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.1), transparent 32%),
                linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
        }

        .auth-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 28px;
            background: rgba(255, 255, 255, 0.88);
            box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
            overflow: hidden;
        }

        .auth-visual {
            background:
                linear-gradient(180deg, rgba(15, 23, 42, 0.32), rgba(15, 23, 42, 0.68)),
                url('assets/images/Sanitation.jpg') center/cover;
            color: #fff;
            min-height: 100%;
            padding: 3rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .password-wrap {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            border: none;
            background: transparent;
            cursor: pointer;
            font-size: 18px;
            line-height: 1;
            width: 28px;
            height: 28px;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 2;
        }

        .eye-toggle.active::after {
            content: '/';
            position: absolute;
            left: 6px;
            top: -1px;
            font-size: 18px;
            pointer-events: none;
        }
    </style>
</head>
<body class="auth-page">
    <div class="container-fluid px-0">
        <div class="row g-0 min-vh-100">
            <div class="col-lg-5 d-none d-lg-block">
                <div class="auth-visual">
                    <div>
                        <div class="d-flex align-items-center gap-2 mb-4">
                            <div class="rounded-4 bg-white d-inline-flex align-items-center justify-content-center" style="width:48px;height:48px;">
                                <img src="assets/images/logo.jpg" alt="Complaint Portal" class="img-fluid rounded-4">
                            </div>
                            <div>
                                <div class="fw-bold fs-5">Complaint Portal</div>
                                <div class="small text-white-50">Reset your password</div>
                            </div>
                        </div>
                        <h1 class="display-5 fw-bold" style="line-height:1.05;">Set a new password and keep your account secure.</h1>
                        <p class="mt-3 mb-0 text-white-75" style="max-width: 26rem;">Use the OTP sent to your email to confirm the reset and choose a new password.</p>
                    </div>
                    <div class="row g-3 mt-4">
                        <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3"><div class="small text-white-50">Code</div><div class="fw-semibold">OTP verification</div></div></div>
                        <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3"><div class="small text-white-50">Password</div><div class="fw-semibold">At least 6 chars</div></div></div>
                    </div>
                </div>
            </div>

            <div class="col-lg-7 d-flex align-items-center justify-content-center p-3 p-lg-5">
                <div class="w-100" style="max-width: 640px;">
                    <div class="auth-card p-4 p-md-5">
                        <h2 class="h3 fw-bold mb-1">Reset password</h2>
                        <p class="text-secondary mb-4">Enter the OTP and choose a new password.</p>

                        <% if ("1".equals(request.getParameter("sent"))) { %>
                            <div class="alert alert-success">OTP sent. Enter it below with a new password. OTP is valid for <b><%= expMinutes %> minutes</b>.</div>
                            <div class="alert alert-info">Expires in: <b id="otpExpiryCounter"></b></div>
                        <% } %>
                        <% if ("1".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">Invalid or expired OTP.</div>
                        <% } %>
                        <% if ("db".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">Database is not configured. Contact administrator.</div>
                        <% } %>
                        <% if ("1".equals(request.getParameter("mismatch"))) { %>
                            <div class="alert alert-danger">Passwords do not match.</div>
                        <% } %>
                        <% if ("1".equals(request.getParameter("weak"))) { %>
                            <div class="alert alert-danger">Password must be at least 6 characters.</div>
                        <% } %>
                        <% if ("1".equals(request.getParameter("resent"))) { %>
                            <div class="alert alert-success">A new OTP has been sent. It is valid for <b><%= expMinutes %> minutes</b>.</div>
                            <div class="alert alert-info">New OTP expires in: <b id="otpExpiryCounter"></b></div>
                        <% } %>
                        <% if ("cfg".equals(request.getParameter("smtp"))) { %>
                            <div class="alert alert-danger">SMTP is not configured. Set smtp.user and smtp.password in your environment or config file.</div>
                        <% } %>
                        <% if ("send".equals(request.getParameter("smtp"))) { %>
                            <div class="alert alert-danger">Unable to send OTP email. Verify SMTP credentials.</div>
                        <% } %>

                        <form action="<%= base %>/actions/ResetPasswordAction.jsp" method="post" class="row g-3">
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">OTP</label>
                                <input type="text" name="otp" maxlength="6" class="form-control form-control-lg" placeholder="6 digits" required>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">New Password</label>
                                <div class="position-relative">
                                    <input id="newPassword" type="password" name="newPassword" class="form-control form-control-lg" placeholder="New password" required>
                                    <button id="newPasswordEye" type="button" class="password-wrap" aria-label="Show or hide new password">&#128065;</button>
                                </div>
                                <small class="text-secondary d-block mt-2">Your password should contain at least 6 characters.</small>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Confirm Password</label>
                                <div class="position-relative">
                                    <input id="confirmPassword" type="password" name="confirmPassword" class="form-control form-control-lg" placeholder="Repeat password" required>
                                    <button id="confirmPasswordEye" type="button" class="password-wrap" aria-label="Show or hide confirm password">&#128065;</button>
                                </div>
                            </div>
                            <div class="col-12 d-flex flex-wrap gap-2 justify-content-between align-items-center mt-2">
                                <button type="submit" class="btn btn-primary btn-lg">Update Password</button>
                                <div class="d-flex gap-2 flex-wrap">
                                    <a id="resendOtpLink" href="<%= base %>/actions/ResendResetOtpAction.jsp" class="btn btn-outline-primary" data-wait="<%= waitSeconds %>">Resend OTP</a>
                                    <a href="<%= base %>/userLogin.jsp" class="btn btn-outline-secondary">Back to Login</a>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function bindEye(passwordId, eyeId) {
            const passwordInput = document.getElementById(passwordId);
            const toggleButton = document.getElementById(eyeId);
            if (!passwordInput || !toggleButton) return;
            toggleButton.addEventListener('mousedown', function (event) { event.preventDefault(); });
            toggleButton.addEventListener('click', function () {
                const showing = passwordInput.type === 'text';
                passwordInput.type = showing ? 'password' : 'text';
                toggleButton.classList.toggle('active', !showing);
                passwordInput.focus();
            });
        }
        bindEye('newPassword', 'newPasswordEye');
        bindEye('confirmPassword', 'confirmPasswordEye');

        (function () {
            const resendLink = document.getElementById('resendOtpLink');
            if (!resendLink) return;

            let wait = parseInt(resendLink.getAttribute('data-wait') || '0', 10);
            if (!Number.isFinite(wait) || wait <= 0) return;

            resendLink.style.pointerEvents = 'none';
            resendLink.style.opacity = '0.6';
            resendLink.textContent = 'Resend OTP (' + wait + 's)';

            const timer = setInterval(function () {
                wait -= 1;

                if (wait > 0) {
                    resendLink.textContent = 'Resend OTP (' + wait + 's)';
                    return;
                }

                clearInterval(timer);
                resendLink.style.pointerEvents = 'auto';
                resendLink.style.opacity = '1';
                resendLink.textContent = 'Resend OTP';
            }, 1000);
        })();

        (function () {
            const counter = document.getElementById('otpExpiryCounter');
            if (!counter) return;

            let remaining = <%= expMinutes %> * 60;
            const render = function () {
                const m = Math.floor(remaining / 60);
                const s = remaining % 60;
                counter.textContent = String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
            };

            render();
            const timer = setInterval(function () {
                remaining -= 1;
                if (remaining <= 0) {
                    remaining = 0;
                    render();
                    clearInterval(timer);
                    return;
                }
                render();
            }, 1000);
        })();
    </script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>
