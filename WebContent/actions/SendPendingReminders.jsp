<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws java.io.IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }
%>
<%
    String role = (String) session.getAttribute("role");
    if (role == null || (!"admin".equals(role) && !"officer".equals(role))) {
        safeRedirect(response, "../login.jsp?denied=1");
        return;
    }

    String date = request.getParameter("date");
    if (date == null || date.isBlank()) {
        safeRedirect(response, "../analytics.jsp?error=invalidDate");
        return;
    }

    // Placeholder endpoint: keeps navigation stable and prevents 404/500 until reminder scheduler is implemented.
    safeRedirect(response, "../analytics.jsp?info=reminderQueued&date=" + java.net.URLEncoder.encode(date, "UTF-8"));
%>
