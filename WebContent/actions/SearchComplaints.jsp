<!-- Search/filter complaints -->
<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Role guard: only admin/officer
    String _role = (String) session.getAttribute("role");
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String dash = "officer".equals(_role) ? "/officerDashboard.jsp" : "/adminDashboard.jsp";
    if(_role == null || (!"admin".equals(_role) && !"officer".equals(_role))) {
        response.sendRedirect(base + "/login.jsp");
        return;
    }

    String category = request.getParameter("category");
    String status = request.getParameter("status");
    String date = request.getParameter("date"); // yyyy-MM-dd optional
    boolean includeArchive = "1".equals(request.getParameter("includeArchive"));

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        response.sendRedirect(base + "/analytics.jsp?error=db");
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

        out.println("<div class='container-3d'>");
        out.println("<h3>Filtered Complaints" + (includeArchive?" (including archive)":"") + "</h3>");
        if (date != null && !date.isEmpty()) out.println("<p><b>Date:</b> " + date + "</p>");
        if (status != null && !status.isEmpty()) out.println("<p><b>Status:</b> " + status + "</p>");
        if (category != null && !category.isEmpty()) out.println("<p><b>Category:</b> " + category + "</p>");
        out.println("<table class='table table-bordered'>");
        out.println("<tr><th>ID</th><th>Code</th><th>User</th><th>Category</th><th>Description</th><th>Address</th><th>Status</th><th>Created</th></tr>");

        while(rs.next())
        {
            out.println("<tr>");
            out.println("<td>" + rs.getInt("complaint_id") + "</td>");
            out.println("<td>" + (rs.getString("complaint_code") == null ? "-" : rs.getString("complaint_code")) + "</td>");
            out.println("<td>" + rs.getString("name") + "</td>");
            out.println("<td>" + rs.getString("category") + "</td>");
            out.println("<td>" + rs.getString("description") + "</td>");
            out.println("<td>" + rs.getString("address") + "</td>");
            out.println("<td>" + rs.getString("status") + "</td>");
            out.println("<td>" + rs.getTimestamp("created_at") + "</td>");
            out.println("</tr>");
        }
        out.println("</table>");
        out.println("<a href='" + base + dash + "'>Back to Dashboard</a>");
        out.println("</div>");
    } 
    catch(Exception e)
    {
        e.printStackTrace();
        response.sendRedirect(base + "/analytics.jsp?error=invalidFilter");
        return;
    } 
    finally 
    {
        if(con!=null) con.close();
    }
%>