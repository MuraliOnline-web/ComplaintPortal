<!-- User Dashboard JSP (WebContent) -->
<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String role = (String) session.getAttribute("role");
    if(role == null || !role.equals("user")) {
        response.sendRedirect("userLogin.jsp?required=1");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>User Dashboard</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" integrity="sha384-gH6tQd6rYt6v7s5FQ4u+Nw6mM2J+Z1oQXbQ9yKqNqCkzJ10c1qf6jv9vZ5GxXKbi" crossorigin="anonymous">
</head>
<body>
    <div class="container-3d">
        <h2>Welcome, <%=session.getAttribute("userName")%>!</h2>
        <h3>Your Complaints</h3>
        <div class="form-group">
            <a href="registerComplaint.jsp" class="btn btn-primary btn-3d">Register New Complaint</a>
            <a href="trackComplaint.jsp" class="btn btn-info btn-3d">Track Complaint</a>
        </div>
        <table class="table table-bordered">
            <tr>
                <th>ID</th><th>Category</th><th>Description</th><th>Address</th><th>Status</th><th>Created Date</th>
            </tr>
            <%
                String dbUrl = ConfigLoader.getDbUrl();
                String dbUser = ConfigLoader.getDbUser();
                String dbPassword = ConfigLoader.getDbPassword();
                if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
                    out.println("<tr><td colspan='6'>Database is not configured. Contact admin.</td></tr>");
                } else {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
                    try {
                        int userId = (Integer) session.getAttribute("userId");
                        PreparedStatement pst = con.prepareStatement(
                            "SELECT * FROM complaints WHERE user_id = ? ORDER BY created_at DESC"
                        );
                        pst.setInt(1, userId);
                        ResultSet rs = pst.executeQuery();
                        while(rs.next()){
            %>
            <tr>
                <td><%=rs.getInt("complaint_id")%></td>
                <td><%=rs.getString("category")%></td>
                <td><%=rs.getString("description")%></td>
                <td><%=rs.getString("address")%></td>
                <td>
                    <span class="status-badge status-<%=rs.getString("status").toLowerCase()%>">
                        <%=rs.getString("status")%>
                    </span>
                </td>
                <td><%=rs.getTimestamp("created_at")%></td>
            </tr>
            <%
                        }
                    } catch(Exception e) { e.printStackTrace(); out.println("<tr><td colspan='6'>Error fetching complaints.</td></tr>"); }
                    finally { if(con!=null) con.close(); }
                }
            %>
        </table>
        <div class="form-group">
            <a href="index.jsp" class="btn btn-primary btn-3d">Back to Home</a>
        </div>
    </div>
    <style>
        .status-badge { padding: 4px 12px; border-radius: 20px; font-weight: bold; text-transform: uppercase; font-size: 12px; }
        .status-pending { background: linear-gradient(135deg, #fef3c7, #fde68a); color: #92400e; }
        .status-solving { background: linear-gradient(135deg, #dbeafe, #bfdbfe); color: #1e40af; }
        .status-solved { background: linear-gradient(135deg, #d1fae5, #a7f3d0); color: #065f46; }
        .table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 8px 32px rgba(0,0,0,0.1); }
        .table th, .table td { padding: 12px 16px; text-align: left; border-bottom: 1px solid #e5e7eb; }
        .table th { background: linear-gradient(135deg, #f8fafc, #e2e8f0); font-weight: 600; color: #374151; }
        .table tr:hover { background: #f8fafc; }
    </style>
</body>
</html>
