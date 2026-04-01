<%@ page import="java.sql.*" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.security.SecureRandom" %>
<%@ page import="java.util.Base64" %>
<%@ page import="javax.crypto.SecretKeyFactory" %>
<%@ page import="javax.crypto.spec.PBEKeySpec" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }

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
%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;

    String name = request.getParameter("name");
    String email = request.getParameter("email");
    String mobile = request.getParameter("mobile");
    String cityVillage = request.getParameter("cityVillage");
    String password = request.getParameter("password");

    if (name == null || name.isBlank() ||
        email == null || email.isBlank() || mobile == null || mobile.isBlank() ||
        cityVillage == null || cityVillage.isBlank() || password == null || password.isBlank()) {
        safeRedirect(response, base + "/userRegister.jsp?error=All fields are required");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        safeRedirect(response, base + "/userRegister.jsp?error=Database is not configured");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = null;
    try {
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        PreparedStatement dup = con.prepareStatement(
            "SELECT 1 FROM users WHERE email=? LIMIT 1"
        );
        dup.setString(1, email.trim());
        ResultSet drs = dup.executeQuery();
        if (drs.next()) {
            safeRedirect(response, base + "/userRegister.jsp?error=Email already exists");
            return;
        }
        drs.close();
        dup.close();

        String salt = generateSalt();
        String hash = hashPassword(password, salt);

        PreparedStatement pst = con.prepareStatement(
            "INSERT INTO users(name, email, mobile, city_village, password_hash, password_salt, role, is_verified) VALUES(?,?,?,?,?,?,?,?)"
        );
        pst.setString(1, name.trim());
        pst.setString(2, email.trim());
        pst.setString(3, mobile.trim());
        pst.setString(4, cityVillage.trim());
        pst.setString(5, hash);
        pst.setString(6, salt);
        pst.setString(7, "user");
        pst.setInt(8, 1);
        pst.executeUpdate();
        pst.close();

        safeRedirect(response, base + "/userRegister.jsp?ok=1");
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/userRegister.jsp?error=Registration failed");
    } finally {
        if (con != null) con.close();
    }
%>
