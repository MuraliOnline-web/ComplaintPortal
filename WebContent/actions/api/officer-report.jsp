<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%!
    private static String toDbStatus(String s) {
        if (s == null) return "Solved";
        String v = s.trim();
        if ("Pending".equalsIgnoreCase(v)) return "Pending";
        if ("In Progress".equalsIgnoreCase(v) || "Solving".equalsIgnoreCase(v)) return "Solving";
        if ("Resolved".equalsIgnoreCase(v) || "Solved".equalsIgnoreCase(v)) return "Solved";
        return "Solved";
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
    String userName = (String) session.getAttribute("userName");
    if (userId == null || role == null || (!"officer".equals(role) && !"admin".equals(role))) {
        response.setStatus(401);
        out.print("{\"ok\":false,\"error\":\"unauthorized\"}");
        return;
    }

    String complaintIdRaw = request.getParameter("complaintId");
    String reportNotes = request.getParameter("officerNotes");
    String officerName = request.getParameter("officerName");
    String resolutionStatus = toDbStatus(request.getParameter("resolutionStatus"));

    if (officerName == null || officerName.trim().isEmpty()) officerName = userName;

    if (complaintIdRaw == null || complaintIdRaw.trim().isEmpty() || reportNotes == null || reportNotes.trim().isEmpty() || officerName == null || officerName.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"error\":\"missing_fields\"}");
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

        PreparedStatement ins = con.prepareStatement(
            "INSERT INTO officer_reports(complaint_id,officer_name,report_notes,report_photo_path) VALUES(?,?,?,NULL)"
        );
        ins.setInt(1, complaintId);
        ins.setString(2, officerName.trim());
        ins.setString(3, reportNotes.trim());
        ins.executeUpdate();
        ins.close();

        PreparedStatement upd = con.prepareStatement("UPDATE complaints SET status=?, officer_notes=?, officer_name=? WHERE complaint_id=?");
        upd.setString(1, resolutionStatus);
        upd.setString(2, reportNotes.trim());
        upd.setString(3, officerName.trim());
        upd.setInt(4, complaintId);
        int changed = upd.executeUpdate();
        upd.close();

        out.print("{\"ok\":true,\"updated\":" + changed + "}");
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"server\"}");
    } finally {
        if (con != null) try { con.close(); } catch(Exception ignore) {}
    }
%>
