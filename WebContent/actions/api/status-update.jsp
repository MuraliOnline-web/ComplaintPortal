<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%!
    private static String toDbStatus(String s) {
        if (s == null) return "Pending";
        String v = s.trim();
        if ("Pending".equalsIgnoreCase(v)) return "Pending";
        if ("In Progress".equalsIgnoreCase(v) || "Solving".equalsIgnoreCase(v)) return "Solving";
        if ("Resolved".equalsIgnoreCase(v) || "Solved".equalsIgnoreCase(v)) return "Solved";
        return "Pending";
    }
%>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.setStatus(405);
        out.print("{\"ok\":false,\"error\":\"method_not_allowed\"}");
        return;
    }

    Integer userId = (Integer) session.getAttribute("userId");
    String role = (String) session.getAttribute("role");
    if (userId == null || role == null || !"admin".equals(role)) {
        response.setStatus(401);
        out.print("{\"ok\":false,\"error\":\"unauthorized\"}");
        return;
    }

    String complaintIdRaw = request.getParameter("complaintId");
    String status = toDbStatus(request.getParameter("status"));
    if (complaintIdRaw == null || complaintIdRaw.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"error\":\"missing_complaint_id\"}");
        return;
    }

    int complaintId;
    try { complaintId = Integer.parseInt(complaintIdRaw.trim()); }
    catch (Exception ex) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"error\":\"invalid_complaint_id\"}");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"db_config\"}");
        return;
    }

    Connection con = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
        PreparedStatement pst = con.prepareStatement("UPDATE complaints SET status=? WHERE complaint_id=?");
        pst.setString(1, status);
        pst.setInt(2, complaintId);
        int changed = pst.executeUpdate();
        pst.close();
        out.print("{\"ok\":true,\"updated\":" + changed + "}");
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"server\"}");
    } finally {
        if (con != null) try { con.close(); } catch(Exception ignore) {}
    }
%>
