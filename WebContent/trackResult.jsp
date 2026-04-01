<!-- Track Complaint Result JSP (WebContent) -->
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Complaint Tracking Result</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" integrity="sha384-gH6tQd6rYt6v7s5FQ4u+Nw6mM2J+Z1oQXbQ9yKqNqCkzJ10c1qf6jv9vZ5GxXKbi" crossorigin="anonymous">
</head>
<body>
    <div class="container-3d">
        <h2>Complaint Details</h2>
        <% if(request.getAttribute("complaintId") != null) { %>
            <div class="complaint-details">
                <p><strong>Complaint ID:</strong> <%= request.getAttribute("complaintId") %></p>
                <p><strong>Category:</strong> <%= request.getAttribute("category") %></p>
                <p><strong>Description:</strong> <%= request.getAttribute("description") %></p>
                <p><strong>Status:</strong> 
                    <span class="status-badge status-<%= request.getAttribute("status") %>">
                        <%= request.getAttribute("status") %>
                    </span>
                </p>
                <% if(request.getAttribute("officerNotes") != null) { %>
                    <p><strong>Officer Notes:</strong> <%= request.getAttribute("officerNotes") %></p>
                <% } %>
                <% if(request.getAttribute("photoPath") != null) { %>
                    <p><strong>Photo:</strong></p>
                    <img src="<%= request.getAttribute("photoPath") %>" alt="Complaint Photo" style="max-width: 300px; border-radius: 8px;">
                <% } %>
            </div>
        <% } else { %>
            <div class="alert alert-error">
                <h3>No complaint found with the provided details.</h3>
                <p>Please check your Complaint ID and Email address.</p>
            </div>
        <% } %>
        <br>
        <a href="trackComplaint.jsp" class="btn btn-primary btn-3d">Track Another Complaint</a>
        <a href="index.jsp" class="btn btn-primary btn-3d">Back to Home</a>
    </div>
    <style>
        .complaint-details {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            margin: 20px 0;
        }
        .complaint-details p { margin: 10px 0; font-size: 16px; }
        .status-badge { padding: 4px 12px; border-radius: 20px; font-weight: bold; text-transform: uppercase; }
        .status-Pending { background-color: #ffc107; color: #000; }
        .status-Solving { background-color: #17a2b8; color: #fff; }
        .status-Solved { background-color: #28a745; color: #fff; }
    </style>
</body>
</html>
