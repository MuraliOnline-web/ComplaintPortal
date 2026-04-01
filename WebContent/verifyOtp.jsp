<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String expValue = request.getParameter("exp");
    int expMinutes = 14;
    try {
        if (expValue != null) expMinutes = Integer.parseInt(expValue);
    } catch (Exception ignore) {
        expMinutes = 14;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Verify OTP</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body class="bg-gradient">
    <div class="container-3d">
        <h2>Verify Email OTP</h2>
        <% if ("1".equals(request.getParameter("sent"))) { %>
            <div class="alert alert-success">OTP sent to your registered email. It is valid for <b><%= expMinutes %> minutes</b>.</div>
            <div class="alert alert-info">Expires in: <b id="otpExpiryCounter"></b></div>
        <% } %>
        <% if ("0".equals(request.getParameter("mail"))) { %>
            <div class="alert alert-error">
                Unable to send OTP email using current SMTP settings.
            </div>
        <% } %>
        <% if ("1".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">Invalid or expired OTP.</div>
        <% } %>
        <% if ("db".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">Database is not configured. Contact administrator.</div>
        <% } %>

        <form action="<%= base %>/actions/VerifyOtpAction.jsp" method="post">
            <div class="form-group">
                <label>Enter OTP</label>
                <input type="text" name="otp" class="form-control input-3d" maxlength="6" required>
            </div>
            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-3d">Verify & Login</button>
                <a href="<%= base %>/userLogin.jsp" class="btn btn-secondary btn-3d">Back</a>
            </div>
        </form>
    </div>
    <script>
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
