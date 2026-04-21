<%@ page import="java.sql.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="javax.crypto.SecretKeyFactory" %>
<%@ page import="javax.crypto.spec.PBEKeySpec" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%!
    private static String hashPassword(String password, String saltB64) throws Exception {
        byte[] salt = Base64.getDecoder().decode(saltB64);
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 65536, 256);
        SecretKeyFactory skf = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        return Base64.getEncoder().encodeToString(skf.generateSecret(spec).getEncoded());
    }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "\\r").replace("\n", "\\n");
    }
%>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.setStatus(405);
        out.print("{\"ok\":false,\"error\":\"method_not_allowed\"}");
        return;
    }

    String email = request.getParameter("email");
    String password = request.getParameter("password");
    String role = request.getParameter("role");
    if (email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty() || role == null || role.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"error\":\"missing_fields\"}");
        return;
    }

    role = role.trim().toLowerCase();
    if (!("user".equals(role) || "admin".equals(role) || "officer".equals(role))) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"error\":\"invalid_role\"}");
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

        PreparedStatement pst = con.prepareStatement(
            "SELECT user_id,name,email,mobile,role,password,password_hash,password_salt FROM users WHERE email=? AND role=? LIMIT 1"
        );
        pst.setString(1, email.trim());
        pst.setString(2, role);
        ResultSet rs = pst.executeQuery();

        if (!rs.next()) {
            response.setStatus(401);
            out.print("{\"ok\":false,\"error\":\"invalid_credentials\"}");
            return;
        }

        String storedPlain = rs.getString("password");
        String storedHash = rs.getString("password_hash");
        String storedSalt = rs.getString("password_salt");

        boolean passwordOk = false;
        if (storedHash != null && !storedHash.trim().isEmpty() && storedSalt != null && !storedSalt.trim().isEmpty()) {
            String inputHash = hashPassword(password, storedSalt);
            passwordOk = inputHash.equals(storedHash);
        } else if (storedPlain != null) {
            passwordOk = storedPlain.equals(password);
        }

        if (!passwordOk) {
            response.setStatus(401);
            out.print("{\"ok\":false,\"error\":\"invalid_credentials\"}");
            return;
        }

        int uid = rs.getInt("user_id");
        String name = rs.getString("name");
        String dbRole = rs.getString("role");
        String dbEmail = rs.getString("email");
        String dbMobile = rs.getString("mobile");

        session.setAttribute("userId", uid);
        session.setAttribute("userName", name);
        session.setAttribute("userEmail", dbEmail);
        session.setAttribute("userMobile", dbMobile);
        session.setAttribute("role", dbRole);

        out.print("{\"ok\":true,\"role\":\"" + esc(dbRole) + "\",\"name\":\"" + esc(name) + "\"}");

        rs.close();
        pst.close();
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"server\"}");
    } finally {
        if (con != null) try { con.close(); } catch(Exception ignore) {}
    }
%>
