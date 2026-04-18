<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>User Registration</title>
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
                linear-gradient(180deg, rgba(15, 23, 42, 0.34), rgba(15, 23, 42, 0.7)),
                url('assets/images/Sanitation.jpg') center/cover;
            color: #fff;
            min-height: 100%;
            padding: 3rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .field-icon {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #64748b;
        }

        .field-wrap input {
            padding-left: 2.5rem;
        }

        .field-wrap input.has-password-toggle {
            padding-right: 3rem;
        }

        .password-toggle-btn {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            border: 0;
            background: transparent;
            color: #64748b;
            width: 28px;
            height: 28px;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 2;
            line-height: 1;
        }

        .password-toggle-btn.active::after {
            content: '/';
            position: absolute;
            left: 7px;
            top: -1px;
            font-size: 18px;
            pointer-events: none;
        }

        .role-tabs {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.5rem;
            background: #e2e8f0;
            padding: 0.35rem;
            border-radius: 18px;
        }

        .role-tab {
            border: 0;
            border-radius: 14px;
            background: transparent;
            padding: 0.8rem 1rem;
            font-weight: 700;
            color: #475569;
        }

        .role-tab.active {
            background: #ffffff;
            color: #0f172a;
            box-shadow: 0 12px 24px rgba(15, 23, 42, 0.08);
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
                    <li class="breadcrumb-item active" aria-current="page">Register</li>
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
                                <div class="small text-white-50">A cleaner route to civic support</div>
                            </div>
                        </div>
                        <h1 class="display-5 fw-bold" style="line-height:1.05;">Create your account and start filing complaints.</h1>
                        <p class="mt-3 mb-0 text-white-75" style="max-width: 26rem;">Register once, then use OTP login to access your dashboard, complaint history, and service updates.</p>
                    </div>
                    <div class="row g-3 mt-4">
                        <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3 backdrop-blur"><div class="small text-white-50">Access</div><div class="fw-semibold">User dashboard</div></div></div>
                        <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3 backdrop-blur"><div class="small text-white-50">Flow</div><div class="fw-semibold">Register → OTP login</div></div></div>
                    </div>
                </div>
            </div>

            <div class="col-lg-7 d-flex align-items-center justify-content-center p-3 p-lg-5">
                <div class="w-100" style="max-width: 640px;">
                    <div class="auth-card p-4 p-md-5">
                        <div class="d-flex align-items-center justify-content-between mb-3">
                            <div>
                                <h2 class="h3 fw-bold mb-1">Create your account</h2>
                                <p class="text-secondary mb-0">Join the complaint portal in a few steps.</p>
                            </div>
                        </div>

                        <div class="role-tabs mb-4">
                            <a class="role-tab text-center text-decoration-none" href="userLogin.jsp">User Login</a>
                            <a class="role-tab active text-center text-decoration-none" href="userRegister.jsp">Get Started</a>
                        </div>

                        <% if ("1".equals(request.getParameter("ok"))) { %>
                            <div class="alert alert-success">Registration successful. Please login.</div>
                        <% } %>
                        <% if (request.getParameter("error") != null) { %>
                            <div class="alert alert-danger"><%= request.getParameter("error") %></div>
                        <% } %>

                        <form action="actions/UserRegisterAction.jsp" method="post" class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Full Name</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">👤</span>
                                    <input type="text" name="name" class="form-control form-control-lg" placeholder="Your full name" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Email</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">@</span>
                                    <input type="email" name="email" class="form-control form-control-lg" placeholder="you@example.com" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Mobile</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">☎</span>
                                    <input type="text" name="mobile" class="form-control form-control-lg" placeholder="9876543210" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">City / Village</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">⌂</span>
                                    <input type="text" name="cityVillage" class="form-control form-control-lg" placeholder="Your locality" required>
                                </div>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Password</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">🔒</span>
                                    <input id="userRegisterPassword" type="password" name="password" class="form-control form-control-lg has-password-toggle" placeholder="At least 6 characters" required>
                                    <button type="button" class="password-toggle-btn" data-password-toggle data-target="#userRegisterPassword" aria-label="Show or hide password" aria-pressed="false">&#128065;</button>
                                </div>
                            </div>

                            <div class="col-12 d-flex flex-wrap gap-2 justify-content-between align-items-center mt-2">
                                <button type="submit" class="btn btn-primary btn-lg">Register</button>
                                <div class="d-flex gap-2">
                                    <a href="userLogin.jsp" class="btn btn-outline-primary">Login</a>
                                    <a href="index.jsp" class="btn btn-outline-secondary">Home</a>
                                </div>
                            </div>
                        </form>
                    </div>
                    <div class="text-center mt-3 text-secondary">
                        Already a member? <a href="userLogin.jsp" class="fw-semibold text-decoration-none">Login</a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>