<%@ page import="java.sql.*" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.security.SecureRandom" %>
<%@ page import="javax.crypto.SecretKeyFactory" %>
<%@ page import="javax.crypto.spec.PBEKeySpec" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }

    private static String sha256(String value) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] digest = md.digest(value.getBytes("UTF-8"));
        StringBuilder sb = new StringBuilder();
        for (byte b : digest) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private static String generateSalt() {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
    }

    private static String hashPassword(String password, String saltB64) throws Exception {
        byte[] salt = Base64.getDecoder().decode(saltB64);
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 65536, 256);
        SecretKeyFactory skf = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        return Base64.getEncoder().encodeToString(skf.generateSecret(spec).getEncoded());
    }
%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;

    Integer pendingResetUserId = (Integer) session.getAttribute("pendingResetUserId");
    String otp = request.getParameter("otp");
    String newPassword = request.getParameter("newPassword");
    String confirmPassword = request.getParameter("confirmPassword");

    if (pendingResetUserId == null) {
        safeRedirect(response, base + "/forgotPassword.jsp?error=Start reset process first");
        return;
    }

    if (otp == null || otp.trim().isEmpty() || newPassword == null || newPassword.trim().isEmpty() || confirmPassword == null || confirmPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/resetPassword.jsp?error=1");
        return;
    }

    if (newPassword.length() < 6) {
        safeRedirect(response, base + "/resetPassword.jsp?weak=1");
        return;
    }

    if (!newPassword.equals(confirmPassword)) {
        safeRedirect(response, base + "/resetPassword.jsp?mismatch=1");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/resetPassword.jsp?error=db");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = null;
    try {
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        String otpHash = sha256(otp.trim());
        PreparedStatement checkOtp = con.prepareStatement(
            "SELECT otp_id FROM otp_codes WHERE user_id=? AND channel='email' AND consumed=0 AND expires_at >= NOW() AND otp_hash=? ORDER BY otp_id DESC LIMIT 1"
        );
        checkOtp.setInt(1, pendingResetUserId.intValue());
        checkOtp.setString(2, otpHash);
        ResultSet rs = checkOtp.executeQuery();

        if (!rs.next()) {
            safeRedirect(response, base + "/resetPassword.jsp?error=1");
            return;
        }

        int otpId = rs.getInt("otp_id");
        String salt = generateSalt();
        String hash = hashPassword(newPassword, salt);

        PreparedStatement updUser = con.prepareStatement(
            "UPDATE users SET password_hash=?, password_salt=?, password=NULL, is_verified=1 WHERE user_id=?"
        );
        updUser.setString(1, hash);
        updUser.setString(2, salt);
        updUser.setInt(3, pendingResetUserId.intValue());
        updUser.executeUpdate();
        updUser.close();

        PreparedStatement updOtp = con.prepareStatement("UPDATE otp_codes SET consumed=1 WHERE otp_id=?");
        updOtp.setInt(1, otpId);
        updOtp.executeUpdate();
        updOtp.close();

        session.removeAttribute("pendingResetUserId");
        session.removeAttribute("pendingResetEmail");

        safeRedirect(response, base + "/userLogin.jsp?reset=1");
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/resetPassword.jsp?error=1");
    } finally {
        if (con != null) con.close();
    }
%>
