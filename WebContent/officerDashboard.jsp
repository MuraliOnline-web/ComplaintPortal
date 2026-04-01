<!-- Field Officer Dashboard (WebContent) -->
<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Prevent caching so back button won't show protected page after logout
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String role = (String) session.getAttribute("role");
    if(role == null || (!role.equals("officer") && !role.equals("admin"))) {
        response.sendRedirect(base + "/login.jsp");
        return;
    }

    String searchCode = request.getParameter("code");
    String searchIdRaw = request.getParameter("id");
    boolean searchRequested = (searchCode != null && !searchCode.isBlank()) || (searchIdRaw != null && !searchIdRaw.isBlank());
    String searchMessage = null;
    boolean searchFound = false;
    String foundComplaintHtml = "";

    if (searchRequested) {
        String dbUrl = ConfigLoader.getDbUrl();
        String dbUser = ConfigLoader.getDbUser();
        String dbPassword = ConfigLoader.getDbPassword();

        if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
            searchMessage = "Database is not configured.";
        } else {
            Connection searchCon = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                searchCon = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

                PreparedStatement countPs = searchCon.prepareStatement("SELECT COUNT(*) FROM complaints");
                ResultSet countRs = countPs.executeQuery();
                int total = 0;
                if (countRs.next()) total = countRs.getInt(1);
                countRs.close();
                countPs.close();

                if (total == 0) {
                    searchMessage = "DB is empty. No complaints available.";
                } else {
                    Integer searchId = null;
                    if (searchIdRaw != null && !searchIdRaw.isBlank()) {
                        try {
                            searchId = Integer.parseInt(searchIdRaw.trim());
                        } catch (Exception ignore) {
                            searchMessage = "Invalid complaint ID format.";
                        }
                    }

                    if (searchMessage == null) {
                        String sql = "SELECT complaint_id, complaint_code, category, description, address, status, officer_notes, created_at, updated_at " +
                                     "FROM complaints WHERE 1=1" +
                                     ((searchCode != null && !searchCode.isBlank()) ? " AND complaint_code=?" : "") +
                                     ((searchId != null) ? " AND complaint_id=?" : "") +
                                     " LIMIT 1";
                        PreparedStatement ps = searchCon.prepareStatement(sql);
                        int idx = 1;
                        if (searchCode != null && !searchCode.isBlank()) ps.setString(idx++, searchCode.trim());
                        if (searchId != null) ps.setInt(idx++, searchId.intValue());
                        ResultSet rs = ps.executeQuery();

                        if (rs.next()) {
                            searchFound = true;
                            StringBuilder sb = new StringBuilder();
                            sb.append("<div class='complaint-card' style='margin-top:12px'>");
                            sb.append("<div class='complaint-header'><h4>Search Result</h4></div>");
                            sb.append("<p><strong>ID:</strong> ").append(rs.getInt("complaint_id")).append("</p>");
                            sb.append("<p><strong>Code:</strong> ").append(rs.getString("complaint_code") == null ? "-" : rs.getString("complaint_code")).append("</p>");
                            sb.append("<p><strong>Category:</strong> ").append(rs.getString("category")).append("</p>");
                            sb.append("<p><strong>Description:</strong> ").append(rs.getString("description")).append("</p>");
                            sb.append("<p><strong>Address:</strong> ").append(rs.getString("address")).append("</p>");
                            sb.append("<p><strong>Status:</strong> ").append(rs.getString("status")).append("</p>");
                            sb.append("<p><strong>Officer Notes:</strong> ").append(rs.getString("officer_notes") == null ? "-" : rs.getString("officer_notes")).append("</p>");
                            sb.append("</div>");
                            foundComplaintHtml = sb.toString();
                        } else {
                            searchMessage = "Complaint not found for given code/ID.";
                        }

                        rs.close();
                        ps.close();
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
                searchMessage = "Error while searching complaint.";
            } finally {
                if (searchCon != null) searchCon.close();
            }
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Field Officer Dashboard</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body class="bg-gradient">
    <div class="container-3d">
        <h2>🔧 Field Officer Dashboard</h2>
        <div class="card p-3 mb-3">
            <h5>Search Complaint</h5>
            <form class="row g-2" method="get" action="<%= base %>/officerDashboard.jsp">
                <div class="col-md-5">
                    <input type="text" name="code" class="form-control" placeholder="Enter Complaint Code (e.g., CMP-20250922-ABC123)" value="<%= searchCode != null ? searchCode : "" %>">
                </div>
                <div class="col-md-3">
                    <input type="number" name="id" class="form-control" placeholder="Or Complaint ID" value="<%= searchIdRaw != null ? searchIdRaw : "" %>">
                </div>
                <div class="col-md-2">
                    <button class="btn btn-primary btn-3d w-100" type="submit">Search</button>
                </div>
            </form>
            <% if (searchMessage != null) { %>
                <div class="alert alert-info" style="margin-top:10px;"><%= searchMessage %></div>
            <% } %>
            <% if (searchFound) { %>
                <%= foundComplaintHtml %>
            <% } %>
        </div>
        <% if(request.getParameter("success") != null) { %>
            <div class="alert alert-success">✅ ${param.success}</div>
        <% } %>
        <% if(request.getParameter("error") != null) { %>
            <div class="alert alert-error">❌ ${param.error}</div>
        <% } %>
        <div class="form-group">
            <h3>📋 Pending Complaints</h3>
            <div class="complaints-list">
                <%
                    String dbUrl = ConfigLoader.getDbUrl();
                    String dbUser = ConfigLoader.getDbUser();
                    String dbPassword = ConfigLoader.getDbPassword();
                    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
                        out.println("<div class='alert alert-error'>Database is not configured. Contact admin.</div>");
                    } else {
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
                        try {
                            String sql = "SELECT * FROM complaints WHERE LOWER(TRIM(status)) = 'pending' ORDER BY created_at DESC";
                            PreparedStatement ps = con.prepareStatement(sql);
                            ResultSet rs = ps.executeQuery();
                            boolean hasRows = false;
                            while(rs.next()) {
                                hasRows = true;
                %>
                <div class="complaint-card">
                    <div class="complaint-header">
                        <h4>Complaint #<%= rs.getInt("complaint_id") %> <small style="color:#6b7280">(<%= rs.getString("complaint_code") %>)</small></h4>
                        <span class="status-badge status-pending"><%= rs.getString("status") %></span>
                    </div>
                    <div class="complaint-details">
                        <p><strong>Category:</strong> <%= rs.getString("category") %></p>
                        <p><strong>Description:</strong> <%= rs.getString("description") %></p>
                        <p><strong>Address:</strong> <%= rs.getString("address") %></p>
                        <p><strong>Created:</strong> <%= rs.getTimestamp("created_at") %></p>
                        <% if(rs.getString("photo_path") != null) { %>
                            <img src="<%= rs.getString("photo_path") %>" alt="Complaint Photo" style="max-width: 200px; border-radius: 8px; margin: 10px 0;">
                        <% } %>
                    </div>
                    <form action="actions/FieldOfficerUpdate.jsp" method="post" enctype="multipart/form-data" class="update-form">
                        <input type="hidden" name="complaintId" value="<%= rs.getInt("complaint_id") %>">
                        <div class="form-group">
                            <label>Officer Name:</label>
                            <input type="text" name="officerName" class="form-control input-3d" required>
                        </div>
                        <div class="form-group">
                            <label>Visit Report Notes:</label>
                            <textarea name="officerNotes" class="form-control input-3d" rows="3" required></textarea>
                        </div>
                        <div class="form-group">
                            <label>Visit Photo (Optional):</label>
                            <div class="photo-upload">
                                <input type="file" name="reportPhoto" class="form-control input-3d" accept="image/*">
                                <p>Upload proof photo from field visit</p>
                            </div>
                        </div>
                        <div class="form-group">
                            <button type="submit" class="btn btn-success btn-3d btn-glow">Submit Report</button>
                        </div>
                    </form>
                </div>
                <%
                            }
                            if (!hasRows) {
                                out.println("<div class='alert alert-info'>No pending complaints found.</div>");
                            }
                        } catch(Exception e) { e.printStackTrace(); out.println("<div class='alert alert-error'>Error loading complaints.</div>"); }
                        finally { if(con != null) con.close(); }
                    }
                %>
            </div>
        </div>
        <div class="form-group" style="display:flex; gap:10px; flex-wrap:wrap;">
            <form method="get" action="<%= base %>/index.jsp" style="margin:0;">
                <button type="submit" class="btn btn-primary btn-3d">Back to Home</button>
            </form>
            <form method="get" action="<%= base %>/analytics.jsp" style="margin:0;">
                <button type="submit" class="btn btn-info btn-3d">View Analytics</button>
            </form>
        </div>
    </div>
    <script>
        document.querySelectorAll('.complaint-card').forEach(card => {
            card.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-5px)';
                this.style.boxShadow = '0 15px 35px rgba(0,0,0,0.1)';
            });
            card.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0)';
                this.style.boxShadow = '0 8px 32px rgba(0,0,0,0.1)';
            });
        });
    </script>
    <style>
        .complaint-card { background: white; border-radius: 16px; padding: 20px; margin: 20px 0; box-shadow: 0 8px 32px rgba(0,0,0,0.1); transition: all 0.3s ease; border-left: 4px solid var(--warning); }
        .complaint-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
        .complaint-details p { margin: 8px 0; color: #374151; }
        .update-form { margin-top: 20px; padding-top: 20px; border-top: 2px solid #e5e7eb; }
        .complaints-list { max-height: 600px; overflow-y: auto; }
    </style>
    <script src="assets/js/main.js"></script>
</body>
</html>
