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
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;

    String loginMode = request.getParameter("loginMode");
    String identifier = request.getParameter("identifier");

    if (identifier == null || identifier.trim().isEmpty()) {
        safeRedirect(response, base + "/userLogin.jsp?error=1");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/userLogin.jsp?error=config");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = null;
    try {
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        String sql = "SELECT user_id, name, email, mobile FROM users WHERE role='user' AND " +
                     ("mobile".equalsIgnoreCase(loginMode) ? "mobile=?" : "email=?") +
                     " LIMIT 1";
        PreparedStatement pst = con.prepareStatement(sql);
        pst.setString(1, identifier.trim());
        ResultSet rs = pst.executeQuery();
        if (!rs.next()) {
            safeRedirect(response, base + "/userLogin.jsp?error=1");
            return;
        }

        int userId = rs.getInt("user_id");
        String userName = rs.getString("name");
        String email = rs.getString("email");
        String mobile = rs.getString("mobile");

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

        final String smtpUser = ConfigLoader.getSmtpUser() == null ? null : ConfigLoader.getSmtpUser().trim();
        final String smtpPass = ConfigLoader.getSmtpPassword() == null ? null : ConfigLoader.getSmtpPassword().trim();
        final String smtpHost = ConfigLoader.getSmtpHost() == null ? null : ConfigLoader.getSmtpHost().trim();
        final String smtpPort = ConfigLoader.getSmtpPort() == null ? null : ConfigLoader.getSmtpPort().trim();

        boolean smtpConfigured = smtpUser != null && !smtpUser.trim().isEmpty() && smtpPass != null && !smtpPass.trim().isEmpty();
        if (!smtpConfigured || smtpHost == null || smtpHost.trim().isEmpty() || smtpPort == null || smtpPort.trim().isEmpty()) {
            safeRedirect(response, base + "/userLogin.jsp?smtp=cfg");
            return;
        }

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.host", smtpHost);
        props.put("mail.smtp.port", smtpPort);
        props.put("mail.smtp.connectiontimeout", "10000");
        props.put("mail.smtp.timeout", "10000");
        props.put("mail.smtp.writetimeout", "10000");
        props.put("mail.smtp.ssl.trust", smtpHost);
        props.put("mail.smtp.ssl.protocols", "TLSv1.2");

        boolean useImplicitSsl = "465".equals(smtpPort);
        if (useImplicitSsl) {
            props.put("mail.smtp.ssl.enable", "true");
            props.put("mail.smtp.starttls.enable", "false");
        } else {
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.starttls.required", "true");
        }

        try {
            Session mailSession = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(smtpUser, smtpPass);
                }
            });
            Message message = new MimeMessage(mailSession);
            message.setFrom(new InternetAddress(smtpUser));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(email));
            message.setSubject("Your Complaint Portal OTP");
            message.setText("Hi " + userName + ",\n\nYour OTP is: " + otp + "\nIt is valid for " + OTP_VALIDITY_MINUTES + " minutes.\n\n- Complaint Portal");
            Transport.send(message);
        } catch (Exception mailEx) {
            application.log("OTP email send failed: host=" + smtpHost + ", port=" + smtpPort + ", user=" + smtpUser, mailEx);
            safeRedirect(response, base + "/userLogin.jsp?smtp=send");
            return;
        }

        session.setAttribute("pendingUserId", userId);
        session.setAttribute("pendingUserName", userName);
        session.setAttribute("pendingUserEmail", email);
        session.setAttribute("pendingUserMobile", mobile);

        safeRedirect(response, base + "/verifyOtp.jsp?sent=1&mail=1&exp=" + OTP_VALIDITY_MINUTES);
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/userLogin.jsp?error=1");
    } finally {
        if (con != null) con.close();
    }
%>
