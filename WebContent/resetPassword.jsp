<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String homeHref = base + "/index.jsp";
    String loginHref = base + "/userLogin.jsp";
    String styleHref = base + "/assets/css/style.css";
    String scriptHref = base + "/assets/js/main.js";
    String logoHref = base + "/assets/images/logo.svg";
    String visualHref = base + "/assets/images/Sanitation.jpg";
    try {
        if (application.getResource("/index.jsp") != null) homeHref = ctx + "/index.jsp";
        if (application.getResource("/userLogin.jsp") != null) loginHref = ctx + "/userLogin.jsp";
        if (application.getResource("/assets/css/style.css") != null) styleHref = ctx + "/assets/css/style.css";
        if (application.getResource("/assets/js/main.js") != null) scriptHref = ctx + "/assets/js/main.js";
        if (application.getResource("/assets/images/logo.svg") != null) logoHref = ctx + "/assets/images/logo.svg";
        if (application.getResource("/assets/images/Sanitation.jpg") != null) visualHref = ctx + "/assets/images/Sanitation.jpg";
    } catch (Exception ignore) {
        // Use computed fallbacks.
    }

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
    <link rel="stylesheet" href="<%= styleHref %>">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.auth-page {
            min-height: 100vh;
            background:
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
                url('<%= visualHref %>') center/cover;
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

        .password-wrap.active::after {
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
    <%@ include file="includes/ui-enhancements.jspf" %>
    <div id="toastContainer"></div>

    <div class="container-fluid px-0">
        <div class="container py-3">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb small">
                    <li class="breadcrumb-item"><a href="<%= homeHref %>">Home</a></li>
                    <li class="breadcrumb-item"><a href="<%= loginHref %>">Login</a></li>
                    <li class="breadcrumb-item active" aria-current="page">Reset Password</li>
                </ol>
            </nav>
        </div>

        <div class="row g-0 min-vh-100">
            <div class="col-lg-5 d-none d-lg-block">
                <div class="auth-visual">
                    <div>
                        <div class="d-flex align-items-center gap-2 mb-4">
                            <div class="rounded-4 bg-white d-inline-flex align-items-center justify-content-center" style="width:48px;height:48px;">
                                <img src="<%= logoHref %>" alt="Complaint Portal" class="img-fluid rounded-4">
                            </div>
                            <div>
                                <div class="fw-bold fs-5">Complaint Portal</div>
                                <div class="small text-white-50">Reset your password</div>
                            </div>
                        </div>
                        <h1 class="display-5 fw-bold" style="line-height:1.05;">Set a new password and keep your account secure.</h1>
                        <p class="mt-3 mb-0 text-white-75" style="max-width: 26rem;">Use the OTP sent to your email to confirm the reset and choose a new password.</p>
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

                        <input type="hidden" id="otpExpiryMinutes" value="<%= expMinutes %>">
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
                                    <a href="<%= loginHref %>" class="btn btn-outline-secondary">Back to Login</a>
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

            const expInput = document.getElementById('otpExpiryMinutes');
            const expFromPage = expInput ? parseInt(expInput.value || '14', 10) : 14;
            let remaining = (Number.isFinite(expFromPage) ? expFromPage : 14) * 60;
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
    <script src="<%= scriptHref %>"></script>
</body>
</html>
