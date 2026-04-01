<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Role guard: only admin/officer
    String role = (String) session.getAttribute("role");
    if(role == null || (!"admin".equals(role) && !"officer".equals(role))) {
        response.sendRedirect("../login.jsp");
        return;
    }

    // Parameters: granularity g=day|month|year, and date/month/year
    String g = request.getParameter("g");
    if (g == null || g.isBlank()) g = "day";
    String date = request.getParameter("date");      // yyyy-MM-dd
    String month = request.getParameter("month");    // yyyy-MM
    String year = request.getParameter("year");      // yyyy

    // Compute time window [start, end]
    String start = null, end = null; // inclusive start, exclusive end for safety
    java.time.LocalDate today = java.time.LocalDate.now();
    try {
        if ("day".equals(g)) {
            java.time.LocalDate d = (date==null||date.isBlank()) ? today : java.time.LocalDate.parse(date);
            start = d.toString() + " 00:00:00";
            end   = d.toString() + " 23:59:59";
        } else if ("month".equals(g)) {
            java.time.YearMonth ym = (month==null||month.isBlank()) ? java.time.YearMonth.from(today) : java.time.YearMonth.parse(month);
            start = ym.atDay(1).toString() + " 00:00:00";
            end   = ym.atEndOfMonth().toString() + " 23:59:59";
        } else { // year
            int y = (year==null||year.isBlank()) ? today.getYear() : Integer.parseInt(year);
            start = java.time.LocalDate.of(y,1,1).toString() + " 00:00:00";
            end   = java.time.LocalDate.of(y,12,31).toString() + " 23:59:59";
        }
    } catch (Exception ex) {
        response.sendRedirect("../analytics.jsp?error=invalidFilter");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        response.sendRedirect("../analytics.jsp?error=db");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
    con.setAutoCommit(false);
    int movedComplaints = 0, movedNotifs = 0;
    try {
        // 1) Move solved complaints in window to archive
        PreparedStatement selIds = con.prepareStatement(
            "SELECT complaint_id FROM complaints WHERE status='Solved' AND created_at BETWEEN ? AND ?"
        );
        selIds.setString(1, start);
        selIds.setString(2, end);
        ResultSet rsIds = selIds.executeQuery();
        java.util.ArrayList<Integer> ids = new java.util.ArrayList<>();
        while (rsIds.next()) ids.add(rsIds.getInt(1));
        rsIds.close(); selIds.close();

        if (!ids.isEmpty()) {
            // Insert complaints into archive
            PreparedStatement insComp = con.prepareStatement(
                "INSERT INTO complaints_archive SELECT * FROM complaints WHERE complaint_id IN (" +
                ids.toString().replace('[','(').replace(']',')') + ")"
            );
            movedComplaints = insComp.executeUpdate();
            insComp.close();

            // Insert notifications into archive
            PreparedStatement insNotif = con.prepareStatement(
                "INSERT INTO notifications_archive SELECT * FROM notifications WHERE complaint_id IN (" +
                ids.toString().replace('[','(').replace(']',')') + ")"
            );
            movedNotifs = insNotif.executeUpdate();
            insNotif.close();

            // Delete notifications then complaints from live tables
            PreparedStatement delNotif = con.prepareStatement(
                "DELETE FROM notifications WHERE complaint_id IN (" +
                ids.toString().replace('[','(').replace(']',')') + ")"
            );
            delNotif.executeUpdate();
            delNotif.close();

            PreparedStatement delComp = con.prepareStatement(
                "DELETE FROM complaints WHERE complaint_id IN (" +
                ids.toString().replace('[','(').replace(']',')') + ")"
            );
            delComp.executeUpdate();
            delComp.close();
        }
        con.commit();

        out.println("<div class='container-3d'>");
        out.println("<h3>Archive Completed</h3>");
        out.println("<p>Time window: <b>" + start + "</b> to <b>" + end + "</b></p>");
        out.println("<p>Solved complaints moved: <b>" + movedComplaints + "</b></p>");
        out.println("<p>Notifications moved: <b>" + movedNotifs + "</b></p>");
        out.println("<a class='btn btn-secondary btn-3d' href='../analytics.jsp?g=" + g + ("day".equals(g)?"&date="+ (date==null?today.toString():date): ("month".equals(g)?"&month="+(month==null?java.time.YearMonth.from(today).toString():month):"&year="+(year==null?String.valueOf(today.getYear()):year))) + "'>Back to Analytics</a>");
        out.println("</div>");
    } catch(Exception e) {
        con.rollback();
        e.printStackTrace();
        response.sendRedirect("../analytics.jsp?error=invalidFilter");
        return;
    } finally {
        con.setAutoCommit(true);
        if (con!=null) con.close();
    }
%>
