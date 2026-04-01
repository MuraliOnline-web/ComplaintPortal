<!-- Complaint Form JSP (WebContent) -->
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String role = (String) session.getAttribute("role");
    if(role == null || !"user".equals(role)) {
        response.sendRedirect("userLogin.jsp?required=1");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Register Complaint</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body class="bg-gradient">

    <div class="container-3d">
        <h2>Register a Complaint</h2>
        
        <% if(request.getParameter("success") != null) { %>
            <div class="alert alert-success">${param.success}</div>
        <% } %>
        <% if(request.getParameter("error") != null) { %>
            <div class="alert alert-error">${param.error}</div>
        <% } %>

        <!-- Web root is WebContent/ at runtime. Paths are relative to this file. -->
        <form action="actions/RegisterComplaintAction.jsp" method="post">
            <div class="form-group">
                <label>Name:</label>
                <input type="text" name="name" class="form-control input-3d" required readonly value="<%= session.getAttribute("userName") != null ? session.getAttribute("userName") : "" %>">
            </div>
            <div class="form-group">
                <label>Email:</label>
                <input type="email" name="email" class="form-control input-3d" required readonly value="<%= session.getAttribute("userEmail") != null ? session.getAttribute("userEmail") : "" %>">
            </div>
            <div class="form-group">
                <label>Mobile:</label>
                <input type="text" name="mobile" class="form-control input-3d" required readonly value="<%= session.getAttribute("userMobile") != null ? session.getAttribute("userMobile") : "" %>">
            </div>
            
            <div class="form-group">
                <label>Category:</label>
                <select name="category" class="form-control input-3d" required>
                    <option value="">Select Category</option>
                    <option value="WaterTap">Water Tap</option>
                    <option value="Electricity">Electricity</option>
                    <option value="Road">Road</option>
                    <option value="Sanitation">Sanitation</option>
                    <option value="Other">Other</option>
                </select>
            </div>
            
            <div class="form-group">
                <label>Description:</label>
                <textarea name="description" class="form-control input-3d" rows="4" required></textarea>
            </div>
            
            <div class="form-group">
                <label>Address:</label>
                <input type="text" name="address" class="form-control input-3d" required>
            </div>
            
            <div class="form-group">
                <label>Photo:</label>
                <input type="text" class="form-control input-3d" value="Photo upload temporarily disabled" readonly>
            </div>
            
            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-3d btn-glow">Submit Complaint</button>
                <a href="index.jsp" class="btn btn-secondary btn-3d">Cancel</a>
            </div>
        </form>
    </div>

    <script src="assets/js/main.js"></script>
</body>
</html>
