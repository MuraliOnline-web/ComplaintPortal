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
        out.print("{\"ok\":true,\"authenticated\":false}");
        return;
    }

    String name = null;
    String email = null;
    String mobile = null;

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();

    if (dbUrl != null && !dbUrl.isBlank() && dbUser != null && !dbUser.isBlank() && dbPassword != null && !dbPassword.isBlank()) {
        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
            PreparedStatement pst = con.prepareStatement("SELECT name,email,mobile FROM users WHERE user_id=? LIMIT 1");
            pst.setInt(1, userId.intValue());
            ResultSet rs = pst.executeQuery();
            if (rs.next()) {
                name = rs.getString("name");
                email = rs.getString("email");
                mobile = rs.getString("mobile");
            }
            rs.close();
            pst.close();
        } catch (Exception ignore) {
            // Keep session-based fallback.
        } finally {
            if (con != null) try { con.close(); } catch(Exception ignore) {}
        }
    }

    if (name == null) name = (String) session.getAttribute("userName");
    if (email == null) email = (String) session.getAttribute("userEmail");
    if (mobile == null) mobile = (String) session.getAttribute("userMobile");

    out.print("{\"ok\":true,\"authenticated\":true,\"user\":{");
    out.print("\"id\":" + userId + ",");
    out.print("\"role\":\"" + esc(role) + "\",");
    out.print("\"name\":\"" + esc(name) + "\",");
    out.print("\"email\":\"" + esc(email) + "\",");
    out.print("\"mobile\":\"" + esc(mobile) + "\"");
    out.print("}}");
%>
