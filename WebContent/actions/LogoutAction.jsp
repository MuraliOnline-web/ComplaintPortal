<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    jakarta.servlet.http.HttpSession oldSession = request.getSession(false);
    if (oldSession != null) {
        oldSession.invalidate();
    }

    jakarta.servlet.http.HttpSession newSession = request.getSession(true);
    newSession.setAttribute("flashMessage", "You have been logged out successfully.");
    newSession.setAttribute("flashType", "success");

    response.setStatus(302);
    response.setHeader("Location", "../index.jsp");
%>
