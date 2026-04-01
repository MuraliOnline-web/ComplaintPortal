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

        out.println("<div class='container-3d'>");
        if (rs.next()) {
            out.println("<h2>Complaint Details</h2>");
            out.println("<p><b>Complaint ID:</b> " + rs.getInt("complaint_id") + "</p>");
            out.println("<p><b>Complaint Code:</b> " + (rs.getString("complaint_code") == null ? "-" : rs.getString("complaint_code")) + "</p>");
            out.println("<p><b>User:</b> " + rs.getString("user_name") + " (" + rs.getString("user_email") + ", " + rs.getString("user_mobile") + ")</p>");
            out.println("<p><b>Category:</b> " + rs.getString("category") + "</p>");
            out.println("<p><b>Description:</b> " + rs.getString("description") + "</p>");
            out.println("<p><b>Address:</b> " + rs.getString("address") + "</p>");
            out.println("<p><b>Status:</b> " + rs.getString("status") + "</p>");
            out.println("<p><b>Officer:</b> " + "-" + "</p>");
            out.println("<p><b>Officer Notes:</b> " + (rs.getString("officer_notes") == null ? "-" : rs.getString("officer_notes")) + "</p>");
            out.println("<p><b>Created:</b> " + rs.getTimestamp("created_at") + "</p>");
            out.println("<p><b>Last Updated:</b> " + rs.getTimestamp("updated_at") + "</p>");
            if (rs.getString("solved_photo_path") != null) {
                out.println("<p><b>Solved Photo:</b><br><img src='../" + rs.getString("solved_photo_path") + "' width='220' style='border-radius:8px'></p>");
            }
        } else {
            safeRedirect(response, base + dashboard + "?searchError=notfound");
            return;
        }
        out.println("<div style='margin-top:12px'>");
        if ("admin".equals(role)) {
            out.println("<a class='btn btn-secondary btn-3d' href='" + base + "/adminDashboard.jsp'>Back to Admin Dashboard</a>");
        } else {
            out.println("<a class='btn btn-secondary btn-3d' href='" + base + "/officerDashboard.jsp'>Back to Officer Dashboard</a>");
        }
        out.println("</div>");
        out.println("</div>");
    } catch(Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + dashboard + "?searchError=error");
        return;
    } finally {
        if (con != null) con.close();
    }
%>
