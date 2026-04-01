<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
%>
<!DOCTYPE html>
<html>
<head>
    <title>User Registration</title>
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
        <h2>Create User Account</h2>
        <% if ("1".equals(request.getParameter("ok"))) { %>
            <div class="alert alert-success">Registration successful. Please login.</div>
        <% } %>
        <% if (request.getParameter("error") != null) { %>
            <div class="alert alert-error"><%= request.getParameter("error") %></div>
        <% } %>

        <form action="<%= base %>/actions/UserRegisterAction.jsp" method="post">
            <div class="form-group">
                <label>Full Name</label>
                <input type="text" name="name" class="form-control input-3d" required>
            </div>
            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" class="form-control input-3d" required>
            </div>
            <div class="form-group">
                <label>Mobile</label>
                <input type="text" name="mobile" class="form-control input-3d" required>
            </div>
            <div class="form-group">
                <label>City / Village</label>
                <input type="text" name="cityVillage" class="form-control input-3d" required>
            </div>
            <div class="form-group">
                <label>Password</label>
                <div class="password-wrap">
                    <input id="registerPassword" type="password" name="password" class="form-control input-3d" required>
                    <button id="registerEye" type="button" class="eye-toggle" aria-label="Show or hide password" title="Show or hide password">&#128065;</button>
                </div>
                <small style="display:block; margin-top:6px; color:#6b7280;">Your password should contains minimum 6 characters.</small>
            </div>
            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-3d">Register</button>
                <a href="<%= base %>/userLogin.jsp" class="btn btn-secondary btn-3d">User Login</a>
                <a href="<%= base %>/index.jsp" class="btn btn-secondary btn-3d">Home</a>
            </div>
        </form>
    </div>
    <script>
        (function () {
            const passwordInput = document.getElementById('registerPassword');
            const toggleButton = document.getElementById('registerEye');
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
