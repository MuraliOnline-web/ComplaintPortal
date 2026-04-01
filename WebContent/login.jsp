<!-- Login JSP (WebContent) -->
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Admin / Officer Login</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" integrity="sha384-gH6tQd6rYt6v7s5FQ4u+Nw6mM2J+Z1oQXbQ9yKqNqCkzJ10c1qf6jv9vZ5GxXKbi" crossorigin="anonymous">
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
<body>
    <div class="container-3d no-tilt">
        <h2>Login - Admin / Officer</h2>
        <% if ("1".equals(request.getParameter("error"))) { %>
            <div class="alert alert-danger" role="alert">Invalid email, password, or role. Please try again.</div>
        <% } %>
        <% if ("config".equals(request.getParameter("error"))) { %>
            <div class="alert alert-danger" role="alert">Database is not configured. Contact administrator.</div>
        <% } %>
        <% if ("1".equals(request.getParameter("denied"))) { %>
            <div class="alert alert-warning" role="alert">Access denied for your role. Only Admin/Officer can log in here.</div>
        <% } %>
        <form action="actions/LoginAction.jsp" method="post">
            <div class="form-group">
                <label>Email ID:</label>
                <input type="email" name="email" class="form-control" required>
            </div>
            <div class="form-group">
                <label>Password:</label>
                <div class="password-wrap">
                    <input id="adminOfficerPassword" type="password" name="password" class="form-control" required>
                    <button id="adminOfficerEye" type="button" class="eye-toggle" aria-label="Show or hide password" title="Show or hide password">&#128065;</button>
                </div>
            </div>
            <div class="form-group">
                <label>Role:</label>
                <select name="role" class="form-control" required>
                    <option value="admin">Admin</option>
                    <option value="officer">Officer</option>
                </select>
            </div>
            <br>
            <button type="submit" class="btn btn-primary btn-3d">Login</button>
        </form>
        <br>
        <a href="index.jsp" class="btn btn-primary btn-3d">Back to Home</a>
    </div>
    <script>
        (function () {
            const passwordInput = document.getElementById('adminOfficerPassword');
            const toggleButton = document.getElementById('adminOfficerEye');
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
