<%@ page import="java.sql.*" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.util.Properties" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="javax.crypto.SecretKeyFactory" %>
<%@ page import="javax.crypto.spec.PBEKeySpec" %>
<%@ page import="jakarta.mail.*" %>
<%@ page import="jakarta.mail.internet.*" %>
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

    String emailInput = request.getParameter("email");
    String password = request.getParameter("password");

    if (emailInput == null || emailInput.isBlank() || password == null || password.isBlank()) {
        safeRedirect(response, base + "/userLogin.jsp?error=1");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        safeRedirect(response, base + "/userLogin.jsp?error=config");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = null;
    try {
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        PreparedStatement pst = con.prepareStatement(
            "SELECT user_id, name, email, mobile, role, password, password_hash, password_salt FROM users WHERE role='user' AND email=? LIMIT 1"
        );
        pst.setString(1, emailInput.trim());
        ResultSet rs = pst.executeQuery();
        if (!rs.next()) {
            safeRedirect(response, base + "/userLogin.jsp?error=1");
            return;
        }

        int userId = rs.getInt("user_id");
        String userName = rs.getString("name");
        String email = rs.getString("email");
        String mobile = rs.getString("mobile");
        String pwdHash = rs.getString("password_hash");
        String pwdSalt = rs.getString("password_salt");

        boolean passwordOk = false;
        if (pwdHash != null && !pwdHash.isBlank() && pwdSalt != null && !pwdSalt.isBlank()) {
            String inputHash = hashPassword(password, pwdSalt);
            passwordOk = inputHash.equals(pwdHash);
        }

        if (!passwordOk) {
            safeRedirect(response, base + "/userLogin.jsp?error=1");
            return;
        }

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

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", smtpHost);
        props.put("mail.smtp.port", smtpPort);

        boolean mailSent = false;
        boolean smtpConfigured =
            smtpUser != null && !smtpUser.isBlank() &&
            smtpPass != null && !smtpPass.isBlank();

        if (!smtpConfigured) {
            safeRedirect(response, base + "/userLogin.jsp?smtp=cfg");
            return;
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
            mailSent = true;
        } catch (Exception mailEx) {
            application.log("OTP email send failed", mailEx);
            safeRedirect(response, base + "/userLogin.jsp?smtp=send");
            return;
        }

        session.setAttribute("pendingUserId", userId);
        session.setAttribute("pendingUserName", userName);
        session.setAttribute("pendingUserEmail", email);
        session.setAttribute("pendingUserMobile", mobile);

        safeRedirect(response, base + "/verifyOtp.jsp?sent=" + (mailSent ? "1" : "0") + "&mail=" + (mailSent ? "1" : "0") + "&exp=" + OTP_VALIDITY_MINUTES);
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/userLogin.jsp?error=1");
    } finally {
        if (con != null) con.close();
    }
%>
