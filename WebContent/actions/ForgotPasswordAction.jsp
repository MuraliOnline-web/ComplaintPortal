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

    String email = request.getParameter("email");
    if (email == null || email.trim().isEmpty()) {
        safeRedirect(response, base + "/forgotPassword.jsp?error=Enter your registered email");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/forgotPassword.jsp?error=Database is not configured");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = null;
    try {
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        PreparedStatement pst = con.prepareStatement(
            "SELECT user_id, name, email FROM users WHERE role='user' AND email=? LIMIT 1"
        );
        pst.setString(1, email.trim());
        ResultSet rs = pst.executeQuery();
        if (!rs.next()) {
            safeRedirect(response, base + "/forgotPassword.jsp?error=notfound");
            return;
        }

        int userId = rs.getInt("user_id");
        String userName = rs.getString("name");
        String userEmail = rs.getString("email");

        PreparedStatement cooldownPst = con.prepareStatement(
            "SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) AS elapsed FROM otp_codes WHERE user_id=? AND channel='email' ORDER BY otp_id DESC LIMIT 1"
        );
        cooldownPst.setInt(1, userId);
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
        otpPst.setInt(1, userId);
        otpPst.setString(2, otpHash);
        otpPst.setInt(3, OTP_VALIDITY_MINUTES);
        otpPst.executeUpdate();
        otpPst.close();

        final String smtpUser = ConfigLoader.getSmtpUser();
        final String smtpPass = ConfigLoader.getSmtpPassword();
        final String smtpHost = ConfigLoader.getSmtpHost();
        final String smtpPort = ConfigLoader.getSmtpPort();

        boolean smtpConfigured =
            smtpUser != null && !smtpUser.trim().isEmpty() &&
            smtpPass != null && !smtpPass.trim().isEmpty();
        if (!smtpConfigured) {
            safeRedirect(response, base + "/forgotPassword.jsp?smtp=cfg");
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
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(userEmail));
        message.setSubject("Password Reset OTP - Complaint Portal");
        message.setText("Hi " + userName + ",\n\nYour password reset OTP is: " + otp + "\nIt is valid for " + OTP_VALIDITY_MINUTES + " minutes.\n\n- Complaint Portal");
        Transport.send(message);

        session.setAttribute("pendingResetUserId", userId);
        session.setAttribute("pendingResetEmail", userEmail);

        safeRedirect(response, base + "/resetPassword.jsp?sent=1&wait=" + RESEND_COOLDOWN_SECONDS + "&exp=" + OTP_VALIDITY_MINUTES);
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/forgotPassword.jsp?smtp=send");
    } finally {
        if (con != null) con.close();
    }
%>
