<%@ page import="java.sql.*" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.util.Properties" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="jakarta.mail.*" %>
<%@ page import="jakarta.mail.internet.*" %>
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
    final int OTP_VALIDITY_MINUTES = 14;
    final int RESEND_COOLDOWN_SECONDS = 30;
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;

    Integer pendingResetUserId = (Integer) session.getAttribute("pendingResetUserId");
    String pendingResetEmail = (String) session.getAttribute("pendingResetEmail");

    if (pendingResetUserId == null || pendingResetEmail == null || pendingResetEmail.isBlank()) {
        safeRedirect(response, base + "/forgotPassword.jsp?error=Start reset process first");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        safeRedirect(response, base + "/resetPassword.jsp?error=db");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = null;
    try {
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        PreparedStatement userPst = con.prepareStatement("SELECT name FROM users WHERE user_id=? AND role='user' LIMIT 1");
        userPst.setInt(1, pendingResetUserId.intValue());
        ResultSet userRs = userPst.executeQuery();
        if (!userRs.next()) {
            safeRedirect(response, base + "/forgotPassword.jsp?error=No account found for reset");
            return;
        }
        String userName = userRs.getString("name");
        userRs.close();
        userPst.close();

        PreparedStatement cooldownPst = con.prepareStatement(
            "SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) AS elapsed FROM otp_codes WHERE user_id=? AND channel='email' ORDER BY otp_id DESC LIMIT 1"
        );
        cooldownPst.setInt(1, pendingResetUserId.intValue());
        ResultSet cooldownRs = cooldownPst.executeQuery();
        if (cooldownRs.next()) {
            int elapsed = cooldownRs.getInt("elapsed");
            if (elapsed < RESEND_COOLDOWN_SECONDS) {
                int wait = RESEND_COOLDOWN_SECONDS - elapsed;
                safeRedirect(response, base + "/resetPassword.jsp?wait=" + wait + "&exp=" + OTP_VALIDITY_MINUTES);
                return;
            }
        }
        cooldownRs.close();
        cooldownPst.close();

        String otp = String.valueOf(100000 + new java.security.SecureRandom().nextInt(900000));
        String otpHash = sha256(otp);

        PreparedStatement otpPst = con.prepareStatement(
            "INSERT INTO otp_codes(user_id, channel, otp_hash, expires_at, consumed) VALUES(?, 'email', ?, DATE_ADD(NOW(), INTERVAL ? MINUTE), 0)"
        );
        otpPst.setInt(1, pendingResetUserId.intValue());
        otpPst.setString(2, otpHash);
        otpPst.setInt(3, OTP_VALIDITY_MINUTES);
        otpPst.executeUpdate();
        otpPst.close();

        final String smtpUser = ConfigLoader.getSmtpUser();
        final String smtpPass = ConfigLoader.getSmtpPassword();
        final String smtpHost = ConfigLoader.getSmtpHost();
        final String smtpPort = ConfigLoader.getSmtpPort();

        boolean smtpConfigured =
            smtpUser != null && !smtpUser.isBlank() &&
            smtpPass != null && !smtpPass.isBlank();
        if (!smtpConfigured) {
            safeRedirect(response, base + "/resetPassword.jsp?smtp=cfg");
            return;
        }

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", smtpHost);
        props.put("mail.smtp.port", smtpPort);

        Session mailSession = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(smtpUser, smtpPass);
            }
        });

        Message message = new MimeMessage(mailSession);
        message.setFrom(new InternetAddress(smtpUser));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(pendingResetEmail));
        message.setSubject("Password Reset OTP - Complaint Portal");
        message.setText("Hi " + userName + ",\n\nYour password reset OTP is: " + otp + "\nIt is valid for " + OTP_VALIDITY_MINUTES + " minutes.\n\n- Complaint Portal");
        Transport.send(message);

        safeRedirect(response, base + "/resetPassword.jsp?resent=1&wait=" + RESEND_COOLDOWN_SECONDS + "&exp=" + OTP_VALIDITY_MINUTES);
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/resetPassword.jsp?smtp=send");
    } finally {
        if (con != null) con.close();
    }
%>
