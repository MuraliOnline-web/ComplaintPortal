<%@ page import="java.sql.*" %>
<%@ page import="java.security.SecureRandom" %>
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

    private static String generateSalt() {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
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

    String name = request.getParameter("name");
    String email = request.getParameter("email");
    String mobile = request.getParameter("mobile");
    String cityVillage = request.getParameter("cityVillage");
    String password = request.getParameter("password");

    if (name == null || name.isBlank() || email == null || email.isBlank() || mobile == null || mobile.isBlank() || cityVillage == null || cityVillage.isBlank() || password == null || password.isBlank()) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"error\":\"missing_fields\"}");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"db_config\"}");
        return;
    }

    Connection con = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        PreparedStatement dup = con.prepareStatement("SELECT 1 FROM users WHERE email=? LIMIT 1");
        dup.setString(1, email.trim().toLowerCase());
        ResultSet drs = dup.executeQuery();
        if (drs.next()) {
            response.setStatus(409);
            out.print("{\"ok\":false,\"error\":\"email_exists\"}");
            return;
        }
        drs.close();
        dup.close();

        String salt = generateSalt();
        String hash = hashPassword(password, salt);

        PreparedStatement ins = con.prepareStatement(
            "INSERT INTO users(name,email,mobile,city_village,password_hash,password_salt,role,is_verified) VALUES(?,?,?,?,?,?,?,?)",
            Statement.RETURN_GENERATED_KEYS
        );
        ins.setString(1, name.trim());
        ins.setString(2, email.trim().toLowerCase());
        ins.setString(3, mobile.trim());
        ins.setString(4, cityVillage.trim());
        ins.setString(5, hash);
        ins.setString(6, salt);
        ins.setString(7, "user");
        ins.setInt(8, 1);
        ins.executeUpdate();

        int userId = 0;
        ResultSet keys = ins.getGeneratedKeys();
        if (keys.next()) userId = keys.getInt(1);
        keys.close();
        ins.close();

        out.print("{\"ok\":true,\"userId\":" + userId + ",\"name\":\"" + esc(name.trim()) + "\"}");
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"ok\":false,\"error\":\"server\"}");
    } finally {
        if (con != null) try { con.close(); } catch(Exception ignore) {}
    }
%>
