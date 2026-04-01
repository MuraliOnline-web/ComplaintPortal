<%@ page import="java.sql.*" %>
<%@ page import="java.util.Properties" %>
<%@ page import="jakarta.mail.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static String mask(String value) {
        if (value == null) return "(missing)";
        if (value.isBlank()) return "(blank)";
        if (value.length() <= 4) return "****";
        return value.substring(0, 2) + "****" + value.substring(value.length() - 2);
    }
%>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;

    String role = (String) session.getAttribute("role");
    if (role == null || !"admin".equals(role)) {
        response.sendRedirect(base + "/login.jsp?denied=1");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();

    String smtpHost = ConfigLoader.getSmtpHost();
    String smtpPort = ConfigLoader.getSmtpPort();
    String smtpUser = ConfigLoader.getSmtpUser();
    String smtpPassword = ConfigLoader.getSmtpPassword();

    boolean dbConfigured = dbUrl != null && !dbUrl.isBlank() && dbUser != null && !dbUser.isBlank() && dbPassword != null && !dbPassword.isBlank();
    boolean smtpConfigured = smtpHost != null && !smtpHost.isBlank() && smtpPort != null && !smtpPort.isBlank() && smtpUser != null && !smtpUser.isBlank() && smtpPassword != null && !smtpPassword.isBlank();

    String runDb = request.getParameter("dbtest");
    String runSmtp = request.getParameter("smtptest");

    String dbTestStatus = "Not run";
    String dbTestDetail = "";
    if ("1".equals(runDb)) {
        if (!dbConfigured) {
            dbTestStatus = "Failed";
            dbTestDetail = "DB configuration is incomplete.";
        } else {
            Connection checkCon = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                checkCon = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
                dbTestStatus = "Success";
                dbTestDetail = "Database connection opened successfully.";
            } catch (Exception ex) {
                dbTestStatus = "Failed";
                dbTestDetail = ex.getClass().getSimpleName() + ": " + ex.getMessage();
            } finally {
                try { if (checkCon != null) checkCon.close(); } catch (Exception ignore) {}
            }
        }
    }

    String smtpTestStatus = "Not run";
    String smtpTestDetail = "";
    if ("1".equals(runSmtp)) {
        if (!smtpConfigured) {
            smtpTestStatus = "Failed";
            smtpTestDetail = "SMTP configuration is incomplete.";
        } else {
            Transport transport = null;
            try {
                Properties props = new Properties();
                props.put("mail.smtp.auth", "true");
                props.put("mail.smtp.starttls.enable", "true");
                props.put("mail.smtp.host", smtpHost);
                props.put("mail.smtp.port", smtpPort);
                Session mailSession = Session.getInstance(props);
                transport = mailSession.getTransport("smtp");
                transport.connect(smtpHost, Integer.parseInt(smtpPort), smtpUser, smtpPassword);
                smtpTestStatus = "Success";
                smtpTestDetail = "SMTP login/connect successful.";
            } catch (Exception ex) {
                smtpTestStatus = "Failed";
                smtpTestDetail = ex.getClass().getSimpleName() + ": " + ex.getMessage();
            } finally {
                try { if (transport != null) transport.close(); } catch (Exception ignore) {}
            }
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Config Health Check</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" integrity="sha384-gH6tQd6rYt6v7s5FQ4u+Nw6mM2J+Z1oQXbQ9yKqNqCkzJ10c1qf6jv9vZ5GxXKbi" crossorigin="anonymous">
</head>
<body>
    <div class="container-3d">
        <h2>Configuration Health Check</h2>
        <p>This page is admin-only and masks secret values.</p>

        <div class="card p-3 mb-3">
            <h5>Database Config</h5>
            <p><b>Configured:</b> <%= dbConfigured ? "Yes" : "No" %></p>
            <p><b>DB_URL:</b> <%= mask(dbUrl) %></p>
            <p><b>DB_USER:</b> <%= mask(dbUser) %></p>
            <p><b>DB_PASSWORD:</b> <%= mask(dbPassword) %></p>
            <p><b>DB Test:</b> <%= dbTestStatus %></p>
            <% if (!dbTestDetail.isBlank()) { %>
                <p><b>DB Detail:</b> <%= dbTestDetail %></p>
            <% } %>
            <button type="button" class="btn btn-primary btn-3d" onclick="window.location.href='<%= base %>/adminConfigHealth.jsp?dbtest=1';">Run DB Connectivity Test</button>
        </div>

        <div class="card p-3 mb-3">
            <h5>SMTP Config</h5>
            <p><b>Configured:</b> <%= smtpConfigured ? "Yes" : "No" %></p>
            <p><b>SMTP_HOST:</b> <%= mask(smtpHost) %></p>
            <p><b>SMTP_PORT:</b> <%= mask(smtpPort) %></p>
            <p><b>SMTP_USER:</b> <%= mask(smtpUser) %></p>
            <p><b>SMTP_PASSWORD:</b> <%= mask(smtpPassword) %></p>
            <p><b>SMTP Test:</b> <%= smtpTestStatus %></p>
            <% if (!smtpTestDetail.isBlank()) { %>
                <p><b>SMTP Detail:</b> <%= smtpTestDetail %></p>
            <% } %>
            <button type="button" class="btn btn-primary btn-3d" onclick="window.location.href='<%= base %>/adminConfigHealth.jsp?smtptest=1';">Run SMTP Connectivity Test</button>
        </div>

        <div class="form-group" style="display:flex; gap:10px; flex-wrap:wrap;">
            <button type="button" class="btn btn-secondary btn-3d" onclick="window.location.href='<%= base %>/adminDashboard.jsp';">Back to Admin Dashboard</button>
            <button type="button" class="btn btn-primary btn-3d" onclick="window.location.href='<%= base %>/index.jsp';">Back to Home</button>
        </div>
    </div>
    <script src="assets/js/main.js"></script>
</body>
</html>
