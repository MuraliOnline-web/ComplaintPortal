<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
%>
<!DOCTYPE html>
<html>
<head>
    <title>User Login</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        .no-tilt,
        .no-tilt:hover {
            transform: none !important;
        }
        .password-wrap {
            position: relative;
            display: flex;
            align-items: center;
        }
        .password-wrap input {
            width: 100%;
            padding-right: 52px;
            caret-color: #111827;
        }
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
        <h2>User Login (Email OTP)</h2>
        <% if ("1".equals(request.getParameter("required"))) { %>
            <div class="alert alert-info">Please login first to continue.</div>
        <% } %>
        <% if ("1".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">Invalid email or password.</div>
        <% } %>
        <% if ("config".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">Database is not configured. Contact administrator.</div>
        <% } %>
        <% if ("cfg".equals(request.getParameter("smtp"))) { %>
            <div class="alert alert-error">SMTP is not configured. Set smtp.user and smtp.password (Gmail App Password) in web.xml or environment variables.</div>
        <% } %>
        <% if ("send".equals(request.getParameter("smtp"))) { %>
            <div class="alert alert-error">Unable to send OTP email. Please verify SMTP credentials and Gmail App Password.</div>
        <% } %>
        <% if ("1".equals(request.getParameter("reset"))) { %>
            <div class="alert alert-success">Password updated successfully. Please login.</div>
        <% } %>

        <form action="<%= base %>/actions/UserLoginAction.jsp" method="post">
            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" class="form-control input-3d" required>
            </div>
            <div class="form-group">
                <label>Password</label>
                <div class="password-wrap">
                    <input id="loginPassword" type="password" name="password" class="form-control input-3d" required>
                    <button id="loginEye" type="button" class="eye-toggle" aria-label="Show or hide password" title="Show or hide password">&#128065;</button>
                </div>
            </div>
            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-3d">SignIn</button>
                <a href="<%= base %>/forgotPassword.jsp" class="btn btn-secondary btn-3d">Forgot Password</a>
                <a href="<%= base %>/index.jsp" class="btn btn-secondary btn-3d">Home</a>
            </div>
        </form>
    </div>
    <script>
        (function () {
            const passwordInput = document.getElementById('loginPassword');
            const toggleButton = document.getElementById('loginEye');
            if (!passwordInput || !toggleButton) return;
            toggleButton.addEventListener('mousedown', function (event) {
                event.preventDefault();
            });
            toggleButton.addEventListener('click', function () {
                const showing = passwordInput.type === 'text';
                passwordInput.type = showing ? 'password' : 'text';
                toggleButton.classList.toggle('active', !showing);
                passwordInput.focus();
            });
        })();
    </script>
    <script src="assets/js/main.js"></script>
</body>
</html>
