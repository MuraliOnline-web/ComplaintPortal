<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="org.apache.taglibs.standard.tag.rt.core.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>Complaint Registered</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
</head>
<body class="bg-gradient">
    <div class="container-3d">
        <h2>Complaint Registered Successfully!</h2>
        <p>Your Complaint ID: <b><%= request.getParameter("id") != null ? request.getParameter("id") : "" %></b></p>
        <p>Your Complaint Code: <b><%= request.getParameter("code") != null ? request.getParameter("code") : "" %></b></p>
        <p>Thank you <b><%= request.getParameter("name") != null ? request.getParameter("name") : "User" %></b>. We will update you once it is resolved.</p>
        <div class="form-group" style="margin-top: 16px;">
            <a class="btn btn-primary btn-3d" href="index.jsp">Back to Home</a>
            <a class="btn btn-secondary btn-3d" href="registerComplaint.jsp">Register another complaint</a>
        </div>
    </div>
    <script src="assets/js/main.js"></script>
</body>
</html>
