<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
%>
<!DOCTYPE html>
<html>
<head>
    <title>Forgot Password</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body class="bg-gradient">
    <div class="container-3d no-tilt">
        <h2>Forgot Password</h2>
        <% if ("1".equals(request.getParameter("sent"))) { %>
            <div class="alert alert-success">Reset OTP was sent to your email.</div>
        <% } %>
        <% if ("notfound".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">No account found for this email.</div>
        <% } %>
        <% if ("cfg".equals(request.getParameter("smtp"))) { %>
            <div class="alert alert-error">SMTP is not configured. Set smtp.user and smtp.password (Gmail App Password) in web.xml or environment variables.</div>
        <% } %>
        <% if ("send".equals(request.getParameter("smtp"))) { %>
            <div class="alert alert-error">Unable to send OTP email. Verify SMTP credentials and Gmail App Password.</div>
        <% } %>
        <% if (request.getParameter("error") != null && !"notfound".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error"><%= request.getParameter("error") %></div>
        <% } %>

        <form action="<%= base %>/actions/ForgotPasswordAction.jsp" method="post">
            <div class="form-group">
                <label>Registered Email</label>
                <input type="email" name="email" class="form-control input-3d" required>
            </div>
            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-3d">Send OTP</button>
                <a href="<%= base %>/userLogin.jsp" class="btn btn-secondary btn-3d">Back to Login</a>
            </div>
        </form>
    </div>
    <script src="assets/js/main.js"></script>
</body>
</html>
