<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String role = (String) session.getAttribute("role");
    if (role == null || (!"admin".equals(role) && !"officer".equals(role))) {
        response.sendRedirect("../login.jsp?denied=1");
        return;
    }

    String date = request.getParameter("date");
    if (date == null || date.isBlank()) {
        response.sendRedirect("../analytics.jsp?error=invalidDate");
        return;
    }

    // Placeholder endpoint: keeps navigation stable and prevents 404/500 until reminder scheduler is implemented.
    response.sendRedirect("../analytics.jsp?info=reminderQueued&date=" + java.net.URLEncoder.encode(date, "UTF-8"));
%>
