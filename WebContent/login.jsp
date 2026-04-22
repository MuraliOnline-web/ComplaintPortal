<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String errorMsg = request.getParameter("error");
    String reason = request.getParameter("reason");

    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String homeHref = base + "/index.jsp";
    String userLoginHref = base + "/userLogin.jsp";
    String forgotPasswordHref = base + "/forgotPassword.jsp";
    String styleHref = base + "/assets/css/style.css";
    String scriptHref = base + "/assets/js/main.js";
    String logoHref = base + "/assets/images/logo.svg";
    String visualHref = base + "/assets/images/watertaps.jpg";
    try {
        if (application.getResource("/index.jsp") != null) homeHref = ctx + "/index.jsp";
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
    <title>Admin / Officer Login</title>
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
                linear-gradient(180deg, rgba(15, 23, 42, 0.32), rgba(15, 23, 42, 0.7)),
                url('<%= visualHref %>') center/cover;
            color: #fff;
            min-height: 100%;
            padding: 2rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        @media (max-width: 991.98px) {
            .auth-visual {
                padding: 1.5rem;
            }

            .auth-visual h1 {
                font-size: 1.75rem !important;
            }

            .auth-visual p {
                font-size: 0.9rem !important;
            }
        }

        .field-wrap input,
        .field-wrap select {
            padding-left: 2.5rem;
        }

        .field-wrap input.has-password-toggle {
            padding-right: 3rem;
        }

        .field-icon {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #64748b;
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
    <!-- Toast container for notifications -->
    <div id="toastContainer"></div>
    
    <!-- Hidden message divs -->
    <% 
        if ("1".equals(errorMsg)) {
            String hiddenErrorText = "Invalid email, role, or login credentials";
            if ("email_not_found".equals(reason)) {
                hiddenErrorText = "Email not found for Admin/Officer account";
            } else if ("role_mismatch".equals(reason)) {
                hiddenErrorText = "Role mismatch for the provided email";
            }
    %>
            <div id="errorMessage" style="display:none;"><%= hiddenErrorText %></div>
        <% } else if ("config".equals(errorMsg)) { %>
            <div id="errorMessage" style="display:none;">Database configuration error</div>
        <% } else if ("denied".equals(request.getParameter("denied"))) { %>
            <div id="errorMessage" style="display:none;">Access denied - Admin/Officer only</div>
        <% } %>
    
    <div class="container-fluid px-0">
        <div class="container py-3">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb small">
                    <li class="breadcrumb-item"><a href="<%= homeHref %>">Home</a></li>
                    <li class="breadcrumb-item active" aria-current="page">Login</li>
                </ol>
            </nav>
        </div>
        <div class="row g-0 min-vh-100">
            <div class="col-12 col-md-5">
                <div class="auth-visual">
                    <div>
                        <div class="d-flex align-items-center gap-2 mb-4">
                            <div class="rounded-4 bg-white d-inline-flex align-items-center justify-content-center" style="width:48px;height:48px;">
                                <img src="<%= logoHref %>" alt="Complaint Portal" class="img-fluid rounded-4">
                            </div>
                            <div>
                                <div class="fw-bold fs-5">Complaint Portal</div>
                                <div class="small text-white-50">Administrative control center</div>
                            </div>
                        </div>
                        <h1 class="display-5 fw-bold" style="line-height:1.05;">Manage complaints and supervise field resolution.</h1>
                        <p class="mt-3 mb-0 text-white-75" style="max-width: 26rem;">Admin and officer access is separate from citizen login so the workflow stays clear and secure.</p>
                    </div>
                    <div class="row g-3 mt-4">
                        <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3"><div class="small text-white-50">Role</div><div class="fw-semibold">Admin / Officer</div></div></div>
                        <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3"><div class="small text-white-50">Flow</div><div class="fw-semibold">Email + password</div></div></div>
                    </div>
                </div>
            </div>

            <div class="col-12 col-md-7 d-flex align-items-center justify-content-center p-3 p-lg-5">
                <div class="w-100" style="max-width: 560px;">
                    <div class="auth-card p-4 p-md-5">
                        <div class="d-flex align-items-center justify-content-between mb-3">
                            <div>
                                <h2 class="h3 fw-bold mb-1">Admin / Officer Login</h2>
                                <p class="text-secondary mb-0">Sign in to access internal complaint workflows.</p>
                            </div>
                        </div>

                        <div class="role-tabs mb-4">
                            <a class="role-tab text-center text-decoration-none" href="<%= userLoginHref %>">User Login</a>
                            <a class="role-tab active text-center text-decoration-none" href="<%= base %>/login.jsp">Admin / Officer Login</a>
                        </div>

                        <% if ("1".equals(errorMsg)) {
                            String detailedError = "Invalid email, role, or login credentials. Please try again.";
                            if ("email_not_found".equals(reason)) {
                                detailedError = "Email not found. Use the registered Admin/Officer email.";
                            } else if ("role_mismatch".equals(reason)) {
                                detailedError = "Role mismatch. Select the role that matches this email account.";
                            }
                        %>
                            <div class="alert alert-danger"><%= detailedError %></div>
                        <% } %>
                        <% if ("config".equals(errorMsg)) { %>
                            <div class="alert alert-danger">Database is not configured. Contact administrator.</div>
                        <% } %>
                        <% if ("1".equals(request.getParameter("denied"))) { %>
                            <div class="alert alert-warning">Access denied for your role. Only Admin/Officer can log in here.</div>
                        <% } %>

                        <form action="actions/LoginAction.jsp" method="post" class="row g-3">
                            <div class="col-12">
                                <label class="form-label fw-semibold">Role</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">▣</span>
                                    <select name="role" class="form-select form-select-lg" required>
                                        <option value="admin">Admin</option>
                                        <option value="officer">Officer</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Email</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">@</span>
                                    <input type="email" name="email" class="form-control form-control-lg" placeholder="you@example.com" required>
                                </div>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Password</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">🔒</span>
                                    <input id="adminOfficerPassword" type="password" name="password" class="form-control form-control-lg has-password-toggle" placeholder="Your password" required>
                                    <button type="button" class="password-toggle-btn" data-password-toggle data-target="#adminOfficerPassword" aria-label="Show or hide password" aria-pressed="false">&#128065;</button>
                                </div>
                            </div>

                            <div class="col-12 d-flex flex-wrap gap-2 justify-content-between align-items-center mt-2">
                                <button type="submit" class="btn btn-primary btn-lg">Login</button>
                                <div class="d-flex gap-2">
                                    <a href="<%= homeHref %>" class="btn btn-outline-secondary">Home</a>
                                    <a href="<%= forgotPasswordHref %>" class="btn btn-outline-primary">Problems logging in?</a>
                                </div>
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
