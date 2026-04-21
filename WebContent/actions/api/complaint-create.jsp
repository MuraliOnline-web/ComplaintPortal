<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%!
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "\\r").replace("\n", "\\n");
    }

    private static String toDbCategory(String category) {
        if (category == null) return "Other";
        String c = category.trim().toLowerCase();
        if (c.equals("road") || c.equals("roads")) return "Road";
        if (c.equals("electricity")) return "Electricity";
        if (c.equals("watertap") || c.equals("water tap") || c.equals("water supply")) return "WaterTap";
        if (c.equals("sanitation")) return "Sanitation";
        return "Other";
    }

    private static String generateCode() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        StringBuilder sb = new StringBuilder("CMP-");
        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyyMMdd");
        sb.append(sdf.format(new java.util.Date())).append("-");
        java.util.Random rnd = new java.util.Random();
        for (int i = 0; i < 6; i++) sb.append(chars.charAt(rnd.nextInt(chars.length())));
        return sb.toString();
    }
%>
<%
    response.setHeader("Cache-Control", "no-store");
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.setStatus(405);
        out.print("{\"ok\":false,\"error\":\"method_not_allowed\"}");
        return;
    }

    Integer userId = (Integer) session.getAttribute("userId");
    String role = (String) session.getAttribute("role");
    if (userId == null || role == null || !"user".equals(role)) {
        response.setStatus(401);
        out.print("{\"ok\":false,\"error\":\"unauthorized\"}");
        return;
    }

    String category = request.getParameter("category");
    String description = request.getParameter("description");
    String address = request.getParameter("address");

    if (description == null || description.trim().isEmpty() || address == null || address.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"error\":\"missing_fields\"}");
        return;
    }

    String dbCategory = toDbCategory(category);

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

        String code = generateCode();
        boolean unique = false;
        while (!unique) {
            PreparedStatement chk = con.prepareStatement("SELECT 1 FROM complaints WHERE complaint_code=? LIMIT 1");
            chk.setString(1, code);
            ResultSet crs = chk.executeQuery();
            unique = !crs.next();
            crs.close();
            chk.close();
            if (!unique) code = generateCode();
        }

        PreparedStatement pst = con.prepareStatement(
            "INSERT INTO complaints(user_id,category,description,address,complaint_code,status) VALUES(?,?,?,?,?,?)",
            Statement.RETURN_GENERATED_KEYS
        );
        pst.setInt(1, userId.intValue());
        pst.setString(2, dbCategory);
        pst.setString(3, description.trim());
        pst.setString(4, address.trim());
        pst.setString(5, code);
        pst.setString(6, "Pending");
        pst.executeUpdate();

        int complaintId = 0;
        ResultSet keys = pst.getGeneratedKeys();
        if (keys.next()) complaintId = keys.getInt(1);
        keys.close();
        pst.close();

        out.print("{\"ok\":true,\"complaintId\":" + complaintId + ",\"code\":\"" + esc(code) + "\"}");
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"server\"}");
    } finally {
        if (con != null) try { con.close(); } catch(Exception ignore) {}
    }
%>
