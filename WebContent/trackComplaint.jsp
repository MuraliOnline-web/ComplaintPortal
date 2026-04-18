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
    <title>Track Complaint</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.form-page {
            min-height: 100vh;
            background:
                radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 30%),
                radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.1), transparent 32%),
                linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
        }

        .page-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 28px;
            background: rgba(255, 255, 255, 0.88);
            box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
            overflow: hidden;
        }

        .hero-side {
            background:
                linear-gradient(180deg, rgba(15, 23, 42, 0.32), rgba(15, 23, 42, 0.68)),
                url('assets/images/road.jpg') center/cover;
            color: #fff;
            min-height: 100%;
            padding: 2.5rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }
    </style>
</head>
<body class="form-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <nav class="navbar navbar-expand-lg bg-white bg-opacity-75 backdrop-blur-sm sticky-top border-bottom border-light-subtle">
        <div class="container py-2">
            <a class="navbar-brand fw-bold d-flex align-items-center gap-2" href="index.jsp">
                <img src="assets/images/logo.jpg" alt="Complaint Portal" style="width:40px;height:40px;border-radius:12px;object-fit:cover;">
                <span>Complaint Portal</span>
            </a>
            <div class="ms-auto d-flex gap-2">
                <a href="userDashboard.jsp" class="btn btn-outline-primary">Dashboard</a>
                <a href="actions/LogoutAction.jsp" class="btn btn-outline-danger" data-confirm-logout data-confirm-message="You are about to log out of your account." data-logout-url="actions/LogoutAction.jsp">Logout</a>
            </div>
        </div>
    </nav>

    <main class="container py-4 py-lg-5">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb small">
                <li class="breadcrumb-item"><a href="index.jsp">Home</a></li>
                <li class="breadcrumb-item"><a href="userDashboard.jsp">Dashboard</a></li>
                <li class="breadcrumb-item active" aria-current="page">Track Complaint</li>
            </ol>
        </nav>
        <div class="page-card">
            <div class="row g-0">
                <div class="col-lg-4 d-none d-lg-block">
                    <div class="hero-side">
                        <div>
                            <div class="small text-white-50 text-uppercase fw-semibold">Track complaint</div>
                            <h1 class="display-6 fw-bold mt-2" style="line-height:1.05;">Check the current status of any complaint you filed.</h1>
                            <p class="mt-3 mb-0 text-white-75">Use the complaint code for the fastest lookup, or use the complaint ID if you already have it.</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-8">
                    <div class="p-4 p-md-5">
                        <div class="d-flex align-items-start justify-content-between flex-wrap gap-3 mb-4">
                            <div>
                                <h2 class="h3 fw-bold mb-1">Track Your Complaint</h2>
                                <p class="text-secondary mb-0">Search by complaint code or complaint ID together with your email address.</p>
                            </div>
                            <a href="userDashboard.jsp" class="btn btn-outline-secondary">Back to Dashboard</a>
                        </div>

                        <% if ("1".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">Please enter valid complaint details to continue.</div>
                        <% } %>
                        <% if ("db".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">Database is not configured. Please contact support.</div>
                        <% } %>
                        <% if ("notfound".equals(request.getParameter("error"))) { %>
                            <div class="alert alert-danger">No complaint found for the provided details.</div>
                        <% } %>

                        <form action="<%= base %>/actions/TrackComplaintAction.jsp" method="post" class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Complaint Code</label>
                                <input type="text" name="code" class="form-control form-control-lg" placeholder="CMP-20260418-ABC123">
                                <div class="text-secondary small mt-1">Recommended for the quickest search.</div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Complaint ID</label>
                                <input type="number" name="complaintId" class="form-control form-control-lg" placeholder="Numeric ID">
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Registered Email</label>
                                <input type="email" name="email" class="form-control form-control-lg" placeholder="you@example.com" required>
                            </div>
                            <div class="col-12 d-flex flex-wrap gap-2 justify-content-between align-items-center mt-2">
                                <button type="submit" class="btn btn-primary btn-lg">Track Complaint</button>
                                <a href="index.jsp" class="btn btn-outline-secondary">Home</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>
