<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="org.apache.taglibs.standard.tag.rt.core.*" %>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String dashboardHref = base + "/userDashboard.jsp";
    String registerComplaintHref = base + "/registerComplaint.jsp";
    String styleHref = base + "/assets/css/style.css";
    String scriptHref = base + "/assets/js/main.js";
    try {
        if (application.getResource("/userDashboard.jsp") != null) dashboardHref = ctx + "/userDashboard.jsp";
        if (application.getResource("/registerComplaint.jsp") != null) registerComplaintHref = ctx + "/registerComplaint.jsp";
        if (application.getResource("/assets/css/style.css") != null) styleHref = ctx + "/assets/css/style.css";
        if (application.getResource("/assets/js/main.js") != null) scriptHref = ctx + "/assets/js/main.js";
    } catch (Exception ignore) {
        // Keep default path
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Complaint Registered</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="<%= styleHref %>">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.success-page {
            min-height: 100vh;
            background:
                radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 30%),
                radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.1), transparent 32%),
                linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
        }

        .success-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 28px;
            background: rgba(255, 255, 255, 0.9);
            box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
            overflow: hidden;
        }
    </style>
</head>
<body class="success-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <main class="container py-4 py-lg-5">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb small justify-content-center">
                <li class="breadcrumb-item"><a href="<%= dashboardHref %>">User Dashboard</a></li>
                <li class="breadcrumb-item active" aria-current="page">Complaint Registered</li>
            </ol>
        </nav>
        <div class="success-card p-4 p-md-5 text-center mx-auto" style="max-width: 760px;">
            <div class="mb-4">
                <div class="mx-auto mb-3 rounded-circle d-inline-flex align-items-center justify-content-center text-white fw-bold" style="width:72px;height:72px;background:linear-gradient(135deg,#4f46e5,#0ea5e9);font-size:2rem;">✓</div>
                <div class="text-uppercase small fw-semibold text-primary">Complaint submitted</div>
                <h1 class="h2 fw-bold mb-2">Complaint Registered Successfully!</h1>
                <p class="text-secondary mb-0">Your complaint has been received. Keep the details below for tracking.</p>
            </div>

            <div class="row g-3 text-start mb-4">
                <div class="col-md-4"><div class="bg-white border rounded-4 p-3 h-100"><div class="text-secondary small">Complaint ID</div><div class="fw-bold fs-5"><%= request.getParameter("id") != null ? request.getParameter("id") : "" %></div></div></div>
                <div class="col-md-4"><div class="bg-white border rounded-4 p-3 h-100"><div class="text-secondary small">Complaint Code</div><div class="fw-bold fs-5"><%= request.getParameter("code") != null ? request.getParameter("code") : "" %></div></div></div>
                <div class="col-md-4"><div class="bg-white border rounded-4 p-3 h-100"><div class="text-secondary small">Submitted by</div><div class="fw-bold fs-5"><%= request.getParameter("name") != null ? request.getParameter("name") : "User" %></div></div></div>
            </div>

            <p class="text-secondary mb-4">We will update you once it is resolved. Use the complaint code or ID to track progress from your dashboard.</p>

            <div class="d-flex flex-wrap justify-content-center gap-2">
                <a class="btn btn-primary btn-lg" href="<%= dashboardHref %>">Go to Dashboard</a>
                <a class="btn btn-outline-primary btn-lg" href="<%= registerComplaintHref %>">Register another complaint</a>
            </div>
        </div>
    </main>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="<%= scriptHref %>"></script>
</body>
</html>
