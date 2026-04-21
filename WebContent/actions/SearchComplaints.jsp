<!-- Search/filter complaints -->
<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws java.io.IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    String assetsBase = base;
    try {
        if (application.getResource("/assets/css/style.css") == null && application.getResource("/WebContent/assets/css/style.css") != null) {
            assetsBase = ctx + "/WebContent";
        }
    } catch (Exception ignore) {
        // Keep computed base.
    }
    }
%>
<%
    // Role guard: only admin/officer
    String _role = (String) session.getAttribute("role");
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String dash = "officer".equals(_role) ? "/officerDashboard.jsp" : "/adminDashboard.jsp";
    if(_role == null || (!"admin".equals(_role) && !"officer".equals(_role))) {
        safeRedirect(response, base + "/login.jsp");
        return;
    }

    String category = request.getParameter("category");
    String status = request.getParameter("status");
    String date = request.getParameter("date"); // yyyy-MM-dd optional
    boolean includeArchive = "1".equals(request.getParameter("includeArchive"));

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/analytics.jsp?error=db");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

    try 
    {
        StringBuilder where = new StringBuilder(" WHERE 1=1 ");
        java.util.List<Object> params = new java.util.ArrayList<>();
        if (category != null && !category.isEmpty()) { where.append(" AND c.category=?"); params.add(category); }
        if (status != null && !status.isEmpty())   { where.append(" AND c.status=?"); params.add(status); }
        if (date != null && !date.isEmpty())       { where.append(" AND DATE(c.created_at)=?"); params.add(date); }

        String baseSelect = "SELECT c.complaint_id, c.complaint_code, u.name, c.category, c.description, c.address, c.status, c.created_at "+
                            "FROM %s c JOIN users u ON c.user_id = u.user_id";
        String sql;
        if (includeArchive) {
            sql = String.format(baseSelect, "complaints") + where.toString() +
                  " UNION ALL " +
                  String.format(baseSelect, "complaints_archive") + where.toString() +
                  " ORDER BY created_at DESC";
        } else {
            sql = String.format(baseSelect, "complaints") + where.toString() + " ORDER BY c.created_at DESC";
        }

        PreparedStatement pst = con.prepareStatement(sql);
        int idx = 1;
        // bind params for live
        for (Object p : params) pst.setObject(idx++, p);
        // bind params for archive (same order) if included
        if (includeArchive) {
            for (Object p : params) pst.setObject(idx++, p);
        }
        ResultSet rs = pst.executeQuery();

        out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1'>");
        out.println("<title>Filtered Complaints</title><link rel='stylesheet' href='" + assetsBase + "/assets/css/style.css'><link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css' crossorigin='anonymous'><style>body.result-page{min-height:100vh;background:radial-gradient(circle at top left, rgba(79,70,229,.14), transparent 30%),radial-gradient(circle at bottom right, rgba(14,165,233,.1), transparent 32%),linear-gradient(180deg,#f8fafc 0%,#eef2ff 100%);} .result-card{border:1px solid rgba(148,163,184,.2);border-radius:28px;background:rgba(255,255,255,.9);box-shadow:0 24px 80px rgba(15,23,42,.08);}</style></head><body class='result-page'>");
        out.println("<main class='container py-4 py-lg-5'><div class='result-card p-4 p-md-5'><div class='d-flex flex-wrap justify-content-between align-items-start gap-3 mb-4'><div><div class='text-uppercase small fw-semibold text-primary'>Search results</div><h1 class='h2 fw-bold mb-2'>Filtered Complaints" + (includeArchive ? " (including archive)" : "") + "</h1><p class='text-secondary mb-0'>Matched complaints for the chosen filters.</p></div><a class='btn btn-outline-primary' href='" + base + dash + "'>Back to Dashboard</a></div>");
        if (date != null && !date.isEmpty()) out.println("<p><b>Date:</b> " + date + "</p>");
        if (status != null && !status.isEmpty()) out.println("<p><b>Status:</b> " + status + "</p>");
        if (category != null && !category.isEmpty()) out.println("<p><b>Category:</b> " + category + "</p>");
        out.println("<div class='table-responsive'><table class='table align-middle'><thead><tr><th>ID</th><th>Code</th><th>User</th><th>Category</th><th>Description</th><th>Address</th><th>Status</th><th>Created</th></tr></thead><tbody>");

        boolean any = false;
        while(rs.next())
        {
            any = true;
            out.println("<tr>");
            out.println("<td class='fw-semibold'>" + rs.getInt("complaint_id") + "</td>");
            out.println("<td>" + (rs.getString("complaint_code") == null ? "-" : rs.getString("complaint_code")) + "</td>");
            out.println("<td>" + rs.getString("name") + "</td>");
            out.println("<td>" + rs.getString("category") + "</td>");
            out.println("<td>" + rs.getString("description") + "</td>");
            out.println("<td>" + rs.getString("address") + "</td>");
            out.println("<td>" + rs.getString("status") + "</td>");
            out.println("<td>" + rs.getTimestamp("created_at") + "</td>");
            out.println("</tr>");
        }
        if (!any) {
            out.println("<tr><td colspan='8' class='text-center text-secondary py-4'>No complaints matched the filters.</td></tr>");
        }
        out.println("</tbody></table></div></div></main><script src='https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js' crossorigin='anonymous'></script></body></html>");
    } 
    catch(Exception e)
    {
        e.printStackTrace();
        safeRedirect(response, base + "/analytics.jsp?error=invalidFilter");
        return;
    } 
    finally 
    {
        if(con!=null) con.close();
    }
%>