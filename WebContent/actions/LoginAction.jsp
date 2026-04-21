<!-- Admin login logic -->
<%@ page import="java.sql.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.io.File" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.net.URLClassLoader" %>
<%@ page import="java.util.Properties" %>
<%@ page import="javax.crypto.SecretKeyFactory" %>
<%@ page import="javax.crypto.spec.PBEKeySpec" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }

    private static String hashPassword(String password, String saltB64) throws Exception {
        byte[] salt = Base64.getDecoder().decode(saltB64);
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 65536, 256);
        SecretKeyFactory skf = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        return Base64.getEncoder().encodeToString(skf.generateSecret(spec).getEncoded());
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
    // Prevent caching of authenticated pages after logout
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String email = request.getParameter("email");
    String password = request.getParameter("password");
    String requestedRole = request.getParameter("role");

    String ctx = request.getContextPath();
    String base = ctx;
    try {
        if (application.getResource("/index.jsp") == null && application.getResource("/WebContent/index.jsp") != null) {
            base = ctx + "/WebContent";
        }
    } catch (Exception ignore) {
        // keep default base
    }

    // Load DB configuration from environment variables or local config.properties.
    String dbUrl = getConfig(application, "db.url", "");
    String dbUser = getConfig(application, "db.user", "");
    String dbPassword = getConfig(application, "db.password", "");
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, base + "/login.jsp?error=config");
        return;
    }

    Connection con = openConnection(application, dbUrl, dbUser, dbPassword);

    try 
    {
        PreparedStatement pst = con.prepareStatement(
            "SELECT user_id, name, role, password, password_hash, password_salt FROM users WHERE email=? AND role=? LIMIT 1"
        );
        pst.setString(1, email);
        pst.setString(2, requestedRole);

        ResultSet rs = pst.executeQuery();

        if(rs.next())
        {
            String legacyPassword = rs.getString("password");
            String storedHash = rs.getString("password_hash");
            String storedSalt = rs.getString("password_salt");

            boolean passwordOk = false;
            if (storedHash != null && !storedHash.trim().isEmpty() && storedSalt != null && !storedSalt.trim().isEmpty()) {
                String inputHash = hashPassword(password, storedSalt);
                passwordOk = inputHash.equals(storedHash);
            } else if (legacyPassword != null) {
                passwordOk = legacyPassword.equals(password);
            }

            if (!passwordOk) {
                safeRedirect(response, base + "/login.jsp?error=1");
                return;
            }

            // Create session
            int uid = rs.getInt("user_id");
            String uname = rs.getString("name");
            String dbRole = rs.getString("role");
            session.setAttribute("userId", uid);
            session.setAttribute("userName", uname);
            session.setAttribute("role", dbRole);
            session.setAttribute("flashMessage", "Login successful. Welcome, " + uname + ".");
            session.setAttribute("flashType", "success");

            // Redirect by actual DB role to proper dashboard
            if ("admin".equalsIgnoreCase(dbRole)) {
                safeRedirect(response, base + "/adminDashboard.jsp");
            } else if ("officer".equalsIgnoreCase(dbRole)) {
                safeRedirect(response, base + "/officerDashboard.jsp");
            } else {
                // Not an allowed role for this login portal
                session.invalidate();
                safeRedirect(response, base + "/login.jsp?denied=1");
                return;
            }
        } 
        else 
        {
            safeRedirect(response, base + "/login.jsp?error=1");
            return;
        }
    } 
    catch(Exception e)
    {
        e.printStackTrace();
        safeRedirect(response, base + "/login.jsp?error=1");
        return;
    } 
    finally 
    {
        if(con!=null) con.close();
    }
%>