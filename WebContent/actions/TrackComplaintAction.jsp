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

        if(rs.next())
        {
            request.setAttribute("complaintId", rs.getInt("complaint_id"));
            request.setAttribute("complaintCode", rs.getString("complaint_code"));
            request.setAttribute("category", rs.getString("category"));
            request.setAttribute("description", rs.getString("description"));
            request.setAttribute("address", rs.getString("address"));
            request.setAttribute("photoPath", rs.getString("photo_path"));
            request.setAttribute("status", rs.getString("status"));
            request.setAttribute("officerNotes", rs.getString("officer_notes"));
            request.setAttribute("solvedPhotoPath", rs.getString("solved_photo_path"));
            request.setAttribute("createdAt", rs.getTimestamp("created_at"));
            request.setAttribute("updatedAt", rs.getTimestamp("updated_at"));
            request.getRequestDispatcher("../trackResult.jsp").forward(request, response);
            return;
        }
        else
        {
            response.sendRedirect("../trackComplaint.jsp?error=notfound");
            return;
        }
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