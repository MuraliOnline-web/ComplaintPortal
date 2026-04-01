<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Complaint Portal - Home</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" integrity="sha384-gH6tQd6rYt6v7s5FQ4u+Nw6mM2J+Z1oQXbQ9yKqNqCkzJ10c1qf6jv9vZ5GxXKbi" crossorigin="anonymous">
</head>
<body>
    <%
        String flashMessage = null;
        String flashType = null;
        if (session != null) {
            Object fm = session.getAttribute("flashMessage");
            Object ft = session.getAttribute("flashType");
            if (fm != null) {
                flashMessage = String.valueOf(fm);
                flashType = (ft == null) ? "info" : String.valueOf(ft);
                session.removeAttribute("flashMessage");
                session.removeAttribute("flashType");
            }
        }
    %>
    <nav class="navbar navbar-expand-lg navbar-light bg-light px-3">
        <a class="navbar-brand" href="index.jsp">Complaint Portal</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navMenu" aria-controls="navMenu" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navMenu">
            <ul class="navbar-nav me-auto">
                <% if (session != null && session.getAttribute("role") != null) { 
                       String _role = String.valueOf(session.getAttribute("role"));
                       String dashHref = "admin".equalsIgnoreCase(_role) ? "adminDashboard.jsp" : ("officer".equalsIgnoreCase(_role) ? "officerDashboard.jsp" : "userDashboard.jsp"); %>
                    <li class="nav-item"><a class="nav-link" href="<%= dashHref %>">Dashboard</a></li>
                <% } %>
            </ul>
            <ul class="navbar-nav ms-auto">
                <% if (session != null && session.getAttribute("role") != null) { %>
                    <li class="nav-item"><span class="navbar-text me-2">Welcome, <%= session.getAttribute("userName") != null ? session.getAttribute("userName") : session.getAttribute("role") %></span></li>
                    <li class="nav-item"><a class="btn btn-outline-danger btn-sm" href="actions/LogoutAction.jsp">Logout</a></li>
                <% } else { %>
                    <li class="nav-item me-2"><a class="btn btn-outline-primary btn-sm" href="userRegister.jsp">User Register</a></li>
                    <li class="nav-item me-2"><a class="btn btn-primary btn-sm" href="userLogin.jsp">User Login</a></li>
                    <li class="nav-item"><a class="btn btn-secondary btn-sm" href="login.jsp">Admin/Officer Login</a></li>
                <% } %>
            </ul>
        </div>
    </nav>

    <div class="px-3 pt-3">
        <% if (flashMessage != null) { %>
            <div class="alert alert-<%= flashType %> auto-dismiss-notification" role="alert"><%= flashMessage %></div>
        <% } %>
    </div>

    <div class="container-3d mt-4">
        <header class="mb-4 text-center">
            <img src="assets/images/logo.jpg" alt="Logo" class="logo">
        </header>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-kQTa9d6k0C2eG2qGJ4d2w8eQmR0m+0+Yy0K8c2r8Z9ZQK7Q0tZQyF1rQKj7Yh0rN" crossorigin="anonymous"></script>
    <script>
        (function () {
            const notifications = document.querySelectorAll('.auto-dismiss-notification');
            notifications.forEach(function (el) {
                el.style.transition = 'opacity 0.4s ease';
                setTimeout(function () {
                    el.style.opacity = '0';
                    setTimeout(function () {
                        if (el && el.parentNode) {
                            el.parentNode.removeChild(el);
                        }
                    }, 450);
                }, 2500);
            });
        })();
    </script>
</body>
</html>
