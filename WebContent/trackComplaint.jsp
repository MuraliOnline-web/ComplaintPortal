<!-- Track Complaint JSP (WebContent) -->
 <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Track Complaint</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" integrity="sha384-gH6tQd6rYt6v7s5FQ4u+Nw6mM2J+Z1oQXbQ9yKqNqCkzJ10c1qf6jv9vZ5GxXKbi" crossorigin="anonymous">
</head>
<body>
    <div class="container-3d">
        <h2>Track Your Complaint</h2>
        <% if ("1".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">Please enter valid complaint details to continue.</div>
        <% } %>
        <% if ("db".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">Database is not configured. Please contact support.</div>
        <% } %>
        <% if ("notfound".equals(request.getParameter("error"))) { %>
            <div class="alert alert-error">No complaint found for the provided details.</div>
        <% } %>
        <form action="actions/TrackComplaintAction.jsp" method="post">
            <div class="form-group">
                <label>Complaint Code (recommended):</label>
                <input type="text" name="code" class="form-control" placeholder="e.g., CMP-20250922-ABC123">
                <small class="text-muted">You can enter either Complaint Code or Complaint ID.</small>
            </div>
            <div class="form-group">
                <label>Complaint ID (optional):</label>
                <input type="number" name="complaintId" class="form-control" placeholder="Numeric ID">
            </div>
            <div class="form-group">
                <label>Registered Email:</label>
                <input type="email" name="email" class="form-control" required>
            </div>
            <br>
            <button type="submit" class="btn btn-primary btn-3d">Track Complaint</button>
            <a href="userDashboard.jsp" class="btn btn-secondary btn-3d">Back to Dashboard</a>
        </form>
    </div>
    <script src="assets/js/main.js"></script>
</body>
</html>
