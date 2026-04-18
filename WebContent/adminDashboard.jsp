<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="/WEB-INF/tld/c.tld" prefix="c" %>
<%@ taglib uri="/WEB-INF/tld/fn.tld" prefix="fn" %>
<%
    // Handle flash messages from previous actions
    String flashMessage = (String) session.getAttribute("flashMessage");
    String flashType = (String) session.getAttribute("flashType");
    if (flashMessage != null) session.removeAttribute("flashMessage");
    if (flashType != null) session.removeAttribute("flashType");
    
    String role = (String) session.getAttribute("role");
    if (role == null || !"admin".equals(role)) {
        response.sendRedirect("login.jsp?denied=1");
        return;
    }

    String adminName = session.getAttribute("userName") != null ? String.valueOf(session.getAttribute("userName")) : "Admin";
    List<Map<String, Object>> complaintRows = new ArrayList<>();
    int totalCount = 0;
    int pendingCount = 0;
    int solvedCount = 0;
    int solvingCount = 0;
    String dashboardError = null;

    String dbUrl = System.getenv("DB_URL");
    String dbUser = System.getenv("DB_USER");
    String dbPassword = System.getenv("DB_PASSWORD");

    if (dbUrl == null || dbUrl.isBlank()) dbUrl = System.getProperty("db.url");
    if (dbUser == null || dbUser.isBlank()) dbUser = System.getProperty("db.user");
    if (dbPassword == null || dbPassword.isBlank()) dbPassword = System.getProperty("db.password");

    if (dbUrl == null || dbUrl.isBlank()) dbUrl = application.getInitParameter("db.url");
    if (dbUser == null || dbUser.isBlank()) dbUser = application.getInitParameter("db.user");
    if (dbPassword == null || dbPassword.isBlank()) dbPassword = application.getInitParameter("db.password");

    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        Properties props = new Properties();
        InputStream cfg = null;
        try {
            cfg = application.getResourceAsStream("/WEB-INF/config.properties");
            if (cfg == null) cfg = application.getResourceAsStream("/config.properties");
            if (cfg != null) {
                props.load(cfg);
                if (dbUrl == null || dbUrl.isBlank()) dbUrl = props.getProperty("db.url");
                if (dbUser == null || dbUser.isBlank()) dbUser = props.getProperty("db.user");
                if (dbPassword == null || dbPassword.isBlank()) dbPassword = props.getProperty("db.password");
            }
        } catch (Exception ignore) {
            // Keep fallbacks empty and let validation show config message.
        } finally {
            if (cfg != null) {
                try { cfg.close(); } catch (Exception ignore) {}
            }
        }
    }

    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        dashboardError = "Database is not configured.";
    } else {
        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

            PreparedStatement pst = con.prepareStatement(
                "SELECT c.complaint_id, c.complaint_code, u.name AS user_name, c.category, c.description, c.address, c.status, c.created_at " +
                "FROM complaints c JOIN users u ON c.user_id=u.user_id ORDER BY c.created_at DESC"
            );
            ResultSet rs = pst.executeQuery();
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("complaint_id"));
                row.put("code", rs.getString("complaint_code"));
                row.put("userName", rs.getString("user_name"));
                row.put("category", rs.getString("category"));
                row.put("title", rs.getString("description"));
                row.put("description", rs.getString("description"));
                row.put("address", rs.getString("address"));
                row.put("status", rs.getString("status"));
                String statusText = rs.getString("status");
                row.put("statusClass", statusText == null ? "pending" : statusText.toLowerCase().replace(" ", "-"));
                row.put("createdAt", rs.getTimestamp("created_at"));
                complaintRows.add(row);
            }
            rs.close();
            pst.close();

            totalCount = complaintRows.size();
            for (Map<String, Object> row : complaintRows) {
                String statusText = String.valueOf(row.get("status"));
                if (statusText != null && statusText.equalsIgnoreCase("Pending")) pendingCount++;
                if (statusText != null && (statusText.equalsIgnoreCase("Solved") || statusText.equalsIgnoreCase("Resolved"))) solvedCount++;
                if (statusText != null && (statusText.equalsIgnoreCase("Solving") || statusText.equalsIgnoreCase("In Progress"))) solvingCount++;
            }
        } catch (Exception e) {
            dashboardError = "Unable to fetch complaints right now.";
        } finally {
            if (con != null) {
                try { con.close(); } catch (Exception ignore) {}
            }
        }
    }

    request.setAttribute("complaints", complaintRows);
    request.setAttribute("totalCount", totalCount);
    request.setAttribute("pendingCount", pendingCount);
    request.setAttribute("solvingCount", solvingCount);
    request.setAttribute("solvedCount", solvedCount);
    request.setAttribute("dashboardError", dashboardError);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin Dashboard</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.dashboard-page {
            background:
                radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 30%),
                radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.1), transparent 32%),
                linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
            min-height: 100vh;
        }

        .dashboard-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 24px;
            background: rgba(255, 255, 255, 0.88);
            box-shadow: 0 20px 60px rgba(15, 23, 42, 0.07);
        }

        .metric-card {
            border: 1px solid rgba(148, 163, 184, 0.18);
            border-radius: 20px;
            background: rgba(255, 255, 255, 0.82);
            box-shadow: 0 14px 34px rgba(15, 23, 42, 0.05);
            height: 100%;
        }

        .metric-card .value {
            font-size: 2rem;
            font-weight: 800;
            letter-spacing: -0.04em;
        }

        .table thead th {
            background: #eff6ff;
            color: #0f172a;
            border-bottom: 0;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.35rem 0.75rem;
            border-radius: 999px;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .status-pending { background: #fef3c7; color: #92400e; }
        .status-solving,
        .status-in-progress { background: #dbeafe; color: #1d4ed8; }
        .status-solved,
        .status-resolved { background: #d1fae5; color: #047857; }

        .avatar-circle {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #4f46e5, #0ea5e9);
            color: #fff;
            font-weight: 800;
        }
    </style>
</head>
<body class="dashboard-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <!-- Toast container for notifications -->
    <div id="toastContainer"></div>
    
    <!-- Hidden message divs for toast system -->
    <% if (flashMessage != null && !flashMessage.isBlank()) { %>
        <div id="<%= "success".equals(flashType) ? "successMessage" : "errorMessage" %>" style="display:none;"><%= flashMessage %></div>
    <% } %>
    
    <nav class="navbar navbar-expand-lg bg-white bg-opacity-75 backdrop-blur-sm sticky-top border-bottom border-light-subtle">
        <div class="container py-2">
            <a class="navbar-brand fw-bold d-flex align-items-center gap-2" href="index.jsp">
                <img src="assets/images/logo.svg" alt="Complaint Portal" style="width:40px;height:40px;border-radius:12px;object-fit:cover;">
                <span>Complaint Portal</span>
            </a>
            <div class="dropdown ms-auto">
                    <button class="btn btn-light border dropdown-toggle d-flex align-items-center gap-2" data-bs-toggle="dropdown" aria-expanded="false">
                    <span class="avatar-circle"><%= adminName != null && !adminName.isBlank() ? adminName.trim().substring(0, 1).toUpperCase() : "A" %></span>
                    <span class="d-none d-md-inline"><%= adminName %></span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow-lg">
                    <li><h6 class="dropdown-header">Signed in as Admin</h6></li>
                    <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="actions/LogoutAction.jsp" data-confirm-logout data-confirm-message="You are about to log out of the admin dashboard." data-logout-url="actions/LogoutAction.jsp">Logout</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <main class="container py-4 py-lg-5">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb small">
                <li class="breadcrumb-item active" aria-current="page">Admin Dashboard</li>
            </ol>
        </nav>
        <div class="dashboard-card p-4 p-lg-5 mb-4">
            <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
                <div>
                    <div class="text-uppercase small fw-semibold text-primary">Admin Dashboard</div>
                    <h1 class="h2 fw-bold mb-2">Welcome, <%= adminName %></h1>
                    <p class="text-secondary mb-0">Review complaints, update status, and manage resolution work across the city.</p>
                </div>
                <div class="d-flex flex-wrap gap-2">
                    <a href="analytics.jsp" class="btn btn-outline-primary">Analytics</a>
                    <a href="actions/SearchComplaints.jsp" class="btn btn-primary">Search Complaints</a>
                </div>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-md-3"><div class="metric-card p-4"><div class="text-secondary">Total</div><div class="value"><c:out value="${totalCount}"/></div></div></div>
            <div class="col-md-3"><div class="metric-card p-4"><div class="text-secondary">Pending</div><div class="value"><c:out value="${pendingCount}"/></div></div></div>
            <div class="col-md-3"><div class="metric-card p-4"><div class="text-secondary">In Progress</div><div class="value"><c:out value="${solvingCount}"/></div></div></div>
            <div class="col-md-3"><div class="metric-card p-4"><div class="text-secondary">Resolved</div><div class="value"><c:out value="${solvedCount}"/></div></div></div>
        </div>

        <c:if test="${not empty dashboardError}">
            <div class="alert alert-danger"><c:out value="${dashboardError}"/></div>
        </c:if>
        <c:if test="${not empty param.success}">
            <div class="alert alert-success"><c:out value="${param.success}"/></div>
        </c:if>
        <c:if test="${not empty param.error}">
            <div class="alert alert-danger">Unable to complete the update.</div>
        </c:if>

        <div class="dashboard-card p-3 p-lg-4">
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                <div>
                    <h2 class="h4 fw-bold mb-1">All Complaints</h2>
                    <p class="text-secondary mb-0">Update complaint status directly from the dashboard.</p>
                </div>
                <div class="d-flex flex-wrap gap-2 align-items-center">
                    <div class="table-search-group">
                        <input type="search" id="adminComplaintSearch" class="form-control" placeholder="Search ID, title, status">
                    </div>
                    <div class="table-sort-group">
                        <select id="adminComplaintSort" class="form-select">
                            <option value="">Sort complaints</option>
                            <option value="date-desc">Date: newest first</option>
                            <option value="date-asc">Date: oldest first</option>
                            <option value="status-asc">Status: A to Z</option>
                            <option value="status-desc">Status: Z to A</option>
                        </select>
                    </div>
                </div>
            </div>
            <div class="table-responsive">
                <table class="table align-middle mb-0" data-table-filter data-search-input="#adminComplaintSearch" data-sort-input="#adminComplaintSort">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Complaint</th>
                            <th>User</th>
                            <th>Status</th>
                            <th>Date</th>
                            <th>Location</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${empty complaints}">
                                <tr data-empty-state>
                                    <td colspan="7" class="py-5">
                                        <div class="text-center text-muted">
                                            <div class="mb-2" style="font-size:2.5rem;">✓</div>
                                            <div class="fw-semibold text-secondary">No complaints to manage</div>
                                            <div class="small text-muted">All complaints have been resolved!</div>
                                        </div>
                                    </td>
                                </tr>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="c" items="${complaints}">
                                    <tr class="table-row-hover" data-search-text="${fn:escapeXml(c.id)} ${fn:escapeXml(c.title)} ${fn:escapeXml(c.status)} ${fn:escapeXml(c.userName)} ${fn:escapeXml(c.address)}" data-sort-date="${c.createdAt.time}" data-sort-status="${fn:escapeXml(c.status)}">
                                        <td class="fw-semibold"><c:out value="${c.id}"/></td>
                                        <td>
                                            <div class="fw-semibold"><c:out value="${c.title}"/></div>
                                            <div class="text-secondary small"><c:out value="${c.code}"/> - <c:out value="${c.category}"/></div>
                                            <div class="text-secondary small"><c:out value="${c.address}"/></div>
                                        </td>
                                        <td><c:out value="${c.userName}"/></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${c.status == 'Pending'}">
                                                    <span class="badge bg-warning text-dark">📌 Pending</span>
                                                </c:when>
                                                <c:when test="${c.status == 'Solving'}">
                                                    <span class="badge bg-info">⚙️ Solving</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge bg-success">✓ Resolved</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="text-secondary small"><c:out value="${c.createdAt}"/></td>
                                        <td>
                                            <button type="button" class="btn btn-outline-primary btn-sm" aria-label="View complaint location" data-location-open data-location-title="${fn:escapeXml(c.title)}" data-location-address="${fn:escapeXml(c.address)}" data-location-status="${fn:escapeXml(c.status)}">View Location</button>
                                        </td>
                                        <td style="min-width: 280px;">
                                            <form action="actions/UpdateStatus.jsp" method="post" enctype="multipart/form-data" class="d-grid gap-2" data-confirm-form data-confirm-title="Are you sure?" data-confirm-message="Update this complaint status now?" data-confirm-button="Yes, update status">
                                                <input type="hidden" name="complaintId" value="${c.id}">
                                                <select name="status" class="form-select form-select-sm" aria-label="Select complaint status" required>
                                                    <option value="Pending">Pending</option>
                                                    <option value="Solving">Solving</option>
                                                    <option value="Solved">Solved</option>
                                                </select>
                                                <input type="file" name="solvedPhoto" class="form-control form-control-sm" aria-label="Upload solved complaint photo">
                                                <button type="submit" class="btn btn-success btn-sm" aria-label="Update complaint status">Update</button>
                                            </form>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>
    </main>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>
