<%@ page import="java.sql.*" %>
<%@ page import="java.io.File" %>
<%@ page import="jakarta.servlet.http.Part" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws java.io.IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }
%>
<%
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String role = (String) session.getAttribute("role");
    if (role == null || !"admin".equals(role)) {
        safeRedirect(response, base + "/login.jsp?denied=1");
        return;
    }

    String complaintIdRaw = request.getParameter("complaintId");
    String status = request.getParameter("status");
    if (complaintIdRaw == null || complaintIdRaw.trim().isEmpty() || status == null || status.trim().isEmpty()) {
        safeRedirect(response, base + "/adminDashboard.jsp?error=invalid");
        return;
    }

    int complaintId;
    try {
        complaintId = Integer.parseInt(complaintIdRaw.trim());
    } catch (Exception ex) {
        safeRedirect(response, base + "/adminDashboard.jsp?error=invalid");
        return;
    }

    String solvedPhotoPath = null;
    try {
        Part solvedPhotoPart = request.getPart("solvedPhoto");
        if (solvedPhotoPart != null && solvedPhotoPart.getSize() > 0) {
            String original = solvedPhotoPart.getSubmittedFileName();
            String safeName = (original == null ? "solution.jpg" : original.replaceAll("[^a-zA-Z0-9._-]", "_"));
            String fileName = System.currentTimeMillis() + "_" + safeName;
            String uploadDir = application.getRealPath("/") + "assets/images/uploads/";
            File dir = new File(uploadDir);
            if (!dir.exists()) {
                dir.mkdirs();
            }
            solvedPhotoPart.write(uploadDir + fileName);
            solvedPhotoPath = "assets/images/uploads/" + fileName;
        }
    } catch (Exception ignore) {
        // proceed without photo
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/adminDashboard.jsp?error=db");
        return;
    }

    Connection con = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
        PreparedStatement pst;
        if (solvedPhotoPath != null) {
            pst = con.prepareStatement("UPDATE complaints SET status=?, solved_photo_path=? WHERE complaint_id=?");
            pst.setString(1, status);
            pst.setString(2, solvedPhotoPath);
            pst.setInt(3, complaintId);
        } else {
            pst = con.prepareStatement("UPDATE complaints SET status=? WHERE complaint_id=?");
            pst.setString(1, status);
            pst.setInt(2, complaintId);
        }
        int changed = pst.executeUpdate();
        pst.close();
        safeRedirect(response, base + "/adminDashboard.jsp?success=" + java.net.URLEncoder.encode(changed > 0 ? "Complaint updated successfully." : "No complaint updated.", "UTF-8"));
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/adminDashboard.jsp?error=update");
    } finally {
        if (con != null) {
            try { con.close(); } catch (Exception ignore) {}
        }
    }
%>
