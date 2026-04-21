<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%!
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "\\r").replace("\n", "\\n");
    }
%>
<%
    response.setHeader("Cache-Control", "no-store");
    Integer userId = (Integer) session.getAttribute("userId");
    String role = (String) session.getAttribute("role");
    if (userId == null || role == null) {
        response.setStatus(401);
        out.print("{\"ok\":false,\"error\":\"unauthorized\"}");
        return;
    }

    String code = request.getParameter("code");
    String status = request.getParameter("status");
    String category = request.getParameter("category");

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

        StringBuilder sql = new StringBuilder(
            "SELECT c.complaint_id,c.complaint_code,c.category,c.description,c.address,c.status,c.created_at,c.updated_at," +
            "u.name AS user_name,u.email AS user_email FROM complaints c JOIN users u ON c.user_id=u.user_id WHERE 1=1"
        );

        java.util.List<Object> params = new java.util.ArrayList<>();

        if ("user".equals(role)) {
            sql.append(" AND c.user_id=?");
            params.add(userId);
        }
        if (code != null && !code.trim().isEmpty()) {
            sql.append(" AND c.complaint_code=?");
            params.add(code.trim());
        }
        if (status != null && !status.trim().isEmpty()) {
            sql.append(" AND c.status=?");
            params.add(status.trim());
        }
        if (category != null && !category.trim().isEmpty()) {
            sql.append(" AND c.category=?");
            params.add(category.trim());
        }

        sql.append(" ORDER BY c.created_at DESC LIMIT 500");

        PreparedStatement pst = con.prepareStatement(sql.toString());
        int idx = 1;
        for (Object p : params) pst.setObject(idx++, p);

        ResultSet rs = pst.executeQuery();

        StringBuilder json = new StringBuilder();
        json.append("{\"ok\":true,\"complaints\":[");
        boolean first = true;
        while (rs.next()) {
            if (!first) json.append(",");
            first = false;
            json.append("{");
            json.append("\"complaintId\":").append(rs.getInt("complaint_id")).append(",");
            json.append("\"code\":\"").append(esc(rs.getString("complaint_code"))).append("\",");
            json.append("\"category\":\"").append(esc(rs.getString("category"))).append("\",");
            json.append("\"description\":\"").append(esc(rs.getString("description"))).append("\",");
            json.append("\"address\":\"").append(esc(rs.getString("address"))).append("\",");
            json.append("\"status\":\"").append(esc(rs.getString("status"))).append("\",");
            json.append("\"createdAt\":\"").append(esc(String.valueOf(rs.getTimestamp("created_at")))).append("\",");
            json.append("\"updatedAt\":\"").append(esc(String.valueOf(rs.getTimestamp("updated_at")))).append("\",");
            json.append("\"userName\":\"").append(esc(rs.getString("user_name"))).append("\",");
            json.append("\"userEmail\":\"").append(esc(rs.getString("user_email"))).append("\"");
            json.append("}");
        }
        json.append("]}");

        out.print(json.toString());
        rs.close();
        pst.close();
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"server\"}");
    } finally {
        if (con != null) try { con.close(); } catch(Exception ignore) {}
    }
%>
