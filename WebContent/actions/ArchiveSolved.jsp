<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws java.io.IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }
%>
<%
    // Role guard: only admin/officer
    String role = (String) session.getAttribute("role");
    if(role == null || (!"admin".equals(role) && !"officer".equals(role))) {
        safeRedirect(response, "../login.jsp");
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
        safeRedirect(response, "../analytics.jsp?error=invalidFilter");
        return;
    }

    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        safeRedirect(response, "../analytics.jsp?error=db");
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

        out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1'>");
        out.println("<title>Archive Completed</title><link rel='stylesheet' href='../assets/css/style.css'><link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css' crossorigin='anonymous'><style>body.result-page{min-height:100vh;background:radial-gradient(circle at top left, rgba(79,70,229,.14), transparent 30%),radial-gradient(circle at bottom right, rgba(14,165,233,.1), transparent 32%),linear-gradient(180deg,#f8fafc 0%,#eef2ff 100%);} .result-card{border:1px solid rgba(148,163,184,.2);border-radius:28px;background:rgba(255,255,255,.9);box-shadow:0 24px 80px rgba(15,23,42,.08);}</style></head><body class='result-page'>");
        out.println("<main class='container py-4 py-lg-5'><div class='result-card p-4 p-md-5'><div class='text-uppercase small fw-semibold text-primary'>Archive completed</div><h1 class='h2 fw-bold mb-2'>Archive Completed</h1><p class='text-secondary'>Time window: <b>" + start + "</b> to <b>" + end + "</b></p><div class='row g-3'><div class='col-md-4'><div class='border rounded-4 p-3 bg-white'><div class='text-secondary small'>Solved complaints moved</div><div class='fw-bold fs-4'>" + movedComplaints + "</div></div></div><div class='col-md-4'><div class='border rounded-4 p-3 bg-white'><div class='text-secondary small'>Notifications moved</div><div class='fw-bold fs-4'>" + movedNotifs + "</div></div></div></div><div class='mt-4'><a class='btn btn-secondary' href='../analytics.jsp?g=" + g + ("day".equals(g)?("&date="+ (date==null?today.toString():date)): ("month".equals(g)?("&month="+(month==null?java.time.YearMonth.from(today).toString():month)):"&year="+(year==null?String.valueOf(today.getYear()):year))) + "'>Back to Analytics</a></div></div></main><script src='https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js' crossorigin='anonymous'></script></body></html>");
    } catch(Exception e) {
        con.rollback();
        e.printStackTrace();
        safeRedirect(response, "../analytics.jsp?error=invalidFilter");
        return;
    } finally {
        con.setAutoCommit(true);
        if (con!=null) con.close();
    }
%>
