<!-- Analytics (WebContent) -->
<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Role guard: only admin/officer
    String __role = (String) session.getAttribute("role");
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    if(__role == null || (!"admin".equals(__role) && !"officer".equals(__role))) {
        response.sendRedirect(base + "/login.jsp");
        return;
    }
    // Granularity: day (default), month, year
    String g = request.getParameter("g");
    if (g == null || g.isBlank()) g = "day"; // day|month|year
    if (!"day".equals(g) && !"month".equals(g) && !"year".equals(g)) {
        response.sendRedirect(base + "/analytics.jsp?error=invalidFilter");
        return;
    }

    // Read selected date/month/year with defaults
    String selectedDate = request.getParameter("date");
    String selectedMonth = request.getParameter("month"); // yyyy-MM
    String selectedYear  = request.getParameter("year");  // yyyy

    java.time.LocalDate today = java.time.LocalDate.now();
    if ("day".equals(g)) {
        if (selectedDate == null || selectedDate.isBlank()) selectedDate = today.toString();
        try {
            java.time.LocalDate.parse(selectedDate);
        } catch (Exception invalidDate) {
            response.sendRedirect(base + "/analytics.jsp?error=invalidFilter");
            return;
        }
    } else if ("month".equals(g)) {
        if (selectedMonth == null || selectedMonth.isBlank()) selectedMonth = today.getYear()+"-"+String.format("%02d", today.getMonthValue());
        if (!selectedMonth.matches("^\\d{4}-\\d{2}$")) {
            response.sendRedirect(base + "/analytics.jsp?error=invalidFilter");
            return;
        }
    } else if ("year".equals(g)) {
        if (selectedYear == null || selectedYear.isBlank()) selectedYear = String.valueOf(today.getYear());
        if (!selectedYear.matches("^\\d{4}$")) {
            response.sendRedirect(base + "/analytics.jsp?error=invalidFilter");
            return;
        }
    }
    // Read optional category
    String selectedCategory = request.getParameter("cat");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Analytics</title>
    <!-- Use CDN Chart.js for reliability -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js" integrity="sha384-D4lVwU5n5a9Ww0fW8H7kN8M6hBf3t1cVx4kq8qzq6iG6O6J8Q0m0zX4x0m8x3u2v" crossorigin="anonymous"></script>
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        .analytics-toolbar {
            margin: 16px 0 18px 0;
            display: flex;
            gap: 14px;
            row-gap: 14px;
            align-items: center;
            flex-wrap: wrap;
        }
        .analytics-toolbar .form-group {
            display: flex;
            align-items: center;
            gap: 8px;
            margin: 0;
        }
        .calendar-label {
            font-size: 14px;
            font-weight: 600;
            color: #334155;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            white-space: nowrap;
        }
        #date, #month, #year {
            min-width: 170px;
            height: 42px;
            font-size: 15px;
        }
    </style>
