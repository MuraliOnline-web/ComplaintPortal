<%@ page import="java.sql.*" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.security.MessageDigest" %>
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
%>
<%
    Integer pendingUserId = (Integer) session.getAttribute("pendingUserId");
    String otp = request.getParameter("otp");

    if (pendingUserId == null) {
        safeRedirect(response, "../userLogin.jsp?required=1");
        return;
    }
    if (otp == null || otp.trim().isEmpty()) {
        safeRedirect(response, "../verifyOtp.jsp?error=1");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, "../verifyOtp.jsp?error=db");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = null;
    try {
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        String otpHash = sha256(otp.trim());
        PreparedStatement pst = con.prepareStatement(
            "SELECT otp_id FROM otp_codes WHERE user_id=? AND channel='email' AND consumed=0 AND expires_at >= NOW() AND otp_hash=? ORDER BY otp_id DESC LIMIT 1"
        );
        pst.setInt(1, pendingUserId.intValue());
        pst.setString(2, otpHash);
        ResultSet rs = pst.executeQuery();

        if (!rs.next()) {
            safeRedirect(response, "../verifyOtp.jsp?error=1");
            return;
        }

        int otpId = rs.getInt("otp_id");
        PreparedStatement upd = con.prepareStatement("UPDATE otp_codes SET consumed=1 WHERE otp_id=?");
        upd.setInt(1, otpId);
        upd.executeUpdate();
        upd.close();

        session.setAttribute("userId", pendingUserId);
        session.setAttribute("userName", session.getAttribute("pendingUserName"));
        session.setAttribute("userEmail", session.getAttribute("pendingUserEmail"));
        session.setAttribute("userMobile", session.getAttribute("pendingUserMobile"));
        session.setAttribute("role", "user");

        session.removeAttribute("pendingUserId");
        session.removeAttribute("pendingUserName");
        session.removeAttribute("pendingUserEmail");
        session.removeAttribute("pendingUserMobile");
        session.removeAttribute("devOtp");

        safeRedirect(response, "../userDashboard.jsp");
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, "../verifyOtp.jsp?error=1");
    } finally {
        if (con != null) con.close();
    }
%>
