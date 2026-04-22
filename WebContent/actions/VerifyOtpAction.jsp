<%@ page import="java.sql.*" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.util.HashMap" %>
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
    Integer pendingUserId = (Integer) session.getAttribute("pendingUserId");
    String pendingRole = (String) session.getAttribute("pendingRole");
    String pendingEmail = (String) session.getAttribute("pendingUserEmail");
    String requestedRole = request.getParameter("role");
    String requestedEmail = request.getParameter("email");
    String otp = request.getParameter("otp");

    String resolvedRole = requestedRole != null && !requestedRole.trim().isEmpty()
        ? requestedRole.trim().toLowerCase()
        : (pendingRole != null && !pendingRole.trim().isEmpty() ? pendingRole.trim().toLowerCase() : "user");
    String resolvedEmail = requestedEmail != null && !requestedEmail.trim().isEmpty()
        ? requestedEmail.trim().toLowerCase()
        : (pendingEmail == null ? null : pendingEmail.trim().toLowerCase());

    if (pendingUserId == null) {
        if ("admin".equals(resolvedRole) || "officer".equals(resolvedRole)) {
            safeRedirect(response, "../login.jsp?required=1");
        } else {
            safeRedirect(response, "../userLogin.jsp?required=1");
        }
        return;
    }
    if (otp == null || otp.trim().isEmpty()) {
        safeRedirect(response, "../verifyOtp.jsp?error=1&reason=invalid");
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
        boolean hasIdentifier = hasColumn(con, "otp_codes", "identifier");
        String otpRoleColumn = otpRoleColumn(con);

        StringBuilder validSql = new StringBuilder();
        validSql.append("SELECT otp_id FROM otp_codes WHERE user_id=? AND channel='email' AND consumed=0 AND expires_at >= NOW() AND otp_hash=?");
        if (hasIdentifier && resolvedEmail != null && !resolvedEmail.isEmpty()) {
            validSql.append(" AND identifier=?");
        }
        if (otpRoleColumn != null && resolvedRole != null && !resolvedRole.isEmpty()) {
            validSql.append(" AND ").append(otpRoleColumn).append("=?");
        }
        validSql.append(" ORDER BY otp_id DESC LIMIT 1");

        PreparedStatement pst = con.prepareStatement(validSql.toString());
        int idx = 1;
        pst.setInt(idx++, pendingUserId.intValue());
        pst.setString(idx++, otpHash);
        if (hasIdentifier && resolvedEmail != null && !resolvedEmail.isEmpty()) {
            pst.setString(idx++, resolvedEmail);
        }
        if (otpRoleColumn != null && resolvedRole != null && !resolvedRole.isEmpty()) {
            pst.setString(idx++, resolvedRole);
        }
        ResultSet rs = pst.executeQuery();

        if (!rs.next()) {
            StringBuilder expiredSql = new StringBuilder();
            expiredSql.append("SELECT otp_id, expires_at FROM otp_codes WHERE user_id=? AND channel='email' AND consumed=0 AND otp_hash=?");
            if (hasIdentifier && resolvedEmail != null && !resolvedEmail.isEmpty()) {
                expiredSql.append(" AND identifier=?");
            }
            if (otpRoleColumn != null && resolvedRole != null && !resolvedRole.isEmpty()) {
                expiredSql.append(" AND ").append(otpRoleColumn).append("=?");
            }
            expiredSql.append(" ORDER BY otp_id DESC LIMIT 1");

            PreparedStatement expiredPst = con.prepareStatement(expiredSql.toString());
            int eIdx = 1;
            expiredPst.setInt(eIdx++, pendingUserId.intValue());
            expiredPst.setString(eIdx++, otpHash);
            if (hasIdentifier && resolvedEmail != null && !resolvedEmail.isEmpty()) {
                expiredPst.setString(eIdx++, resolvedEmail);
            }
            if (otpRoleColumn != null && resolvedRole != null && !resolvedRole.isEmpty()) {
                expiredPst.setString(eIdx++, resolvedRole);
            }
            ResultSet expiredRs = expiredPst.executeQuery();
            if (expiredRs.next()) {
                Timestamp expiresAt = expiredRs.getTimestamp("expires_at");
                Timestamp now = new Timestamp(System.currentTimeMillis());
                if (expiresAt != null && expiresAt.before(now)) {
                    safeRedirect(response, "../verifyOtp.jsp?error=1&reason=expired");
                    return;
                }
            }
            safeRedirect(response, "../verifyOtp.jsp?error=1&reason=invalid");
            return;
        }

        int otpId = rs.getInt("otp_id");
        PreparedStatement upd = con.prepareStatement("UPDATE otp_codes SET consumed=1 WHERE otp_id=?");
        upd.setInt(1, otpId);
        upd.executeUpdate();
        upd.close();

        String pendingUserName = (String) session.getAttribute("pendingUserName");
        String pendingUserMobile = (String) session.getAttribute("pendingUserMobile");

        jakarta.servlet.http.HttpSession oldSession = request.getSession(false);
        if (oldSession != null) oldSession.invalidate();
        jakarta.servlet.http.HttpSession authSession = request.getSession(true);

        HashMap<String, Object> userObject = new HashMap<String, Object>();
        userObject.put("user_id", pendingUserId);
        userObject.put("name", pendingUserName);
        userObject.put("email", resolvedEmail);
        userObject.put("mobile", pendingUserMobile);
        userObject.put("role", resolvedRole);

        authSession.setAttribute("user", userObject);
        authSession.setAttribute("userId", pendingUserId);
        authSession.setAttribute("userName", pendingUserName);
        authSession.setAttribute("userEmail", resolvedEmail);
        authSession.setAttribute("userMobile", pendingUserMobile);
        authSession.setAttribute("role", resolvedRole);

        if ("admin".equals(resolvedRole)) {
            safeRedirect(response, "../adminDashboard.jsp");
        } else if ("officer".equals(resolvedRole)) {
            safeRedirect(response, "../officerDashboard.jsp");
        } else {
            safeRedirect(response, "../userDashboard.jsp");
        }
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, "../verifyOtp.jsp?error=1");
    } finally {
        if (con != null) con.close();
    }
%>
