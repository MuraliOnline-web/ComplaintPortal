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
    <title>User Login</title>
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

        .auth-shell {
            min-height: 100vh;
        }

        .auth-visual {
            background:
                linear-gradient(180deg, rgba(15, 23, 42, 0.3), rgba(15, 23, 42, 0.68)),
                url('assets/images/ElectricWires.jpeg') center/cover;
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

        .auth-visual .badge-soft {
            background: rgba(255, 255, 255, 0.12);
            border: 1px solid rgba(255, 255, 255, 0.18);
            backdrop-filter: blur(12px);
        }

        .auth-panel {
            padding: 2rem;
        }

        .auth-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 28px;
            background: rgba(255, 255, 255, 0.85);
            box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
            overflow: hidden;
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

        .switch-pill {
            display: inline-flex;
            gap: 0.5rem;
            background: #f1f5f9;
            padding: 0.35rem;
            border-radius: 999px;
        }

        .switch-pill label {
            margin: 0;
            padding: 0.55rem 0.9rem;
            border-radius: 999px;
            cursor: pointer;
            font-weight: 600;
            color: #475569;
        }

        .switch-pill input:checked + span {
            background: #ffffff;
            color: #0f172a;
            box-shadow: 0 10px 20px rgba(15, 23, 42, 0.08);
        }

        .switch-pill span {
            display: inline-block;
            min-width: 84px;
            text-align: center;
            padding: 0.35rem 0.7rem;
            border-radius: 999px;
        }

        .input-icon {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #64748b;
        }

        .input-with-icon {
            padding-left: 2.5rem;
        }
    </style>
</head>
<body class="auth-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <!-- Toast container for notifications -->
    <div id="toastContainer"></div>
    
    <!-- Hidden message divs -->
    <% 
        String errorMsg = request.getParameter("error");
        if ("1".equals(errorMsg)) { %>
            <div id="errorMessage" style="display:none;">Invalid email/mobile or OTP verification failed</div>
        <% } else if ("required".equals(errorMsg)) { %>
            <div id="errorMessage" style="display:none;">Please login first to continue</div>
        <% } else if ("config".equals(errorMsg)) { %>
            <div id="errorMessage" style="display:none;">Database configuration error</div>
        <% } else if ("smtp".equals(request.getParameter("smtp"))) { %>
            <div id="errorMessage" style="display:none;">SMTP configuration error - email could not be sent</div>
        <% } %>
    
    <div class="auth-shell container-fluid px-0">
        <div class="container py-3">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb small">
                    <li class="breadcrumb-item"><a href="index.jsp">Home</a></li>
                    <li class="breadcrumb-item active" aria-current="page">User Login</li>
                </ol>
            </nav>
        </div>
        <div class="row g-0 min-vh-100">
            <div class="col-12 col-md-5">
                <div class="auth-visual">
                    <div>
                        <div class="d-flex align-items-center gap-2 mb-4">
                            <div class="rounded-4 bg-white d-inline-flex align-items-center justify-content-center" style="width:48px;height:48px;">
                                <img src="assets/images/logo.jpg" alt="Complaint Portal" class="img-fluid rounded-4">
                            </div>
                            <div>
                                <div class="fw-bold fs-5">Complaint Portal</div>
                                <div class="small text-white-50">Citizen-first issue reporting</div>
                            </div>
                        </div>
                        <h1 class="display-5 fw-bold" style="line-height:1.05;">Report issues. Track progress. Get closure.</h1>
                        <p class="mt-3 mb-0 text-white-75" style="max-width: 26rem;">A cleaner login experience for citizens, with OTP access by email or mobile and a direct path to your complaint dashboard.</p>
                    </div>
                    <div class="row g-3 mt-4">
                        <div class="col-6">
                            <div class="badge-soft rounded-4 p-3">
                                <div class="small text-white-50">Secure login</div>
                                <div class="fw-semibold">OTP verification</div>
                            </div>
                        </div>
                        <div class="col-6">
                            <div class="badge-soft rounded-4 p-3">
                                <div class="small text-white-50">Access by</div>
                                <div class="fw-semibold">Email or mobile</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-12 col-md-7 d-flex align-items-center justify-content-center p-3 p-lg-5">
                <div class="auth-panel w-100" style="max-width: 560px;">
                    <div class="auth-card p-4 p-md-5">
                        <% if ("1".equals(request.getParameter("required"))) { %>
                            <div class="alert alert-info">Please login first to continue.</div>
                        <% } %>
                        <% if ("1".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">Unable to find an account for the provided details.</div>
                        <% } %>
                        <% if ("config".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">Database is not configured. Contact administrator.</div>
                        <% } %>
                        <% if ("cfg".equals(request.getParameter("smtp"))) { %>
                            <div class="alert alert-danger">SMTP is not configured. Set email credentials in your environment or config file.</div>
                        <% } %>
                        <% if ("send".equals(request.getParameter("smtp"))) { %>
                            <div class="alert alert-danger">Unable to send OTP email. Please verify SMTP settings.</div>
                        <% } %>
                        <% if ("1".equals(request.getParameter("reset"))) { %>
                            <div class="alert alert-success">Password updated successfully. Please login.</div>
                        <% } %>

                        <div class="d-flex align-items-center justify-content-between mb-3">
                            <div>
                                <h2 class="h3 fw-bold mb-1">Welcome back</h2>
                                <p class="text-secondary mb-0">Sign in to continue to your citizen dashboard.</p>
                            </div>
                        </div>

                        <div class="role-tabs mb-4">
                            <a class="role-tab active text-center text-decoration-none" href="userLogin.jsp">User Login</a>
                            <a class="role-tab text-center text-decoration-none" href="login.jsp">Admin / Officer Login</a>
                        </div>

                        <form action="actions/UserLoginAction.jsp" method="post" class="space-y-4">
                            <div class="mb-3">
                                <label class="form-label fw-semibold">Login method</label>
                                <div class="switch-pill">
                                    <label>
                                        <input type="radio" name="loginMode" value="email" checked class="d-none">
                                        <span>Email</span>
                                    </label>
                                    <label>
                                        <input type="radio" name="loginMode" value="mobile" class="d-none">
                                        <span>Mobile</span>
                                    </label>
                                </div>
                            </div>

                            <div class="mb-3 position-relative">
                                <label class="form-label fw-semibold">Email address / Mobile number</label>
                                <span class="input-icon">@</span>
                                <input type="text" name="identifier" class="form-control form-control-lg input-with-icon" placeholder="Enter your email or mobile" required>
                            </div>

                            <button type="submit" class="btn btn-primary btn-lg w-100">Send OTP</button>

                            <div class="d-flex justify-content-between align-items-center mt-3 flex-wrap gap-2">
                                <a href="forgotPassword.jsp" class="text-decoration-none">Problems logging in?</a>
                                <a href="index.jsp" class="btn btn-outline-secondary">Home</a>
                            </div>

                            <div class="mt-4 text-center text-secondary">
                                New here? <a href="userRegister.jsp" class="fw-semibold text-decoration-none">Create account</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>
