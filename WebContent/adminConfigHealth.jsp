<%@ page import="java.sql.*" %>
<%@ page import="java.util.Properties" %>
<%@ page import="jakarta.mail.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static String mask(String value) {
        if (value == null) return "(missing)";
        if (value.trim().isEmpty()) return "(blank)";
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
    String homeHref = base + "/index.jsp";
    String dashboardHref = base + "/adminDashboard.jsp";
    String logoutHref = base + "/actions/LogoutAction.jsp";
    String styleHref = base + "/assets/css/style.css";
    String scriptHref = base + "/assets/js/main.js";
    String logoHref = base + "/assets/images/logo.svg";
    try {
        if (application.getResource("/index.jsp") != null) homeHref = ctx + "/index.jsp";
        if (application.getResource("/adminDashboard.jsp") != null) dashboardHref = ctx + "/adminDashboard.jsp";
        if (application.getResource("/actions/LogoutAction.jsp") != null) logoutHref = ctx + "/actions/LogoutAction.jsp";
        if (application.getResource("/assets/css/style.css") != null) styleHref = ctx + "/assets/css/style.css";
        if (application.getResource("/assets/js/main.js") != null) scriptHref = ctx + "/assets/js/main.js";
        if (application.getResource("/assets/images/logo.svg") != null) logoHref = ctx + "/assets/images/logo.svg";
    } catch (Exception ignore) {
        // Use computed fallbacks.
    }
    String role = (String) session.getAttribute("role");
    if (role == null || !"admin".equals(role)) { response.sendRedirect(base + "/login.jsp?denied=1"); return; }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    String smtpHost = ConfigLoader.getSmtpHost();
    String smtpPort = ConfigLoader.getSmtpPort();
    String smtpUser = ConfigLoader.getSmtpUser();
    String smtpPassword = ConfigLoader.getSmtpPassword();
    boolean dbConfigured = dbUrl != null && !dbUrl.trim().isEmpty() && dbUser != null && !dbUser.trim().isEmpty() && dbPassword != null && !dbPassword.trim().isEmpty();
    boolean smtpConfigured = smtpHost != null && !smtpHost.trim().isEmpty() && smtpPort != null && !smtpPort.trim().isEmpty() && smtpUser != null && !smtpUser.trim().isEmpty() && smtpPassword != null && !smtpPassword.trim().isEmpty();

    String runDb = request.getParameter("dbtest");
    String runSmtp = request.getParameter("smtptest");
    String dbTestStatus = "Not run";
    String dbTestDetail = "";
    if ("1".equals(runDb)) {
        if (!dbConfigured) { dbTestStatus = "Failed"; dbTestDetail = "DB configuration is incomplete."; }
        else {
            Connection checkCon = null;
            try { Class.forName("com.mysql.cj.jdbc.Driver"); checkCon = DriverManager.getConnection(dbUrl, dbUser, dbPassword); dbTestStatus = "Success"; dbTestDetail = "Database connection opened successfully."; }
            catch (Exception ex) { dbTestStatus = "Failed"; dbTestDetail = ex.getClass().getSimpleName() + ": " + ex.getMessage(); }
            finally { try { if (checkCon != null) checkCon.close(); } catch (Exception ignore) {} }
        }
    }

    String smtpTestStatus = "Not run";
    String smtpTestDetail = "";
    if ("1".equals(runSmtp)) {
        if (!smtpConfigured) { smtpTestStatus = "Failed"; smtpTestDetail = "SMTP configuration is incomplete."; }
        else {
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
            } catch (Exception ex) { smtpTestStatus = "Failed"; smtpTestDetail = ex.getClass().getSimpleName() + ": " + ex.getMessage(); }
            finally { try { if (transport != null) transport.close(); } catch (Exception ignore) {} }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Config Health Check</title>
    <link rel="stylesheet" href="<%= styleHref %>">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.dashboard-page { min-height: 100vh; background: radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 30%), radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.1), transparent 32%), linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%); }
        .dashboard-card { border: 1px solid rgba(148, 163, 184, 0.2); border-radius: 24px; background: rgba(255, 255, 255, 0.88); box-shadow: 0 20px 60px rgba(15, 23, 42, 0.07); }
    </style>
</head>
<body class="dashboard-page">
    <nav class="navbar navbar-expand-lg bg-white bg-opacity-75 backdrop-blur-sm sticky-top border-bottom border-light-subtle">
        <div class="container py-2">
            <a class="navbar-brand fw-bold d-flex align-items-center gap-2" href="<%= homeHref %>"><img src="<%= logoHref %>" alt="Complaint Portal" style="width:40px;height:40px;border-radius:12px;object-fit:cover;"><span>Complaint Portal</span></a>
            <div class="ms-auto d-flex gap-2"><a href="<%= dashboardHref %>" class="btn btn-outline-primary">Admin Dashboard</a><a href="<%= logoutHref %>" class="btn btn-outline-danger" data-confirm-logout data-confirm-message="You are about to log out of the admin tools page." data-logout-url="<%= logoutHref %>">Logout</a></div>
        </div>
    </nav>

    <main class="container py-4 py-lg-5">
        <div class="dashboard-card p-4 p-lg-5 mb-4">
            <div class="text-uppercase small fw-semibold text-primary">Health Check</div>
            <h1 class="h2 fw-bold mb-2">Configuration Health Check</h1>
            <p class="text-secondary mb-0">This page is admin-only and masks secret values.</p>
        </div>

        <div class="row g-4">
            <div class="col-lg-6"><div class="dashboard-card p-4 h-100"><h2 class="h4 fw-bold mb-3">Database Config</h2><p><b>Configured:</b> <%= dbConfigured ? "Yes" : "No" %></p><p><b>DB_URL:</b> <%= mask(dbUrl) %></p><p><b>DB_USER:</b> <%= mask(dbUser) %></p><p><b>DB_PASSWORD:</b> <%= mask(dbPassword) %></p><p><b>DB Test:</b> <%= dbTestStatus %></p><% if (!dbTestDetail.trim().isEmpty()) { %><p><b>DB Detail:</b> <%= dbTestDetail %></p><% } %><button type="button" class="btn btn-primary" onclick="window.location.href='<%= base %>/adminConfigHealth.jsp?dbtest=1';">Run DB Connectivity Test</button></div></div>
            <div class="col-lg-6"><div class="dashboard-card p-4 h-100"><h2 class="h4 fw-bold mb-3">SMTP Config</h2><p><b>Configured:</b> <%= smtpConfigured ? "Yes" : "No" %></p><p><b>SMTP_HOST:</b> <%= mask(smtpHost) %></p><p><b>SMTP_PORT:</b> <%= mask(smtpPort) %></p><p><b>SMTP_USER:</b> <%= mask(smtpUser) %></p><p><b>SMTP_PASSWORD:</b> <%= mask(smtpPassword) %></p><p><b>SMTP Test:</b> <%= smtpTestStatus %></p><% if (!smtpTestDetail.trim().isEmpty()) { %><p><b>SMTP Detail:</b> <%= smtpTestDetail %></p><% } %><button type="button" class="btn btn-primary" onclick="window.location.href='<%= base %>/adminConfigHealth.jsp?smtptest=1';">Run SMTP Connectivity Test</button></div></div>
        </div>

        <div class="d-flex flex-wrap gap-2 mt-4"><button type="button" class="btn btn-secondary" onclick="window.location.href='<%= dashboardHref %>';">Back to Admin Dashboard</button><button type="button" class="btn btn-primary" onclick="window.location.href='<%= homeHref %>';">Back to Home</button></div>
    </main>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="<%= scriptHref %>"></script>
</body>
</html>