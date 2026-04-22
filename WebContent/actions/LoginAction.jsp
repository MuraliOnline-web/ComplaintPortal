<!-- Admin/Officer login now uses OTP-by-email by default. Password path is kept as fallback. -->
<%@ page import="java.sql.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.util.Properties" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.security.SecureRandom" %>
<%@ page import="javax.crypto.SecretKeyFactory" %>
<%@ page import="javax.crypto.spec.PBEKeySpec" %>
<%@ page import="jakarta.mail.*" %>
<%@ page import="jakarta.mail.internet.*" %>
<%@ page import="java.io.IOException" %>
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

    private static boolean hasColumn(Connection con, String tableName, String columnName) throws Exception {
        DatabaseMetaData md = con.getMetaData();
        try (ResultSet rs = md.getColumns(con.getCatalog(), null, tableName, columnName)) {
            return rs.next();
        }
    }

    private static String otpRoleColumn(Connection con) throws Exception {
        if (hasColumn(con, "otp_codes", "role")) return "role";
        if (hasColumn(con, "otp_codes", "login_role")) return "login_role";
        return null;
    }
%>
<%
    final int OTP_VALIDITY_MINUTES = 14;

    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;

    String email = request.getParameter("email");
    String requestedRole = request.getParameter("role");
    String password = request.getParameter("password");
    boolean usePasswordFallback = "1".equals(request.getParameter("usePasswordFallback"));

    email = (email == null) ? null : email.trim().toLowerCase();
    requestedRole = (requestedRole == null) ? null : requestedRole.trim().toLowerCase();

    if (email == null || email.isEmpty() || requestedRole == null || requestedRole.isEmpty()) {
        safeRedirect(response, base + "/login.jsp?error=1");
        return;
    }
    if (!("admin".equals(requestedRole) || "officer".equals(requestedRole))) {
        safeRedirect(response, base + "/login.jsp?denied=1");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/login.jsp?error=config");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = null;
    try {
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

        PreparedStatement pst = con.prepareStatement(
            "SELECT user_id, name, email, mobile, role, password, password_hash, password_salt FROM users WHERE email=? LIMIT 1"
        );
        pst.setString(1, email);
        ResultSet rs = pst.executeQuery();

        if (!rs.next()) {
            safeRedirect(response, base + "/login.jsp?error=1&reason=email_not_found");
            return;
        }

        int uid = rs.getInt("user_id");
        String uname = rs.getString("name");
        String userEmail = rs.getString("email");
        String userMobile = rs.getString("mobile");
        String dbRole = rs.getString("role");

        if (!requestedRole.equalsIgnoreCase(dbRole)) {
            safeRedirect(response, base + "/login.jsp?error=1&reason=role_mismatch");
            return;
        }

        // Optional password fallback for emergency rollback. Default flow is OTP.
        if (usePasswordFallback) {
            String legacyPassword = rs.getString("password");
            String storedHash = rs.getString("password_hash");
            String storedSalt = rs.getString("password_salt");
            boolean passwordOk = false;

            if (password != null) {
                if (storedHash != null && !storedHash.trim().isEmpty() && storedSalt != null && !storedSalt.trim().isEmpty()) {
                    String inputHash = hashPassword(password, storedSalt);
                    passwordOk = inputHash.equals(storedHash);
                } else if (legacyPassword != null) {
                    passwordOk = legacyPassword.equals(password);
                }
            }

            if (!passwordOk) {
                safeRedirect(response, base + "/login.jsp?error=1");
                return;
            }

            jakarta.servlet.http.HttpSession oldSession = request.getSession(false);
            if (oldSession != null) oldSession.invalidate();
            jakarta.servlet.http.HttpSession authSession = request.getSession(true);
            java.util.HashMap<String, Object> userObject = new java.util.HashMap<String, Object>();
            userObject.put("user_id", Integer.valueOf(uid));
            userObject.put("name", uname);
            userObject.put("email", userEmail);
            userObject.put("role", dbRole);

            authSession.setAttribute("user", userObject);
            authSession.setAttribute("userId", Integer.valueOf(uid));
            authSession.setAttribute("userName", uname);
            authSession.setAttribute("userEmail", userEmail);
            authSession.setAttribute("userMobile", userMobile);
            authSession.setAttribute("role", dbRole);

            if ("admin".equalsIgnoreCase(dbRole)) {
                safeRedirect(response, base + "/adminDashboard.jsp");
            } else {
                safeRedirect(response, base + "/officerDashboard.jsp");
            }
            return;
        }

        String otp = String.valueOf(100000 + new SecureRandom().nextInt(900000));
        String otpHash = sha256(otp);

        boolean hasIdentifier = hasColumn(con, "otp_codes", "identifier");
        String otpRoleColumn = otpRoleColumn(con);

        StringBuilder otpSql = new StringBuilder();
        otpSql.append("INSERT INTO otp_codes(user_id, channel, otp_hash, expires_at, consumed");
        if (hasIdentifier) otpSql.append(", identifier");
        if (otpRoleColumn != null) otpSql.append(", ").append(otpRoleColumn);
        otpSql.append(") VALUES(?, 'email', ?, DATE_ADD(NOW(), INTERVAL ? MINUTE), 0");
        if (hasIdentifier) otpSql.append(", ?");
        if (otpRoleColumn != null) otpSql.append(", ?");
        otpSql.append(")");

        PreparedStatement otpPst = con.prepareStatement(otpSql.toString());
        int idx = 1;
        otpPst.setInt(idx++, uid);
        otpPst.setString(idx++, otpHash);
        otpPst.setInt(idx++, OTP_VALIDITY_MINUTES);
        if (hasIdentifier) otpPst.setString(idx++, userEmail);
        if (otpRoleColumn != null) otpPst.setString(idx++, dbRole);
        otpPst.executeUpdate();
        otpPst.close();

        final String smtpUser = ConfigLoader.getSmtpUser() == null ? null : ConfigLoader.getSmtpUser().trim();
        final String smtpPass = ConfigLoader.getSmtpPassword() == null ? null : ConfigLoader.getSmtpPassword().trim();
        final String smtpHost = ConfigLoader.getSmtpHost() == null ? null : ConfigLoader.getSmtpHost().trim();
        final String smtpPort = ConfigLoader.getSmtpPort() == null ? null : ConfigLoader.getSmtpPort().trim();

        boolean smtpConfigured = smtpUser != null && !smtpUser.trim().isEmpty() && smtpPass != null && !smtpPass.trim().isEmpty();
        if (!smtpConfigured || smtpHost == null || smtpHost.trim().isEmpty() || smtpPort == null || smtpPort.trim().isEmpty()) {
            safeRedirect(response, base + "/login.jsp?smtp=cfg");
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
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(userEmail));
            message.setSubject("Login OTP");
            message.setText("Your OTP is: " + otp);
            Transport.send(message);
        } catch (Exception mailEx) {
            application.log("Admin/Officer OTP email send failed: host=" + smtpHost + ", port=" + smtpPort + ", user=" + smtpUser, mailEx);
            safeRedirect(response, base + "/login.jsp?smtp=send");
            return;
        }

        jakarta.servlet.http.HttpSession oldSession = request.getSession(false);
        if (oldSession != null) oldSession.invalidate();
        jakarta.servlet.http.HttpSession pendingSession = request.getSession(true);
        pendingSession.setAttribute("pendingUserId", Integer.valueOf(uid));
        pendingSession.setAttribute("pendingUserName", uname);
        pendingSession.setAttribute("pendingUserEmail", userEmail);
        pendingSession.setAttribute("pendingUserMobile", userMobile);
        pendingSession.setAttribute("pendingRole", dbRole);

        safeRedirect(response, base + "/verifyOtp.jsp?sent=1&mail=1&exp=" + OTP_VALIDITY_MINUTES + "&role=" + dbRole);
        return;
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/login.jsp?error=1");
        return;
    } finally {
        if (con != null) con.close();
    }
%>