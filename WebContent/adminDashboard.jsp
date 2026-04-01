<!-- Admin Dashboard JSP (WebContent) -->
<%@ page import="java.sql.*" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.io.File" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.net.URLClassLoader" %>
<%@ page import="java.util.Properties" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws java.io.IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }

    private static String getConfig(jakarta.servlet.ServletContext app, String key, String defaultValue) {
        String envKey = key.toUpperCase().replace('.', '_');
        String envVal = System.getenv(envKey);
        if (envVal != null && !envVal.isBlank()) {
            return envVal;
        }

        Properties props = new Properties();
        try (InputStream in = app.getResourceAsStream("/WEB-INF/classes/config.properties") != null
                ? app.getResourceAsStream("/WEB-INF/classes/config.properties")
                : app.getResourceAsStream("/WebContent/WEB-INF/classes/config.properties")) {
            if (in != null) {
                props.load(in);
                String val = props.getProperty(key);
                if (val != null && !val.isBlank()) {
                    return val;
                }
            }
        } catch (Exception ignore) {
            // fall through to default
        }
        return defaultValue;
    }

    private static Connection openConnection(jakarta.servlet.ServletContext app, String dbUrl, String dbUser, String dbPassword) throws Exception {
        try {
            return DriverManager.getConnection(dbUrl, dbUser, dbPassword);
        } catch (SQLException first) {
            String[] jarCandidates = new String[] {
                "/WEB-INF/lib/mysql-connector-java-8.0.26.jar",
                "/WEB-INF/lib/mysql-connector-j-8.3.0.jar",
                "/WebContent/WEB-INF/lib/mysql-connector-java-8.0.26.jar",
                "/WebContent/WEB-INF/lib/mysql-connector-j-8.3.0.jar"
            };

            URL jarUrl = null;
            for (String rel : jarCandidates) {
                String real = app.getRealPath(rel);
                if (real != null) {
                    File f = new File(real);
                    if (f.exists() && f.isFile()) {
                        jarUrl = f.toURI().toURL();
                        break;
                    }
                }
            }

            if (jarUrl == null) {
                throw first;
            }

            URLClassLoader cl = new URLClassLoader(new URL[] { jarUrl }, Thread.currentThread().getContextClassLoader());
            Class<?> drvClass;
            try {
                drvClass = Class.forName("com.mysql.cj.jdbc.Driver", true, cl);
            } catch (ClassNotFoundException ex) {
                drvClass = Class.forName("com.mysql.jdbc.Driver", true, cl);
            }

            java.sql.Driver drv = (java.sql.Driver) drvClass.getDeclaredConstructor().newInstance();
            Properties props = new Properties();
            props.setProperty("user", dbUser);
            props.setProperty("password", dbPassword);

            Connection con = drv.connect(dbUrl, props);
            if (con == null) {
                throw first;
            }
            return con;
        }
    }
