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
    // Only admin/officer can access
    String role = (String) session.getAttribute("role");
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    if(role == null || (!role.equals("admin") && !role.equals("officer"))) {
        safeRedirect(response, base + "/login.jsp");
        return;
    }

    String code = request.getParameter("code");
    String idParam = request.getParameter("id");
    Integer id = null;
    if (idParam != null && !idParam.isBlank()) {
        try { id = Integer.parseInt(idParam.trim()); } catch(Exception ignore) {}
    }

    String dashboard = "admin".equals(role) ? "/adminDashboard.jsp" : "/officerDashboard.jsp";

    if ((code == null || code.isBlank()) && id == null) {
        safeRedirect(response, base + dashboard + "?searchError=1");
        return;
    }

    String dbUrl = getConfig(application, "db.url", "");
    String dbUser = getConfig(application, "db.user", "");
    String dbPassword = getConfig(application, "db.password", "");
    if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
        safeRedirect(response, base + dashboard + "?searchError=db");
        return;
    }

    Connection con = openConnection(application, dbUrl, dbUser, dbPassword);
    try {
        String sql = "SELECT c.complaint_id, c.complaint_code, c.category, c.description, c.address, c.status, " +
                 "c.officer_notes, c.solved_photo_path, c.created_at, c.updated_at, u.name as user_name, u.email as user_email, u.mobile as user_mobile " +
                     "FROM complaints c JOIN users u ON c.user_id=u.user_id WHERE 1=1" +
                     (code != null && !code.isBlank() ? " AND c.complaint_code=?" : "") +
                     (id != null ? " AND c.complaint_id=?" : "");
        PreparedStatement pst = con.prepareStatement(sql);
        int idx = 1;
        if (code != null && !code.isBlank()) pst.setString(idx++, code.trim());
        if (id != null) pst.setInt(idx++, id);
        ResultSet rs = pst.executeQuery();

        if (rs.next()) {
            out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1'>");
            out.println("<title>Complaint Details</title><link rel='stylesheet' href='../assets/css/style.css'><link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css' crossorigin='anonymous'><style>body.result-page{min-height:100vh;background:radial-gradient(circle at top left, rgba(79,70,229,.14), transparent 30%),radial-gradient(circle at bottom right, rgba(14,165,233,.1), transparent 32%),linear-gradient(180deg,#f8fafc 0%,#eef2ff 100%);} .result-card{border:1px solid rgba(148,163,184,.2);border-radius:28px;background:rgba(255,255,255,.9);box-shadow:0 24px 80px rgba(15,23,42,.08);}</style></head><body class='result-page'>");
            out.println("<main class='container py-4 py-lg-5'><div class='result-card p-4 p-md-5'><div class='d-flex flex-wrap justify-content-between align-items-start gap-3 mb-4'><div><div class='text-uppercase small fw-semibold text-primary'>Complaint lookup</div><h1 class='h2 fw-bold mb-2'>Complaint Details</h1><p class='text-secondary mb-0'>Search result for the selected complaint code or ID.</p></div><a class='btn btn-outline-primary' href='" + base + dashboard + "'>Back to Dashboard</a></div><div class='row g-4'><div class='col-lg-8'><div class='border rounded-4 p-4 bg-white h-100'><div class='row g-3'>");
            out.println("<div class='col-md-6'><div class='text-secondary small'>Complaint ID</div><div class='fw-semibold fs-5'>" + rs.getInt("complaint_id") + "</div></div>");
            out.println("<div class='col-md-6'><div class='text-secondary small'>Complaint Code</div><div class='fw-semibold fs-5'>" + (rs.getString("complaint_code") == null ? "-" : rs.getString("complaint_code")) + "</div></div>");
            out.println("<div class='col-md-6'><div class='text-secondary small'>User</div><div class='fw-semibold'>" + rs.getString("user_name") + " (" + rs.getString("user_email") + ", " + rs.getString("user_mobile") + ")</div></div>");
            out.println("<div class='col-md-6'><div class='text-secondary small'>Status</div><div class='fw-semibold'>" + rs.getString("status") + "</div></div>");
            out.println("<div class='col-12'><div class='text-secondary small'>Category</div><div class='fw-semibold'>" + rs.getString("category") + "</div></div>");
            out.println("<div class='col-12'><div class='text-secondary small'>Description</div><div class='fw-semibold'>" + rs.getString("description") + "</div></div>");
            out.println("<div class='col-12'><div class='text-secondary small'>Address</div><div class='fw-semibold'>" + rs.getString("address") + "</div></div>");
            out.println("<div class='col-md-6'><div class='text-secondary small'>Created</div><div class='fw-semibold'>" + rs.getTimestamp("created_at") + "</div></div>");
            out.println("<div class='col-md-6'><div class='text-secondary small'>Last Updated</div><div class='fw-semibold'>" + rs.getTimestamp("updated_at") + "</div></div>");
            out.println("<div class='col-12'><div class='text-secondary small'>Officer Notes</div><div class='fw-semibold'>" + (rs.getString("officer_notes") == null ? "-" : rs.getString("officer_notes")) + "</div></div>");
            if (rs.getString("solved_photo_path") != null) {
                out.println("<div class='col-12'><div class='text-secondary small mb-2'>Solved Photo</div><img src='../" + rs.getString("solved_photo_path") + "' class='img-fluid rounded-4 border' alt='Solved photo'></div>");
            }
            out.println("</div></div></div></div><div class='d-flex flex-wrap gap-2 mt-4'><a class='btn btn-secondary' href='" + base + ("admin".equals(role) ? "/adminDashboard.jsp" : "/officerDashboard.jsp") + "'>Back to Dashboard</a></div></div></main><script src='https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js' crossorigin='anonymous'></script></body></html>");
        } else {
            safeRedirect(response, base + dashboard + "?searchError=notfound");
            return;
        }
    } catch(Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + dashboard + "?searchError=error");
        return;
    } finally {
        if (con != null) con.close();
    }
%>
