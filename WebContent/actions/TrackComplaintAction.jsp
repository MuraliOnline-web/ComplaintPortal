<!-- Fetch complaint status -->
<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String email = request.getParameter("email");
    String code = request.getParameter("code");
    String idStr = request.getParameter("complaintId");
    Integer complaintId = null;
    try { if (idStr != null && !idStr.isBlank()) complaintId = Integer.parseInt(idStr.trim()); } catch(Exception ignore) {}

    if ((code == null || code.isBlank()) && complaintId == null) {
        response.sendRedirect("../trackComplaint.jsp?error=1");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        response.sendRedirect("../trackComplaint.jsp?error=db");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

    try 
    {
        // Verify complaint belongs to this user via email, match by code or id
        String sql = "SELECT c.complaint_id, c.complaint_code, c.category, c.description, c.address, c.photo_path, c.status, " +
                     "c.officer_notes, c.solved_photo_path, c.created_at, c.updated_at " +
                     "FROM complaints c JOIN users u ON c.user_id = u.user_id WHERE u.email=?" +
                     ((code != null && !code.isBlank()) ? " AND c.complaint_code=?" : "") +
                     ((complaintId != null) ? " AND c.complaint_id=?" : "");
        PreparedStatement pst = con.prepareStatement(sql);
        int idx = 1;
        pst.setString(idx++, email);
        if (code != null && !code.isBlank()) pst.setString(idx++, code.trim());
        if (complaintId != null) pst.setInt(idx++, complaintId);

        ResultSet rs = pst.executeQuery();

        out.println("<div class='container-3d'>");
        if(rs.next())
        {
            out.println("<h2>Complaint Details</h2>");
            out.println("<p><b>Complaint ID:</b> " + rs.getInt("complaint_id") + "</p>");
            out.println("<p><b>Complaint Code:</b> " + (rs.getString("complaint_code") == null ? "-" : rs.getString("complaint_code")) + "</p>");
            out.println("<p><b>Category:</b> " + rs.getString("category") + "</p>");
            out.println("<p><b>Description:</b> " + rs.getString("description") + "</p>");
            out.println("<p><b>Address:</b> " + rs.getString("address") + "</p>");
            out.println("<p><b>Status:</b> " + rs.getString("status") + "</p>");
            out.println("<p><b>Created:</b> " + rs.getTimestamp("created_at") + "</p>");
            out.println("<p><b>Last Updated:</b> " + rs.getTimestamp("updated_at") + "</p>");
            if(rs.getString("photo_path") != null)
            {
                out.println("<p><b>Uploaded Photo:</b><br><img src='../" + rs.getString("photo_path") + "' width='200'></p>");
            }
            if(rs.getString("officer_notes") != null)
            {
                out.println("<p><b>Officer Notes:</b> " + rs.getString("officer_notes") + "</p>");
            }
            if(rs.getString("solved_photo_path") != null)
            {
                out.println("<p><b>Resolved Photo:</b><br><img src='../" + rs.getString("solved_photo_path") + "' width='200'></p>");
            }

            // --- Per-complaint analytics block ---
            try {
                int _cid = rs.getInt("complaint_id");
                String _cat = rs.getString("category");
                java.sql.Timestamp createdTs = rs.getTimestamp("created_at");
                java.sql.Timestamp updatedTs = rs.getTimestamp("updated_at");
                String _status = rs.getString("status");

                long nowMs = System.currentTimeMillis();
                long createdMs = createdTs != null ? createdTs.getTime() : nowMs;
                long updatedMs = updatedTs != null ? updatedTs.getTime() : nowMs;
                long daysOpen = Math.max(0, (nowMs - createdMs) / (1000L*60*60*24));
                Long resolutionDays = null;
                if ("Solved".equalsIgnoreCase(_status)) {
                    resolutionDays = Math.max(0, (updatedMs - createdMs) / (1000L*60*60*24));
                }

                // Category stats
                PreparedStatement s1 = con.prepareStatement("SELECT COUNT(*) FROM complaints WHERE category=?");
                s1.setString(1, _cat);
                ResultSet r1 = s1.executeQuery(); r1.next(); int catTotal = r1.getInt(1);
                r1.close(); s1.close();

                PreparedStatement s2 = con.prepareStatement("SELECT COUNT(*) FROM complaints WHERE category=? AND status='Solved'");
                s2.setString(1, _cat);
                ResultSet r2 = s2.executeQuery(); r2.next(); int catSolved = r2.getInt(1);
                r2.close(); s2.close();

                PreparedStatement s3 = con.prepareStatement("SELECT AVG(TIMESTAMPDIFF(HOUR, created_at, updated_at)) FROM complaints WHERE category=? AND status='Solved'");
                s3.setString(1, _cat);
                ResultSet r3 = s3.executeQuery(); r3.next(); Double avgHours = r3.getObject(1) != null ? r3.getDouble(1) : null; 
                r3.close(); s3.close();
                Double avgDays = avgHours != null ? (avgHours / 24.0) : null;

                out.println("<hr><h3>Analysis</h3>");
                out.println("<ul>");
                out.println("<li><b>Days since created:</b> " + daysOpen + " day(s)</li>");
                if (resolutionDays != null) {
                    out.println("<li><b>Resolution time for this complaint:</b> " + resolutionDays + " day(s)</li>");
                }
                out.println("<li><b>Total in category (" + _cat + "):</b> " + catTotal + "</li>");
                out.println("<li><b>Solved in category:</b> " + catSolved + "</li>");
                out.println("<li><b>Average resolution time in category:</b> " + (avgDays == null ? "-" : String.format(java.util.Locale.US, "%.1f", avgDays) + " day(s)") + "</li>");
                out.println("</ul>");

                // Notification history (if any)
                try {
                    PreparedStatement s4 = con.prepareStatement("SELECT message, sent_at FROM notifications WHERE complaint_id=? ORDER BY sent_at ASC");
                    s4.setInt(1, _cid);
                    ResultSet r4 = s4.executeQuery();
                    boolean has = false;
                    StringBuilder sb = new StringBuilder();
                    while (r4.next()) {
                        if (!has) { sb.append("<h4>Notification History</h4><ol>"); has = true; }
                        sb.append("<li><b>").append(r4.getTimestamp("sent_at")).append(":</b> ")
                          .append(r4.getString("message") == null ? "" : r4.getString("message")).append("</li>");
                    }
                    if (has) sb.append("</ol>");
                    out.println(sb.toString());
                    r4.close(); s4.close();
                } catch (Exception ignore) { /* notifications table optional */ }
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        } 
        else 
        {
            response.sendRedirect("../trackComplaint.jsp?error=notfound");
            return;
        }
        out.println("<div style='margin-top:12px'><a class='btn btn-secondary btn-3d' href='../trackComplaint.jsp'>Back to Track</a> <a class='btn btn-primary btn-3d' href='../index.jsp'>Home</a></div>");
        out.println("</div>");
    } 
    catch(Exception e)
    {
        e.printStackTrace();
        response.sendRedirect("../trackComplaint.jsp?error=1");
        return;
    } 
    finally 
    {
        if(con!=null) con.close();
    }
%>