<!-- Track Complaint Result JSP (WebContent) -->
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String homeHref = base + "/index.jsp";
    String userDashboardHref = base + "/userDashboard.jsp";
    String trackComplaintHref = base + "/trackComplaint.jsp";
    String backHref = homeHref;
    String backLabel = "Back to Home";
    String styleHref = base + "/assets/css/style.css";
    String scriptHref = base + "/assets/js/main.js";
    String roadImageHref = base + "/assets/images/road.jpg";
    try {
        if (application.getResource("/index.jsp") != null) {
            homeHref = ctx + "/index.jsp";
        }
        if (application.getResource("/userDashboard.jsp") != null) {
            userDashboardHref = ctx + "/userDashboard.jsp";
        }
        if (application.getResource("/trackComplaint.jsp") != null) {
            trackComplaintHref = ctx + "/trackComplaint.jsp";
        }
        if (application.getResource("/assets/css/style.css") != null) {
            styleHref = ctx + "/assets/css/style.css";
        }
        if (application.getResource("/assets/js/main.js") != null) {
            scriptHref = ctx + "/assets/js/main.js";
        }
        if (application.getResource("/assets/images/road.jpg") != null) {
            roadImageHref = ctx + "/assets/images/road.jpg";
        }
    } catch (Exception ignore) {
        // Fall back to the computed base path.
    }

    String role = session.getAttribute("role") != null ? String.valueOf(session.getAttribute("role")) : "";
    if ("user".equalsIgnoreCase(role) && session.getAttribute("userId") != null) {
        backHref = userDashboardHref;
        backLabel = "Back to Dashboard";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Complaint Tracking Result</title>
    <link rel="stylesheet" href="<%= styleHref %>">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.result-page {
            min-height: 100vh;
            background:
                radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 30%),
                radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.1), transparent 32%),
                linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
        }

        .result-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 28px;
            background: rgba(255, 255, 255, 0.88);
            box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.35rem 0.75rem;
            border-radius: 999px;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .status-pending { background: #fef3c7; color: #92400e; }
        .status-solving { background: #dbeafe; color: #1d4ed8; }
        .status-solved,
        .status-resolved { background: #d1fae5; color: #047857; }

        .detail-box {
            border: 1px solid rgba(148, 163, 184, 0.18);
            border-radius: 18px;
            background: #ffffff;
        }
    </style>
</head>
<body class="result-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <main class="container py-4 py-lg-5">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb small">
                <li class="breadcrumb-item"><a href="<%= userDashboardHref %>">User Dashboard</a></li>
                <li class="breadcrumb-item"><a href="<%= trackComplaintHref %>">Track Complaint</a></li>
                <li class="breadcrumb-item active" aria-current="page">Result</li>
            </ol>
        </nav>
        <div class="result-card p-4 p-md-5">
            <div class="d-flex flex-wrap justify-content-between align-items-start gap-3 mb-4">
                <div>
                    <div class="text-uppercase small fw-semibold text-primary">Complaint details</div>
                    <h1 class="h2 fw-bold mb-2">Complaint Tracking Result</h1>
                    <p class="text-secondary mb-0">Review the latest status, notes, and attachments for your complaint.</p>
                </div>
                <a href="<%= base %>/trackComplaint.jsp" class="btn btn-outline-primary">Track Another Complaint</a>
            </div>

            <% if (request.getAttribute("complaintId") != null) { %>
                <div class="row g-4">
                    <div class="col-lg-8">
                        <div class="detail-box p-4 h-100">
                            <div class="row g-3">
                                <div class="col-md-6"><div class="text-secondary small">Complaint ID</div><div class="fw-semibold fs-5"><%= request.getAttribute("complaintId") %></div></div>
                                <div class="col-md-6"><div class="text-secondary small">Complaint Code</div><div class="fw-semibold fs-5"><%= request.getAttribute("complaintCode") != null ? request.getAttribute("complaintCode") : "-" %></div></div>
                                <div class="col-md-6"><div class="text-secondary small">Category</div><div class="fw-semibold"><%= request.getAttribute("category") %></div></div>
                                <div class="col-md-6"><div class="text-secondary small">Status</div><div><span class="status-badge status-<%= String.valueOf(request.getAttribute("status")).toLowerCase().replace(" ", "-") %>"><%= request.getAttribute("status") %></span></div></div>
                                <div class="col-12"><div class="text-secondary small">Description</div><div class="fw-semibold"><%= request.getAttribute("description") %></div></div>
                                <div class="col-12"><div class="text-secondary small">Address</div><div class="fw-semibold"><%= request.getAttribute("address") %></div></div>
                                <div class="col-md-6"><div class="text-secondary small">Created</div><div class="fw-semibold"><%= request.getAttribute("createdAt") %></div></div>
                                <div class="col-md-6"><div class="text-secondary small">Updated</div><div class="fw-semibold"><%= request.getAttribute("updatedAt") %></div></div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="detail-box p-4 h-100">
                            <h2 class="h5 fw-bold mb-3">Activity</h2>
                            <% if (request.getAttribute("officerNotes") != null) { %>
                                <div class="mb-3">
                                    <div class="text-secondary small">Officer Notes</div>
                                    <div><%= request.getAttribute("officerNotes") %></div>
                                </div>
                            <% } %>
                            <% if (request.getAttribute("photoPath") != null) { %>
                                <div class="mb-3">
                                    <div class="text-secondary small mb-2">Uploaded Photo</div>
                                    <img src="<%= request.getAttribute("photoPath") %>" alt="Complaint Photo" class="img-fluid rounded-4 border">
                                </div>
                            <% } %>
                            <% if (request.getAttribute("solvedPhotoPath") != null) { %>
                                <div>
                                    <div class="text-secondary small mb-2">Resolved Photo</div>
                                    <img src="<%= request.getAttribute("solvedPhotoPath") %>" alt="Resolved Photo" class="img-fluid rounded-4 border">
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            <% } else { %>
                <div class="alert alert-warning mb-4">
                    <h2 class="h5 fw-bold mb-1">No complaint found</h2>
                    <p class="mb-0">Please check your complaint ID and email address.</p>
                </div>
            <% } %>

            <div class="d-flex flex-wrap gap-2 mt-4">
                <a href="<%= trackComplaintHref %>" class="btn btn-primary">Track Another Complaint</a>
                <a href="<%= backHref %>" class="btn btn-outline-secondary"><%= backLabel %></a>
            </div>
        </div>
    </main>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="<%= scriptHref %>"></script>
</body>
</html>
