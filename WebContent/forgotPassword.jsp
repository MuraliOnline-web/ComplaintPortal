<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String homeHref = base + "/index.jsp";
    String loginHref = base + "/userLogin.jsp";
    String styleHref = base + "/assets/css/style.css";
    String scriptHref = base + "/assets/js/main.js";
    String logoHref = base + "/assets/images/logo.svg";
    String visualHref = base + "/assets/images/watertaps.jpg";
    try {
        if (application.getResource("/index.jsp") != null) homeHref = ctx + "/index.jsp";
        if (application.getResource("/userLogin.jsp") != null) loginHref = ctx + "/userLogin.jsp";
        if (application.getResource("/assets/css/style.css") != null) styleHref = ctx + "/assets/css/style.css";
        if (application.getResource("/assets/js/main.js") != null) scriptHref = ctx + "/assets/js/main.js";
        if (application.getResource("/assets/images/logo.svg") != null) logoHref = ctx + "/assets/images/logo.svg";
        if (application.getResource("/assets/images/watertaps.jpg") != null) visualHref = ctx + "/assets/images/watertaps.jpg";
    } catch (Exception ignore) {
        // Use computed fallbacks.
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Forgot Password</title>
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

        .input-shell {
            position: relative;
        }

        .field-icon {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #64748b;
        }

        .field-wrap {
            padding-left: 2.5rem;
        }
    </style>
</head>
<body class="auth-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <div class="container-fluid px-0">
        <div class="container py-3">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb small">
                    <li class="breadcrumb-item"><a href="<%= homeHref %>">Home</a></li>
                    <li class="breadcrumb-item"><a href="<%= loginHref %>">Login</a></li>
                    <li class="breadcrumb-item active" aria-current="page">Forgot Password</li>
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
                                <div class="small text-white-50">Password recovery</div>
                            </div>
                        </div>
                        <h1 class="display-5 fw-bold" style="line-height:1.05;">Recover access with a one-time code.</h1>
                        <p class="mt-3 mb-0 text-white-75" style="max-width: 26rem;">We will send a reset OTP to the email address already registered with your account.</p>
                    </div>
                    <div class="row g-3 mt-4">
                        <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3"><div class="small text-white-50">Step 1</div><div class="fw-semibold">Send OTP</div></div></div>
                        <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3"><div class="small text-white-50">Step 2</div><div class="fw-semibold">Reset password</div></div></div>
                    </div>
                </div>
            </div>

            <div class="col-lg-7 d-flex align-items-center justify-content-center p-3 p-lg-5">
                <div class="w-100" style="max-width: 560px;">
                    <div class="auth-card p-4 p-md-5">
                        <h2 class="h3 fw-bold mb-1">Forgot password</h2>
                        <p class="text-secondary mb-4">Send a reset code to your registered email address.</p>

                        <% if ("1".equals(request.getParameter("sent"))) { %>
                            <div class="alert alert-success">Reset OTP was sent to your email.</div>
                        <% } %>
                        <% if ("notfound".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">No account found for this email.</div>
                        <% } %>
                        <% if ("cfg".equals(request.getParameter("smtp"))) { %>
                            <div class="alert alert-danger">SMTP is not configured. Set smtp.user and smtp.password in your environment or config file.</div>
                        <% } %>
                        <% if ("send".equals(request.getParameter("smtp"))) { %>
                            <div class="alert alert-danger">Unable to send OTP email. Verify SMTP credentials.</div>
                        <% } %>
                        <% if (request.getParameter("error") != null && !"notfound".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger"><%= request.getParameter("error") %></div>
                        <% } %>

                        <form action="<%= base %>/actions/ForgotPasswordAction.jsp" method="post" class="row g-3">
                            <div class="col-12">
                                <label class="form-label fw-semibold">Registered Email</label>
                                <div class="input-shell">
                                    <span class="field-icon">@</span>
                                    <input type="email" name="email" class="form-control form-control-lg field-wrap" placeholder="you@example.com" required>
                                </div>
                            </div>
                            <div class="col-12 d-flex flex-wrap gap-2 justify-content-between align-items-center mt-2">
                                <button type="submit" class="btn btn-primary btn-lg">Send OTP</button>
                                <a href="<%= loginHref %>" class="btn btn-outline-secondary">Back to Login</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="<%= scriptHref %>"></script>
</body>
</html>