</head>
<body>
<div class="container-3d">
    <h2>Complaint Analytics</h2>
    <% if ("db".equals(request.getParameter("error"))) { %>
        <div class="alert alert-error">Database is not configured.</div>
    <% } %>
    <% if ("invalidFilter".equals(request.getParameter("error"))) { %>
        <div class="alert alert-error">Invalid filter value provided. Please choose valid date/month/year.</div>
    <% } %>
    <% if ("invalidDate".equals(request.getParameter("error"))) { %>
        <div class="alert alert-error">Invalid date supplied for reminder operation.</div>
    <% } %>
    <% if ("reminderQueued".equals(request.getParameter("info"))) { %>
        <div class="alert alert-info">Pending reminder request accepted for selected date.</div>
    <% } %>
    <form method="get" class="analytics-toolbar">
        <input type="hidden" name="g" id="granularityValue" value="<%= g %>"/>
        <div class="form-group">
            <label for="granularity">View:&nbsp;</label>
            <select id="granularity" class="form-control" onchange="onGranularityChange(this.value)">
                <option value="day" <%= "day".equals(g)?"selected":"" %>>Day</option>
                <option value="month" <%= "month".equals(g)?"selected":"" %>>Month</option>
                <option value="year" <%= "year".equals(g)?"selected":"" %>>Year</option>
            </select>
        </div>
        <div class="form-group">
            <label for="date">Select:&nbsp;</label>
            <span class="calendar-label">&#128197; Calendar</span>
            <input type="date" id="date" name="date" value="<%= selectedDate %>" class="form-control" <%= "day".equals(g)?"":"style='display:none'" %>>
            <input type="month" id="month" name="month" value="<%= selectedMonth != null ? selectedMonth : "" %>" class="form-control" <%= "month".equals(g)?"":"style='display:none'" %>>
            <input type="number" id="year" name="year" min="2000" max="2100" value="<%= selectedYear != null ? selectedYear : "" %>" class="form-control" <%= "year".equals(g)?"":"style='display:none'" %>>
        </div>
        <div class="form-group">
            <label for="cat">Category:&nbsp;</label>
            <select id="cat" name="cat" class="form-control">
                <option value="" <%= (selectedCategory==null||selectedCategory.isBlank())?"selected":"" %>>All</option>
                <option value="WaterTap" <%= "WaterTap".equals(selectedCategory)?"selected":"" %>>WaterTap</option>
                <option value="Electricity" <%= "Electricity".equals(selectedCategory)?"selected":"" %>>Electricity</option>
                <option value="Road" <%= "Road".equals(selectedCategory)?"selected":"" %>>Road</option>
                <option value="Sanitation" <%= "Sanitation".equals(selectedCategory)?"selected":"" %>>Sanitation</option>
                <option value="Other" <%= "Other".equals(selectedCategory)?"selected":"" %>>Other</option>
            </select>
        </div>
        <button type="submit" class="btn btn-primary btn-3d">View</button>
        <a class="btn btn-warning btn-3d" href="<%= base %>/actions/SendPendingReminders.jsp?date=<%= ("day".equals(g)? selectedDate : ("month".equals(g)? selectedMonth+"-01" : selectedYear+"-01-01")) %>">Send 10AM Pending Reminders</a>
        <a class="btn btn-danger btn-3d" href="<%= base %>/actions/ArchiveSolved.jsp?g=<%= g %><%= "day".equals(g)?("&date="+selectedDate):( "month".equals(g)? ("&month="+selectedMonth) : ("&year="+selectedYear) ) %>">Archive Solved for this period</a>
    </form>
    <canvas id="statusChart" width="400" height="200"></canvas>
    <canvas id="categoryChart" width="400" height="200"></canvas>
    <%
        String dbUrl = ConfigLoader.getDbUrl();
        String dbUser = ConfigLoader.getDbUser();
        String dbPassword = ConfigLoader.getDbPassword();
        int pending=0, solving=0, solved=0;
        int water=0, electricity=0, road=0, sanitation=0, other=0;
        // For selected-category breakdown
        int catPending=0, catSolved=0;
        if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
            out.println("<div class='alert alert-error'>Database is not configured. Analytics data is unavailable.</div>");
        } else {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
            PreparedStatement pst1 = null, pst2 = null;
            PreparedStatement pstCat = null;
            ResultSet rs1 = null, rs2 = null, rsCat = null;
            try {
                String sql1;
                if ("day".equals(g)) {
                    sql1 = "SELECT status, COUNT(*) as cnt FROM complaints WHERE DATE(created_at)=? GROUP BY status";
                    pst1 = con.prepareStatement(sql1);
                    pst1.setString(1, selectedDate);
                } else if ("month".equals(g)) {
                    sql1 = "SELECT status, COUNT(*) as cnt FROM complaints WHERE YEAR(created_at)=? AND MONTH(created_at)=? GROUP BY status";
                    pst1 = con.prepareStatement(sql1);
                    String[] ym = selectedMonth.split("-");
                    pst1.setInt(1, Integer.parseInt(ym[0]));
                    pst1.setInt(2, Integer.parseInt(ym[1]));
                } else { // year
                    sql1 = "SELECT status, COUNT(*) as cnt FROM complaints WHERE YEAR(created_at)=? GROUP BY status";
                    pst1 = con.prepareStatement(sql1);
                    pst1.setInt(1, Integer.parseInt(selectedYear));
                }
                rs1 = pst1.executeQuery();
                while(rs1.next()){
                    String st = rs1.getString("status");
                    if ("Pending".equals(st)) pending = rs1.getInt("cnt");
                    else if ("Solving".equals(st)) solving = rs1.getInt("cnt");
                    else if ("Solved".equals(st)) solved = rs1.getInt("cnt");
                }
                String sql2;
                if ("day".equals(g)) {
                    sql2 = "SELECT category, COUNT(*) as cnt FROM complaints WHERE DATE(created_at)=? GROUP BY category";
                    pst2 = con.prepareStatement(sql2);
                    pst2.setString(1, selectedDate);
                } else if ("month".equals(g)) {
                    sql2 = "SELECT category, COUNT(*) as cnt FROM complaints WHERE YEAR(created_at)=? AND MONTH(created_at)=? GROUP BY category";
                    pst2 = con.prepareStatement(sql2);
                    String[] ym2 = selectedMonth.split("-");
                    pst2.setInt(1, Integer.parseInt(ym2[0]));
                    pst2.setInt(2, Integer.parseInt(ym2[1]));
                } else {
                    sql2 = "SELECT category, COUNT(*) as cnt FROM complaints WHERE YEAR(created_at)=? GROUP BY category";
                    pst2 = con.prepareStatement(sql2);
                    pst2.setInt(1, Integer.parseInt(selectedYear));
                }
                rs2 = pst2.executeQuery();
                while(rs2.next()){
                    switch(rs2.getString("category")){
                        case "WaterTap": water = rs2.getInt("cnt"); break;
                        case "Electricity": electricity = rs2.getInt("cnt"); break;
                        case "Road": road = rs2.getInt("cnt"); break;
                        case "Sanitation": sanitation = rs2.getInt("cnt"); break;
                        case "Other": other = rs2.getInt("cnt"); break;
                    }
                }
                if (selectedCategory != null && !selectedCategory.isBlank()) {
                    if ("day".equals(g)) {
                        pstCat = con.prepareStatement("SELECT status, COUNT(*) cnt FROM complaints WHERE DATE(created_at)=? AND category=? GROUP BY status");
                        pstCat.setString(1, selectedDate);
                        pstCat.setString(2, selectedCategory);
                    } else if ("month".equals(g)) {
                        pstCat = con.prepareStatement("SELECT status, COUNT(*) cnt FROM complaints WHERE YEAR(created_at)=? AND MONTH(created_at)=? AND category=? GROUP BY status");
                        String[] ymc = selectedMonth.split("-");
                        pstCat.setInt(1, Integer.parseInt(ymc[0]));
                        pstCat.setInt(2, Integer.parseInt(ymc[1]));
                        pstCat.setString(3, selectedCategory);
                    } else {
                        pstCat = con.prepareStatement("SELECT status, COUNT(*) cnt FROM complaints WHERE YEAR(created_at)=? AND category=? GROUP BY status");
                        pstCat.setInt(1, Integer.parseInt(selectedYear));
                        pstCat.setString(2, selectedCategory);
                    }
                    rsCat = pstCat.executeQuery();
                    while (rsCat.next()) {
                        String st = rsCat.getString("status");
                        if ("Pending".equals(st)) catPending = rsCat.getInt("cnt");
                        else if ("Solved".equals(st)) catSolved = rsCat.getInt("cnt");
                    }
                }
            } catch(Exception e){ e.printStackTrace(); }
            finally {
                try { if(rs1!=null) rs1.close(); } catch(Exception ignore) {}
                try { if(pst1!=null) pst1.close(); } catch(Exception ignore) {}
                try { if(rs2!=null) rs2.close(); } catch(Exception ignore) {}
                try { if(pst2!=null) pst2.close(); } catch(Exception ignore) {}
                try { if(rsCat!=null) rsCat.close(); } catch(Exception ignore) {}
                try { if(pstCat!=null) pstCat.close(); } catch(Exception ignore) {}
                if(con!=null) con.close();
            }
        }
    %>
    <!-- Server-side metrics exposed via data-* attributes to avoid inline JSP in JS -->
    <div id="metrics"
         data-pending="<%= pending %>"
         data-solving="<%= solving %>"
         data-solved="<%= solved %>"
         data-water="<%= water %>"
         data-electricity="<%= electricity %>"
         data-road="<%= road %>"
         data-sanitation="<%= sanitation %>"
         data-other="<%= other %>"
         style="display:none"></div>
    <div class="summary-cards" style="display:flex; gap:12px; margin:12px 0; flex-wrap:wrap;">
        <div class="card p-3"><b>Date:</b> <%= selectedDate %></div>
        <div class="card p-3"><b>Total:</b> <%= (pending + solving + solved) %></div>
        <a class="btn btn-outline-warning btn-3d" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Pending">Pending: <%= pending %></a>
        <a class="btn btn-outline-info btn-3d" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Solving">Solving: <%= solving %></a>
        <a class="btn btn-outline-success btn-3d" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Solved">Solved: <%= solved %></a>
        <% if (selectedCategory != null && !selectedCategory.isBlank()) { %>
            <div class="card p-3" style="border-left: 4px solid #3b82f6;">
                <b>Category:</b> <%= selectedCategory %><br>
                <span>Pending: <b><%= catPending %></b></span><br>
                <span>Solved: <b><%= catSolved %></b></span><br>
                <div style="margin-top:6px; display:flex; gap:6px;">
                    <a class="btn btn-sm btn-outline-warning" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Pending&category=<%= selectedCategory %>">View Pending</a>
                    <a class="btn btn-sm btn-outline-success" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Solved&category=<%= selectedCategory %>">View Solved</a>
                </div>
            </div>
        <% } %>
    </div>
    <script>
        function onGranularityChange(value) {
            const g = document.getElementById('granularityValue');
            const date = document.getElementById('date');
            const month = document.getElementById('month');
            const year = document.getElementById('year');
            if (g) g.value = value;
            if (date) date.style.display = value === 'day' ? '' : 'none';
            if (month) month.style.display = value === 'month' ? '' : 'none';
            if (year) year.style.display = value === 'year' ? '' : 'none';
        }

        document.addEventListener('DOMContentLoaded', function() {
            if (typeof Chart === 'undefined') {
                console.error('Chart.js not loaded');
                return;
            }
            const statusCtx = document.getElementById('statusChart');
            const categoryCtx = document.getElementById('categoryChart');
            const m = document.getElementById('metrics').dataset;
            const pending = parseInt(m.pending || '0', 10);
            const solving = parseInt(m.solving || '0', 10);
            const solved = parseInt(m.solved || '0', 10);
            const water = parseInt(m.water || '0', 10);
            const electricity = parseInt(m.electricity || '0', 10);
            const road = parseInt(m.road || '0', 10);
            const sanitation = parseInt(m.sanitation || '0', 10);
            const other = parseInt(m.other || '0', 10);

            new Chart(statusCtx, {
                type: 'doughnut',
                data: {
                    labels: ['Pending','Solving','Solved'],
                    datasets: [{
                        label: 'Complaint Status',
                        data: [pending, solving, solved],
                        backgroundColor: ['#ff6384','#f59e0b','#36a2eb']
                    }]
                }
            });

            new Chart(categoryCtx, {
                type: 'bar',
                data: {
                    labels: ['WaterTap','Electricity','Road','Sanitation','Other'],
                    datasets: [{
                        label: 'Complaints by Category',
                        data: [water, electricity, road, sanitation, other],
                        backgroundColor: '#ff9f40'
                    }]
                },
                options: { scales: { y: { beginAtZero: true } } }
            });
        });
    </script>
    <div class="form-group" style="margin-top: 30px;">
        <form action="<%= base %>/actions/GenerateReports.jsp" method="post">
            <button type="submit" class="btn btn-primary btn-3d">Generate Detailed Report</button>
        </form>
    </div>
    <div class="form-group" style="margin-top: 10px;">
        <a href="<%= base %>/index.jsp" class="btn btn-primary btn-3d">Back to Home</a>
        <a href="<%= base %>/<%= "officer".equals(__role) ? "officerDashboard.jsp" : "adminDashboard.jsp" %>" class="btn btn-info btn-3d">Back to Dashboard</a>
    </div>
</div>
<script src="assets/js/main.js"></script>
</body>
</html>