%>
<%
    // Prevent caching so back button won't show a protected page after logout
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    String role = (String) session.getAttribute("role");
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    if(role == null || (!role.equals("admin") && !role.equals("officer"))) {
        safeRedirect(response, base + "/login.jsp");
        return;
    }

    String updateMessage = null;
    if ("POST".equalsIgnoreCase(request.getMethod()) && request.getParameter("complaintId") != null) {
        if (!"admin".equals(role)) {
            updateMessage = "Only admin can update complaint status.";
        } else {
            try {
                int complaintId = Integer.parseInt(request.getParameter("complaintId").trim());
                String status = request.getParameter("status");
                if (status == null || status.isBlank()) {
                    throw new IllegalArgumentException("Status is required");
                }

                Part solvedPhotoPart = request.getPart("solvedPhoto");
                String solvedPhotoPath = null;
                if (solvedPhotoPart != null && solvedPhotoPart.getSize() > 0) {
                    String fileName = System.currentTimeMillis() + "_" + solvedPhotoPart.getSubmittedFileName();
                    String uploadDir = application.getRealPath("/") + "assets/images/uploads/";
                    File dir = new File(uploadDir);
                    if (!dir.exists()) {
                        dir.mkdirs();
                    }
                    solvedPhotoPart.write(uploadDir + fileName);
                    solvedPhotoPath = "assets/images/uploads/" + fileName;
                }

                String dbUrl = getConfig(application, "db.url", "");
                String dbUser = getConfig(application, "db.user", "");
                String dbPassword = getConfig(application, "db.password", "");
                if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
                    updateMessage = "Database is not configured. Contact admin.";
                } else {
                    Connection ucon = openConnection(application, dbUrl, dbUser, dbPassword);
                    try {
                        PreparedStatement upst;
                        if (solvedPhotoPath != null) {
                            upst = ucon.prepareStatement("UPDATE complaints SET status=?, solved_photo_path=? WHERE complaint_id=?");
                            upst.setString(1, status);
                            upst.setString(2, solvedPhotoPath);
                            upst.setInt(3, complaintId);
                        } else {
                            upst = ucon.prepareStatement("UPDATE complaints SET status=? WHERE complaint_id=?");
                            upst.setString(1, status);
                            upst.setInt(2, complaintId);
                        }
                        int changed = upst.executeUpdate();
                        updateMessage = changed > 0 ? "Complaint updated successfully." : "No complaint found for update.";
                    } finally {
                        if (ucon != null) {
                            ucon.close();
                        }
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
                updateMessage = "Update failed: " + ex.getMessage();
            }
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
    <link rel="stylesheet" type="text/css" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" integrity="sha384-gH6tQd6rYt6v7s5FQ4u+Nw6mM2J+Z1oQXbQ9yKqNqCkzJ10c1qf6jv9vZ5GxXKbi" crossorigin="anonymous">
</head>
<body>
    <div class="container-3d">
        <h2>Welcome, <%= (session.getAttribute("userName") != null ? session.getAttribute("userName") : session.getAttribute("role")) %>!</h2>
        <% if (updateMessage != null) { %>
            <div class="alert alert-info"><%= updateMessage %></div>
        <% } %>
        <% if ("1".equals(request.getParameter("searchError"))) { %>
            <div class="required-fields-msg" id="dashboardSearchError">please fill all required fields.</div>
        <% } %>
        <% if ("notfound".equals(request.getParameter("searchError"))) { %>
            <div class="required-fields-msg" id="dashboardSearchError">No complaint found for the provided details.</div>
        <% } %>
        <% if ("db".equals(request.getParameter("searchError"))) { %>
            <div class="required-fields-msg" id="dashboardSearchError">Database is not configured.</div>
        <% } %>
        <% if ("error".equals(request.getParameter("searchError"))) { %>
            <div class="required-fields-msg" id="dashboardSearchError">Unable to fetch complaint details right now.</div>
        <% } %>
        <div class="card p-3 mb-3">
            <h5>Search Complaint</h5>
            <form id="adminSearchForm" class="row g-2" method="get" action="<%= base %>/actions/GetComplaintByCode.jsp">
                <div class="col-md-5">
                    <input type="text" id="adminSearchCode" name="code" class="form-control" placeholder="Enter Complaint Code (e.g., CMP-20250922-ABC123)">
                </div>
                <div class="col-md-3">
                    <input type="number" id="adminSearchId" name="id" class="form-control" placeholder="Or Complaint ID">
                </div>
                <div class="col-md-2">
                    <button class="btn btn-primary btn-3d w-100" type="submit">Search</button>
                </div>
            </form>
        </div>
        <h3>All Complaints</h3>
        <table class="table table-bordered">
            <tr>
                <th>ID</th><th>Code</th><th>User</th><th>Category</th><th>Description</th><th>Address</th><th>Status</th><th>Action</th>
            </tr>
            <%
                String dbUrl = getConfig(application, "db.url", "");
                String dbUser = getConfig(application, "db.user", "");
                String dbPassword = getConfig(application, "db.password", "");
                if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
                    out.println("<tr><td colspan='8'>Database is not configured.</td></tr>");
                } else {
                    Connection con = openConnection(application, dbUrl, dbUser, dbPassword);
                    try {
                        int complaintCount = 0;
                        PreparedStatement countPst = con.prepareStatement("SELECT COUNT(*) FROM complaints");
                        ResultSet countRs = countPst.executeQuery();
                        if (countRs.next()) {
                            complaintCount = countRs.getInt(1);
                        }
                        countRs.close();
                        countPst.close();

                        if (complaintCount == 0) {
                            out.println("<tr><td colspan='8'>DB is empty. No complaints found.</td></tr>");
                        } else {
                        PreparedStatement pst = con.prepareStatement(
                            "SELECT c.complaint_id, c.complaint_code, u.name, c.category, c.description, c.address, c.status " +
                            "FROM complaints c JOIN users u ON c.user_id=u.user_id ORDER BY c.created_at DESC"
                        );
                        ResultSet rs = pst.executeQuery();
                        while(rs.next()){
            %>
            <tr>
                <td><%=rs.getInt("complaint_id")%></td>
                <td><%=rs.getString("complaint_code")%></td>
                <td><%=rs.getString("name")%></td>
                <td><%=rs.getString("category")%></td>
                <td><%=rs.getString("description")%></td>
                <td><%=rs.getString("address")%></td>
                <td><%=rs.getString("status")%></td>
                <td>
                    <form action="adminDashboard.jsp" method="post" enctype="multipart/form-data">
                        <input type="hidden" name="complaintId" value="<%=rs.getInt("complaint_id")%>">
                        <select name="status" class="form-control" required>
                            <option value="Pending">Pending</option>
                            <option value="Solved">Solved</option>
                        </select>
                        <input type="file" name="solvedPhoto">
                        <br>
                        <button type="submit" class="btn btn-success btn-3d">Update</button>
                    </form>
                </td>
            </tr>
            <%
                        }
                            rs.close();
                            pst.close();
                        }
                    } catch(Exception e) { e.printStackTrace(); out.println("<tr><td colspan='8'>Error fetching complaints.</td></tr>"); }
                    finally { if(con!=null) con.close(); }
                }
            %>
        </table>
        <div class="form-group" style="display:flex; gap:10px; flex-wrap:wrap; margin-top:10px;">
            <button type="button" onclick="window.location.href='<%= base %>/adminConfigHealth.jsp';" class="btn btn-warning btn-3d">Config Health Check</button>
            <button type="button" onclick="window.location.href='<%= base %>/index.jsp';" class="btn btn-primary btn-3d">Back to Home</button>
        </div>
    </div>
    <script>
        (function () {
            var msg = document.getElementById('dashboardSearchError');
            if (msg) {
                setTimeout(function () {
                    if (msg && msg.parentNode) {
                        msg.parentNode.removeChild(msg);
                    }
                }, 2500);
            }

            var form = document.getElementById('adminSearchForm');
            var codeInput = document.getElementById('adminSearchCode');
            var idInput = document.getElementById('adminSearchId');
            if (!form || !codeInput || !idInput) return;

            form.addEventListener('submit', function (event) {
                var codeVal = (codeInput.value || '').trim();
                var idVal = (idInput.value || '').trim();
                if (codeVal || idVal) return;

                event.preventDefault();

                codeInput.classList.add('required-temp-invalid');
                idInput.classList.add('required-temp-invalid');

                var existing = document.getElementById('dashboardSearchError');
                if (existing && existing.parentNode) {
                    existing.parentNode.removeChild(existing);
                }

                var notice = document.createElement('div');
                notice.className = 'required-fields-msg';
                notice.id = 'dashboardSearchError';
                notice.textContent = 'please fill all required fields.';
                form.parentNode.insertBefore(notice, form);

                setTimeout(function () {
                    codeInput.classList.remove('required-temp-invalid');
                    idInput.classList.remove('required-temp-invalid');
                    if (notice && notice.parentNode) {
                        notice.parentNode.removeChild(notice);
                    }
                }, 2500);
            });
        })();
    </script>
    <script src="assets/js/main.js"></script>
</body>
</html>
