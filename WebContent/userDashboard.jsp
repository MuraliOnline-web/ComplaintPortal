<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="/WEB-INF/tld/c.tld" prefix="c" %>
<%
    // Handle flash messages from previous actions
    String flashMessage = (String) session.getAttribute("flashMessage");
    String flashType = (String) session.getAttribute("flashType");
    if (flashMessage != null) session.removeAttribute("flashMessage");
    if (flashType != null) session.removeAttribute("flashType");
    
    String role = (String) session.getAttribute("role");
    if (role == null || !"user".equals(role)) {
        response.sendRedirect("userLogin.jsp?required=1");
        return;
    }

    Integer userId = (Integer) session.getAttribute("userId");
    String userName = session.getAttribute("userName") != null ? String.valueOf(session.getAttribute("userName")) : "User";
    String userEmail = session.getAttribute("userEmail") != null ? String.valueOf(session.getAttribute("userEmail")) : "";
    String userMobile = session.getAttribute("userMobile") != null ? String.valueOf(session.getAttribute("userMobile")) : "";

    List<Map<String, Object>> complaintRows = new ArrayList<>();
    int totalCount = 0;
    int pendingCount = 0;
    int solvedCount = 0;
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
        dashboardError = "Database is not configured. Contact admin.";
    } else {
        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

            PreparedStatement pst = con.prepareStatement(
                "SELECT complaint_id, complaint_code, category, description, address, status, created_at FROM complaints WHERE user_id=? ORDER BY created_at DESC"
            );
            pst.setInt(1, userId.intValue());
            ResultSet rs = pst.executeQuery();
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("complaint_id"));
                row.put("code", rs.getString("complaint_code"));
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
    request.setAttribute("solvedCount", solvedCount);
    request.setAttribute("dashboardError", dashboardError);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>User Dashboard</title>
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

        .dashboard-shell {
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
        .status-solving { background: #dbeafe; color: #1d4ed8; }
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
    
    <div class="dashboard-shell">
        <nav class="navbar navbar-expand-lg bg-white bg-opacity-75 backdrop-blur-sm sticky-top border-bottom border-light-subtle">
            <div class="container py-2">
                <a class="navbar-brand fw-bold d-flex align-items-center gap-2" href="index.jsp">
                    <img src="assets/images/logo.svg" alt="Complaint Portal" style="width:40px;height:40px;border-radius:12px;object-fit:cover;">
                    <span>Complaint Portal</span>
                </a>
                <div class="dropdown ms-auto">
                    <button class="btn btn-light border dropdown-toggle d-flex align-items-center gap-2" data-bs-toggle="dropdown" aria-expanded="false">
                        <span class="avatar-circle"><%= userName != null && !userName.isBlank() ? userName.trim().substring(0, 1).toUpperCase() : "U" %></span>
                        <span class="d-none d-md-inline"><%= userName %></span>
                    </button>
                    <ul class="dropdown-menu dropdown-menu-end shadow-lg">
                        <li><h6 class="dropdown-header">Signed in as</h6></li>
                        <li><span class="dropdown-item-text small text-muted"><%= userEmail %></span></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="actions/LogoutAction.jsp" data-confirm-logout data-confirm-message="You are about to log out of your account." data-logout-url="actions/LogoutAction.jsp">Logout</a></li>
                    </ul>
                </div>
            </div>
        </nav>

        <main class="container py-4 py-lg-5">
            <nav aria-label="breadcrumb" class="mb-4">
                <ol class="breadcrumb small">
                    <li class="breadcrumb-item"><a href="index.jsp">Home</a></li>
                    <li class="breadcrumb-item active" aria-current="page">User Dashboard</li>
                </ol>
            </nav>
            <div class="dashboard-card p-4 p-lg-5 mb-4">
                <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
                    <div>
                        <div class="text-uppercase small fw-semibold text-primary">User Dashboard</div>
                        <h1 class="h2 fw-bold mb-2">Welcome, <%= userName %></h1>
                        <p class="text-secondary mb-0">Track your complaint history and submit new issues with the portal.</p>
                    </div>
                    <div class="d-flex flex-wrap gap-2">
                        <a href="registerComplaint.jsp" class="btn btn-primary">New Complaint</a>
                        <a href="trackComplaint.jsp" class="btn btn-outline-primary">Track Complaint</a>
                    </div>
                </div>
            </div>

            <div class="row g-4 mb-4">
                <div class="col-md-4">
                    <div class="metric-card p-4">
                        <div class="text-secondary">Total Complaints</div>
                        <div class="value"><c:out value="${totalCount}"/></div>
                        <div class="text-secondary small">All requests submitted by you</div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="metric-card p-4">
                        <div class="text-secondary">Pending</div>
                        <div class="value"><c:out value="${pendingCount}"/></div>
                        <div class="text-secondary small">Awaiting action</div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="metric-card p-4">
                        <div class="text-secondary">Resolved</div>
                        <div class="value"><c:out value="${solvedCount}"/></div>
                        <div class="text-secondary small">Closed cases</div>
                    </div>
                </div>
            </div>

            <c:if test="${not empty dashboardError}">
                <div class="alert alert-danger"><c:out value="${dashboardError}"/></div>
            </c:if>

            <div class="dashboard-card p-3 p-lg-4">
                <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                    <div>
                        <h2 class="h4 fw-bold mb-1">Recent Complaints</h2>
                        <p class="text-secondary mb-0">Your latest complaint submissions and current status.</p>
                    </div>
                </div>
                <div class="table-responsive">
                    <table class="table align-middle mb-0">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Title</th>
                                <th>Status</th>
                                <th>Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:choose>
                                <c:when test="${empty complaints}">
                                    <tr>
                                        <td colspan="4" class="text-center py-5">
                                            <div class="text-muted mb-2" style="font-size:2.5rem;">📋</div>
                                            <div class="fw-semibold text-secondary">No complaints yet</div>
                                            <div class="small text-muted mb-3">Start by filing your first complaint</div>
                                            <a href="registerComplaint.jsp" class="btn btn-primary btn-sm">Submit Complaint</a>
                                        </td>
                                    </tr>
                                </c:when>
                                <c:otherwise>
                                    <c:forEach var="c" items="${complaints}">
                                        <tr class="table-row-hover">
                                            <td class="fw-semibold">${c.id}</td>
                                            <td>
                                                <div class="fw-semibold">${c.title}</div>
                                                <div class="text-secondary small">${c.category} - ${c.address}</div>
                                            </td>
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
                                            <td class="text-secondary"><c:out value="${c.createdAt}"/></td>
                                        </tr>
                                    </c:forEach>
                                </c:otherwise>
                            </c:choose>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>
