<%@ page import="java.io.*,java.sql.*,jakarta.servlet.http.*,jakarta.servlet.*" %>
<%@ page import="java.net.URL,java.net.URLClassLoader" %>
<%@ page import="java.util.Properties" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws java.io.IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }

    private static String getConfig(jakarta.servlet.ServletContext app, String key, String defaultValue) {
        String envKey = key.toUpperCase().replace('.', '_');
        String envVal = System.getenv(envKey);
        if (envVal != null && !envVal.trim().isEmpty()) {
            return envVal;
        }

        Properties props = new Properties();
        try (InputStream in = app.getResourceAsStream("/WEB-INF/classes/config.properties") != null
                ? app.getResourceAsStream("/WEB-INF/classes/config.properties")
                : app.getResourceAsStream("/WebContent/WEB-INF/classes/config.properties")) {
            if (in != null) {
                props.load(in);
                String val = props.getProperty(key);
                if (val != null && !val.trim().isEmpty()) {
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
        safeRedirect(response, base + "/adminDashboard.jsp");
        return;
    }

    int complaintId;
    try {
        complaintId = Integer.parseInt(complaintIdRaw.trim());
    } catch (Exception ex) {
        safeRedirect(response, base + "/adminDashboard.jsp");
        return;
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
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/adminDashboard.jsp");
        return;
    }

    Connection con = openConnection(application, dbUrl, dbUser, dbPassword);
    try {
        PreparedStatement pst = con.prepareStatement("UPDATE complaints SET status=?, solved_photo_path=? WHERE complaint_id=?");
        pst.setString(1, status);
        pst.setString(2, solvedPhotoPath);
        pst.setInt(3, complaintId);
        int changed = pst.executeUpdate();

        safeRedirect(response, base + "/adminDashboard.jsp");
        return;
    } catch (Exception e) {
        e.printStackTrace();
        safeRedirect(response, base + "/adminDashboard.jsp");
        return;
    } finally {
        if (con != null) con.close();
    }
%>
