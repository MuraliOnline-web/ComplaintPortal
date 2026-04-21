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

        String scopeWhere = "";
        if ("user".equals(role)) {
            scopeWhere = " WHERE user_id=" + userId.intValue();
        }

        int total = 0;
        int pending = 0;
        int solving = 0;
        int solved = 0;

        PreparedStatement c1 = con.prepareStatement("SELECT COUNT(*) AS total, SUM(status='Pending') AS pending, SUM(status='Solving') AS solving, SUM(status='Solved') AS solved FROM complaints" + scopeWhere);
        ResultSet r1 = c1.executeQuery();
        if (r1.next()) {
            total = r1.getInt("total");
            pending = r1.getInt("pending");
            solving = r1.getInt("solving");
            solved = r1.getInt("solved");
        }
        r1.close();
        c1.close();

        StringBuilder monthly = new StringBuilder("[");
        PreparedStatement c2 = con.prepareStatement(
            "SELECT DATE_FORMAT(created_at, '%b') AS m, COUNT(*) AS filed, SUM(status='Solved') AS resolved " +
            "FROM complaints" + scopeWhere + " GROUP BY YEAR(created_at), MONTH(created_at) ORDER BY YEAR(created_at), MONTH(created_at) LIMIT 6"
        );
        ResultSet r2 = c2.executeQuery();
        boolean first = true;
        while (r2.next()) {
            if (!first) monthly.append(",");
            first = false;
            monthly.append("{\"month\":\"").append(esc(r2.getString("m"))).append("\",");
            monthly.append("\"filed\":").append(r2.getInt("filed")).append(",");
            monthly.append("\"resolved\":").append(r2.getInt("resolved")).append("}");
        }
        monthly.append("]");
        r2.close();
        c2.close();

        StringBuilder categories = new StringBuilder("[");
        PreparedStatement c3 = con.prepareStatement(
            "SELECT category, COUNT(*) AS cnt FROM complaints" + scopeWhere + " GROUP BY category ORDER BY cnt DESC"
        );
        ResultSet r3 = c3.executeQuery();
        first = true;
        while (r3.next()) {
            if (!first) categories.append(",");
            first = false;
            categories.append("{\"name\":\"").append(esc(r3.getString("category"))).append("\",");
            categories.append("\"value\":").append(r3.getInt("cnt")).append("}");
        }
        categories.append("]");
        r3.close();
        c3.close();

        out.print("{\"ok\":true,");
        out.print("\"summary\":{\"total\":" + total + ",\"pending\":" + pending + ",\"inProgress\":" + solving + ",\"resolved\":" + solved + "},");
        out.print("\"monthlyTrend\":" + monthly.toString() + ",");
        out.print("\"categoryBreakdown\":" + categories.toString());
        out.print("}");
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"server\"}");
    } finally {
        if (con != null) try { con.close(); } catch(Exception ignore) {}
    }
%>
