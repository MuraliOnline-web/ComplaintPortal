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
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Verify OTP</title>
    <link rel="stylesheet" href="assets/css/style.css">
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
                url('assets/images/ElectricWires.jpeg') center/cover;
            color: #fff;
            min-height: 100%;
            padding: 3rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }
    </style>
</head>
<body class="auth-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <div class="container-fluid px-0">
        <div class="container py-3">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb small">
                    <li class="breadcrumb-item"><a href="index.jsp">Home</a></li>
                    <li class="breadcrumb-item"><a href="userLogin.jsp">Login</a></li>
                    <li class="breadcrumb-item active" aria-current="page">Verify OTP</li>
                </ol>
            </nav>
        </div>
        <div class="row g-0 min-vh-100">
            <div class="col-lg-5 d-none d-lg-block">
                <div class="auth-visual">
                    <div>
                        <div class="d-flex align-items-center gap-2 mb-4">
                            <div class="rounded-4 bg-white d-inline-flex align-items-center justify-content-center" style="width:48px;height:48px;">
                                <img src="assets/images/logo.svg" alt="Complaint Portal" class="img-fluid rounded-4">
                            </div>
                            <div>
                                <div class="fw-bold fs-5">Complaint Portal</div>
                                <div class="small text-white-50">Verify login code</div>
                            </div>
                        </div>
                        <h1 class="display-5 fw-bold" style="line-height:1.05;">Confirm the OTP and continue to your dashboard.</h1>
                        <p class="mt-3 mb-0 text-white-75" style="max-width: 26rem;">The code was sent to your registered email and expires after a short window.</p>
                    </div>
                </div>
            </div>

            <div class="col-lg-7 d-flex align-items-center justify-content-center p-3 p-lg-5">
                <div class="w-100" style="max-width: 560px;">
                    <div class="auth-card p-4 p-md-5">
                        <h2 class="h3 fw-bold mb-1">Verify OTP</h2>
                        <p class="text-secondary mb-4">Enter the 6-digit code to complete sign in.</p>

                        <% if ("1".equals(request.getParameter("sent"))) { %>
                            <div class="alert alert-success">OTP sent to your registered email. It is valid for <b><%= expMinutes %> minutes</b>.</div>
                            <div class="alert alert-info">Expires in: <b id="otpExpiryCounter"></b></div>
                        <% } %>
                        <% if ("0".equals(request.getParameter("mail"))) { %>
                            <div class="alert alert-danger">Unable to send OTP email using the current SMTP settings.</div>
                        <% } %>
                        <% if ("1".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">Invalid or expired OTP.</div>
                        <% } %>
                        <% if ("db".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">Database is not configured. Contact administrator.</div>
                        <% } %>

                        <form action="<%= base %>/actions/VerifyOtpAction.jsp" method="post" class="row g-3">
                            <div class="col-12">
                                <label class="form-label fw-semibold">Enter OTP</label>
                                <input type="text" name="otp" class="form-control form-control-lg" maxlength="6" placeholder="6 digits" required>
                            </div>
                            <div class="col-12 d-flex flex-wrap gap-2 justify-content-between align-items-center mt-2">
                                <button type="submit" class="btn btn-primary btn-lg">Verify & Login</button>
                                <a href="<%= base %>/userLogin.jsp" class="btn btn-outline-secondary">Back</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
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
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>