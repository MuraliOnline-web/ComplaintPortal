<%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String role = (String) session.getAttribute("role");
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    if (role == null || (!"admin".equals(role) && !"officer".equals(role))) {
        response.sendRedirect(base + "/login.jsp");
        return;
    }

    String g = request.getParameter("g");
    if (g == null || g.isBlank()) g = "day";
    if (!"day".equals(g) && !"month".equals(g) && !"year".equals(g)) {
        response.sendRedirect(base + "/analytics.jsp?error=invalidFilter");
        return;
    }

    String selectedDate = request.getParameter("date");
    String selectedMonth = request.getParameter("month");
    String selectedYear = request.getParameter("year");
    java.time.LocalDate today = java.time.LocalDate.now();
    if ("day".equals(g)) {
        if (selectedDate == null || selectedDate.isBlank()) selectedDate = today.toString();
        try { java.time.LocalDate.parse(selectedDate); } catch (Exception ex) { response.sendRedirect(base + "/analytics.jsp?error=invalidFilter"); return; }
    } else if ("month".equals(g)) {
        if (selectedMonth == null || selectedMonth.isBlank()) selectedMonth = today.getYear() + "-" + String.format("%02d", today.getMonthValue());
        if (!selectedMonth.matches("^\\d{4}-\\d{2}$")) { response.sendRedirect(base + "/analytics.jsp?error=invalidFilter"); return; }
    } else {
        if (selectedYear == null || selectedYear.isBlank()) selectedYear = String.valueOf(today.getYear());
        if (!selectedYear.matches("^\\d{4}$")) { response.sendRedirect(base + "/analytics.jsp?error=invalidFilter"); return; }
    }
    String selectedCategory = request.getParameter("cat");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Analytics</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js" crossorigin="anonymous"></script>
    <link rel="stylesheet" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.dashboard-page { min-height: 100vh; background: radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 30%), radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.1), transparent 32%), linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%); }
        .dashboard-card { border: 1px solid rgba(148, 163, 184, 0.2); border-radius: 24px; background: rgba(255, 255, 255, 0.88); box-shadow: 0 20px 60px rgba(15, 23, 42, 0.07); }
        .metric-card { border: 1px solid rgba(148, 163, 184, 0.18); border-radius: 20px; background: rgba(255, 255, 255, 0.82); box-shadow: 0 14px 34px rgba(15, 23, 42, 0.05); height: 100%; }
        .metric-card .value { font-size: 2rem; font-weight: 800; letter-spacing: -0.04em; }
        .chart-box { border: 1px solid rgba(148, 163, 184, 0.16); border-radius: 22px; background: #fff; padding: 1rem; min-height: 360px; display: flex; flex-direction: column; }
        .chart-box canvas { flex: 1; min-height: 280px; }
        .chart-placeholder { min-height: 280px; display: flex; align-items: center; justify-content: center; text-align: center; color: #64748b; }
        @media (max-width: 576px) { .chart-box { min-height: 300px; } .chart-box canvas { min-height: 240px; } }
    </style>
</head>
<body class="dashboard-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <nav class="navbar navbar-expand-lg bg-white bg-opacity-75 backdrop-blur-sm sticky-top border-bottom border-light-subtle">
        <div class="container py-2">
            <a class="navbar-brand fw-bold d-flex align-items-center gap-2" href="index.jsp">
                <img src="assets/images/logo.svg" alt="Complaint Portal logo" style="width:40px;height:40px;border-radius:12px;object-fit:cover;">
                <span>Complaint Portal</span>
            </a>
            <div class="ms-auto d-flex gap-2 flex-wrap">
                <a href="<%= "officer".equals(role) ? "officerDashboard.jsp" : "adminDashboard.jsp" %>" class="btn btn-outline-primary"><%= "officer".equals(role) ? "Officer Dashboard" : "Admin Dashboard" %></a>
                <a href="actions/LogoutAction.jsp" class="btn btn-outline-danger" data-confirm-logout data-confirm-message="You are about to leave analytics and log out." data-logout-url="actions/LogoutAction.jsp">Logout</a>
            </div>
        </div>
    </nav>

    <main class="container py-4 py-lg-5">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb small">
                <li class="breadcrumb-item"><a href="<%= base %>/<%= "officer".equals(role) ? "officerDashboard.jsp" : "adminDashboard.jsp" %>">Dashboard</a></li>
                <li class="breadcrumb-item active" aria-current="page">Analytics</li>
            </ol>
        </nav>

        <div class="dashboard-card p-4 p-lg-5 mb-4">
            <div class="text-uppercase small fw-semibold text-primary">Analytics</div>
            <h1 class="h2 fw-bold mb-2">Complaint Analytics</h1>
            <p class="text-secondary mb-0">Review trends, categories, and status breakdowns for the selected period.</p>
        </div>

        <% if ("db".equals(request.getParameter("error"))) { %><div class="alert alert-danger">Database is not configured.</div><% } %>
        <% if ("invalidFilter".equals(request.getParameter("error"))) { %><div class="alert alert-danger">Invalid filter value provided. Please choose a valid date, month, or year.</div><% } %>
        <% if ("invalidDate".equals(request.getParameter("error"))) { %><div class="alert alert-danger">Invalid date supplied for reminder operation.</div><% } %>
        <% if ("reminderQueued".equals(request.getParameter("info"))) { %><div class="alert alert-info">Pending reminder request accepted for the selected date.</div><% } %>

        <div class="dashboard-card p-3 p-lg-4 mb-4">
            <form method="get" class="row g-3 align-items-end">
                <input type="hidden" name="g" id="granularityValue" value="<%= g %>">
                <div class="col-md-3">
                    <label for="granularity" class="form-label fw-semibold">View</label>
                    <select id="granularity" class="form-select" onchange="onGranularityChange(this.value)">
                        <option value="day" <%= "day".equals(g)?"selected":"" %>>Day</option>
                        <option value="month" <%= "month".equals(g)?"selected":"" %>>Month</option>
                        <option value="year" <%= "year".equals(g)?"selected":"" %>>Year</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Date</label>
                    <input type="date" id="date" name="date" value="<%= selectedDate %>" class="form-control" <%= "day".equals(g)?"":"style='display:none'" %>>
                    <input type="month" id="month" name="month" value="<%= selectedMonth != null ? selectedMonth : "" %>" class="form-control" <%= "month".equals(g)?"":"style='display:none'" %>>
                    <input type="number" id="year" name="year" min="2000" max="2100" value="<%= selectedYear != null ? selectedYear : "" %>" class="form-control" <%= "year".equals(g)?"":"style='display:none'" %>>
                </div>
                <div class="col-md-3">
                    <label for="cat" class="form-label fw-semibold">Category</label>
                    <select id="cat" name="cat" class="form-select">
                        <option value="" <%= (selectedCategory==null||selectedCategory.isBlank())?"selected":"" %>>All</option>
                        <option value="WaterTap" <%= "WaterTap".equals(selectedCategory)?"selected":"" %>>WaterTap</option>
                        <option value="Electricity" <%= "Electricity".equals(selectedCategory)?"selected":"" %>>Electricity</option>
                        <option value="Road" <%= "Road".equals(selectedCategory)?"selected":"" %>>Road</option>
                        <option value="Sanitation" <%= "Sanitation".equals(selectedCategory)?"selected":"" %>>Sanitation</option>
                        <option value="Other" <%= "Other".equals(selectedCategory)?"selected":"" %>>Other</option>
                    </select>
                </div>
                <div class="col-12">
                    <div class="row g-2">
                        <div class="col-md-4 d-grid">
                            <button type="submit" class="btn btn-primary w-100" aria-label="View analytics for selected filters">View</button>
                        </div>
                        <div class="col-md-4 d-grid">
                            <a class="btn btn-warning w-100" href="<%= base %>/actions/SendPendingReminders.jsp?date=<%= ("day".equals(g)? selectedDate : ("month".equals(g)? selectedMonth+"-01" : selectedYear+"-01-01")) %>">Send reminders</a>
                        </div>
                        <div class="col-md-4 d-grid">
                            <a class="btn btn-danger w-100" href="<%= base %>/actions/ArchiveSolved.jsp?g=<%= g %><%= "day".equals(g)?("&date="+selectedDate):( "month".equals(g)? ("&month="+selectedMonth) : ("&year="+selectedYear) ) %>">Archive solved</a>
                        </div>
                    </div>
                </div>
            </form>
        </div>

        <%
            String dbUrl = ConfigLoader.getDbUrl();
            String dbUser = ConfigLoader.getDbUser();
            String dbPassword = ConfigLoader.getDbPassword();
            int pending = 0, solving = 0, solved = 0;
            int water = 0, electricity = 0, road = 0, sanitation = 0, other = 0;
            int catPending = 0, catSolved = 0;
            String dashboardError = null;

            if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
                dashboardError = "Database is not configured. Analytics data is unavailable.";
            } else {
                Connection con = null;
                PreparedStatement pst1 = null, pst2 = null, pstCat = null;
                ResultSet rs1 = null, rs2 = null, rsCat = null;
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

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
                    } else {
                        sql1 = "SELECT status, COUNT(*) as cnt FROM complaints WHERE YEAR(created_at)=? GROUP BY status";
                        pst1 = con.prepareStatement(sql1);
                        pst1.setInt(1, Integer.parseInt(selectedYear));
                    }

                    rs1 = pst1.executeQuery();
                    while (rs1.next()) {
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
                    while (rs2.next()) {
                        switch (rs2.getString("category")) {
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
                } catch (Exception e) {
                    dashboardError = "Unable to calculate analytics right now.";
                } finally {
                    try { if (rs1 != null) rs1.close(); } catch (Exception ignore) {}
                    try { if (pst1 != null) pst1.close(); } catch (Exception ignore) {}
                    try { if (rs2 != null) rs2.close(); } catch (Exception ignore) {}
                    try { if (pst2 != null) pst2.close(); } catch (Exception ignore) {}
                    try { if (rsCat != null) rsCat.close(); } catch (Exception ignore) {}
                    try { if (pstCat != null) pstCat.close(); } catch (Exception ignore) {}
                    if (con != null) try { con.close(); } catch (Exception ignore) {}
                }
            }

            boolean hasChartData = (pending + solving + solved + water + electricity + road + sanitation + other) > 0;
        %>

        <% if (dashboardError != null) { %>
            <div class="alert alert-danger"><%= dashboardError %></div>
        <% } %>

        <div id="metrics" data-pending="<%= pending %>" data-solving="<%= solving %>" data-solved="<%= solved %>" data-water="<%= water %>" data-electricity="<%= electricity %>" data-road="<%= road %>" data-sanitation="<%= sanitation %>" data-other="<%= other %>" data-has-data="<%= hasChartData ? "1" : "0" %>" style="display:none"></div>

        <div class="row g-4 mb-4">
            <div class="col-md-4"><div class="metric-card p-4"><div class="text-secondary">Pending</div><div class="value"><%= pending %></div></div></div>
            <div class="col-md-4"><div class="metric-card p-4"><div class="text-secondary">Solving</div><div class="value"><%= solving %></div></div></div>
            <div class="col-md-4"><div class="metric-card p-4"><div class="text-secondary">Solved</div><div class="value"><%= solved %></div></div></div>
        </div>

        <% if (hasChartData) { %>
            <div class="row g-4 mb-4">
                <div class="col-lg-6">
                    <div class="chart-box h-100">
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <div>
                                <h2 class="h5 fw-bold mb-1">Status Distribution</h2>
                                <div class="text-secondary small">Pending vs solving vs resolved</div>
                            </div>
                        </div>
                        <canvas id="statusChart" aria-label="Complaint status chart" role="img"></canvas>
                    </div>
                </div>
                <div class="col-lg-6">
                    <div class="chart-box h-100">
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <div>
                                <h2 class="h5 fw-bold mb-1">Complaints by Category</h2>
                                <div class="text-secondary small">Category volume for the selected period</div>
                            </div>
                        </div>
                        <canvas id="categoryChart" aria-label="Complaints by category chart" role="img"></canvas>
                    </div>
                </div>
            </div>
        <% } else { %>
            <div class="alert alert-light border text-secondary">No data available for the selected period.</div>
        <% } %>

        <div class="dashboard-card p-3 p-lg-4">
            <div class="row g-3 align-items-stretch">
                <div class="col-12 col-sm-6 col-lg-2">
                    <div class="card h-100 p-3 d-flex flex-column justify-content-center">
                        <div class="text-secondary small fw-semibold">Date</div>
                        <div class="fw-bold"><%= selectedDate %></div>
                    </div>
                </div>
                <div class="col-12 col-sm-6 col-lg-2">
                    <div class="card h-100 p-3 d-flex flex-column justify-content-center">
                        <div class="text-secondary small fw-semibold">Total</div>
                        <div class="fw-bold"><%= (pending + solving + solved) %></div>
                    </div>
                </div>
                <div class="col-12 col-sm-6 col-lg-2">
                    <a class="btn btn-outline-warning w-100 h-100 d-flex align-items-center justify-content-center" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Pending">Pending: <%= pending %></a>
                </div>
                <div class="col-12 col-sm-6 col-lg-2">
                    <a class="btn btn-outline-info w-100 h-100 d-flex align-items-center justify-content-center" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Solving">Solving: <%= solving %></a>
                </div>
                <div class="col-12 col-sm-6 col-lg-2">
                    <a class="btn btn-outline-success w-100 h-100 d-flex align-items-center justify-content-center" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Solved">Solved: <%= solved %></a>
                </div>
                <% if (selectedCategory != null && !selectedCategory.isBlank()) { %>
                    <div class="col-12">
                        <div class="card p-3" style="border-left: 4px solid #3b82f6;">
                            <b>Category:</b> <%= selectedCategory %><br>
                            <span>Pending: <b><%= catPending %></b></span><br>
                            <span>Solved: <b><%= catSolved %></b></span><br>
                            <div class="mt-2 d-flex gap-2 flex-wrap">
                                <a class="btn btn-sm btn-outline-warning" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Pending&category=<%= selectedCategory %>">View Pending</a>
                                <a class="btn btn-sm btn-outline-success" href="<%= base %>/actions/SearchComplaints.jsp?date=<%= selectedDate %>&status=Solved&category=<%= selectedCategory %>">View Solved</a>
                            </div>
                        </div>
                    </div>
                <% } %>
            </div>
        </div>

        <div class="d-flex flex-wrap gap-2 mt-4">
            <a href="<%= base %>/actions/GenerateReports.jsp" class="btn btn-primary">Generate Detailed Report</a>
            <a href="<%= base %>/<%= "officer".equals(role) ? "officerDashboard.jsp" : "adminDashboard.jsp" %>" class="btn btn-outline-primary">Back to Dashboard</a>
        </div>
    </main>

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
            if (typeof Chart === 'undefined') return;
            const metrics = document.getElementById('metrics');
            if (!metrics || metrics.dataset.hasData !== '1') return;

            const m = metrics.dataset;
            const pending = parseInt(m.pending || '0', 10);
            const solving = parseInt(m.solving || '0', 10);
            const solved = parseInt(m.solved || '0', 10);
            const water = parseInt(m.water || '0', 10);
            const electricity = parseInt(m.electricity || '0', 10);
            const road = parseInt(m.road || '0', 10);
            const sanitation = parseInt(m.sanitation || '0', 10);
            const other = parseInt(m.other || '0', 10);

            new Chart(document.getElementById('statusChart'), {
                type: 'pie',
                data: {
                    labels: ['Pending', 'Solving', 'Solved'],
                    datasets: [{ label: 'Complaint Status', data: [pending, solving, solved], backgroundColor: ['#f59e0b', '#3b82f6', '#22c55e'] }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { position: 'bottom' } }
                }
            });

            new Chart(document.getElementById('categoryChart'), {
                type: 'bar',
                data: {
                    labels: ['WaterTap', 'Electricity', 'Road', 'Sanitation', 'Other'],
                    datasets: [{ label: 'Complaints by Category', data: [water, electricity, road, sanitation, other], backgroundColor: '#ff9f40' }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: { y: { beginAtZero: true } },
                    plugins: { legend: { display: false } }
                }
            });
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>