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
<html>
<head>
    <title>Reset Password</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        .password-wrap { position: relative; display: flex; align-items: center; }
        .password-wrap input { width: 100%; padding-right: 52px; }
        .eye-toggle {
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
<body class="bg-gradient">
    <div class="container-3d no-tilt">
        <h2>Reset Password</h2>
        <% if ("1".equals(request.getParameter("sent"))) { %>
            <div class="alert alert-success">OTP sent. Enter it below with a new password. OTP is valid for <b><%= expMinutes %> minutes</b>.</div>
            <div class="alert alert-info">Expires in: <b id="otpExpiryCounter"></b></div>
        <% } %>
        <% if ("1".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">Invalid or expired OTP.</div>
        <% } %>
        <% if ("db".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">Database is not configured. Contact administrator.</div>
        <% } %>
        <% if ("1".equals(request.getParameter("mismatch"))) { %>
            <div class="alert alert-error">Passwords do not match.</div>
        <% } %>
        <% if ("1".equals(request.getParameter("weak"))) { %>
            <div class="alert alert-error">Password must be at least 6 characters.</div>
        <% } %>
        <% if ("1".equals(request.getParameter("resent"))) { %>
            <div class="alert alert-success">A new OTP has been sent to your email. It is valid for <b><%= expMinutes %> minutes</b>.</div>
            <div class="alert alert-info">New OTP expires in: <b id="otpExpiryCounter"></b></div>
        <% } %>
        <% if ("cfg".equals(request.getParameter("smtp"))) { %>
            <div class="alert alert-error">SMTP is not configured. Set smtp.user and smtp.password (Gmail App Password) in web.xml or environment variables.</div>
        <% } %>
        <% if ("send".equals(request.getParameter("smtp"))) { %>
            <div class="alert alert-error">Unable to send OTP email. Verify SMTP credentials and Gmail App Password.</div>
        <% } %>

        <form action="<%= base %>/actions/ResetPasswordAction.jsp" method="post">
            <div class="form-group">
                <label>OTP</label>
                <input type="text" name="otp" maxlength="6" class="form-control input-3d" required>
            </div>
            <div class="form-group">
                <label>New Password</label>
                <div class="password-wrap">
                    <input id="newPassword" type="password" name="newPassword" class="form-control input-3d" required>
                    <button id="newPasswordEye" type="button" class="eye-toggle" aria-label="Show or hide new password">&#128065;</button>
                </div>
                <small style="display:block; margin-top:6px; color:#6b7280;">Your password should contains minimum 6 characters.</small>
            </div>
            <div class="form-group">
                <label>Confirm Password</label>
                <div class="password-wrap">
                    <input id="confirmPassword" type="password" name="confirmPassword" class="form-control input-3d" required>
                    <button id="confirmPasswordEye" type="button" class="eye-toggle" aria-label="Show or hide confirm password">&#128065;</button>
                </div>
            </div>
            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-3d">Update Password</button>
                <a id="resendOtpLink" href="<%= base %>/actions/ResendResetOtpAction.jsp" class="btn btn-secondary btn-3d" data-wait="<%= waitSeconds %>">Resend OTP</a>
                <a href="<%= base %>/userLogin.jsp" class="btn btn-secondary btn-3d">Back to Login</a>
            </div>
        </form>
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
    <script src="assets/js/main.js"></script>
</body>
</html>
