<!-- Insert complaint into DB -->
<%@ page import="java.io.*,java.sql.*,jakarta.servlet.http.*,jakarta.servlet.http.Part" %>
<%@ page import="jakarta.mail.*,jakarta.mail.internet.*,java.util.Properties" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }
%>
<%
    String role = (String) session.getAttribute("role");
    Integer sessionUserId = (Integer) session.getAttribute("userId");
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String registerComplaintPath = base + "/registerComplaint.jsp";
    String complaintSuccessPath = base + "/complaintSuccess.jsp";
    try {
        if (application.getResource("/registerComplaint.jsp") == null && application.getResource("/WebContent/registerComplaint.jsp") != null) {
            registerComplaintPath = ctx + "/WebContent/registerComplaint.jsp";
        }
        if (application.getResource("/complaintSuccess.jsp") == null && application.getResource("/WebContent/complaintSuccess.jsp") != null) {
            complaintSuccessPath = ctx + "/WebContent/complaintSuccess.jsp";
        }
    } catch (Exception ignore) {
        // Fall back to base-derived paths
    }
    if (role == null || !"user".equals(role) || sessionUserId == null) {
        safeRedirect(response, base + "/userLogin.jsp?required=1");
        return;
    }

    String name = request.getParameter("name");
    String email = request.getParameter("email");
    String mobile = request.getParameter("mobile");
    String address = request.getParameter("address");
    String category = request.getParameter("category");
    String description = request.getParameter("description");

    // Multipart forms may not always expose text fields through getParameter in JSP.
    boolean isMultipart = request.getContentType() != null && request.getContentType().toLowerCase().startsWith("multipart/");
    if (isMultipart) {
        if (name == null || name.trim().isEmpty()) {
            try {
                Part p = request.getPart("name");
                if (p != null) name = new String(p.getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8).trim();
            } catch (Exception ignore) {}
        }
        if (email == null || email.trim().isEmpty()) {
            try {
                Part p = request.getPart("email");
                if (p != null) email = new String(p.getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8).trim();
            } catch (Exception ignore) {}
        }
        if (mobile == null || mobile.trim().isEmpty()) {
            try {
                Part p = request.getPart("mobile");
                if (p != null) mobile = new String(p.getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8).trim();
            } catch (Exception ignore) {}
        }
        if (address == null || address.trim().isEmpty()) {
            try {
                Part p = request.getPart("address");
                if (p != null) address = new String(p.getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8).trim();
            } catch (Exception ignore) {}
        }
        if (category == null || category.trim().isEmpty()) {
            try {
                Part p = request.getPart("category");
                if (p != null) category = new String(p.getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8).trim();
            } catch (Exception ignore) {}
        }
        if (description == null || description.trim().isEmpty()) {
            try {
                Part p = request.getPart("description");
                if (p != null) description = new String(p.getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8).trim();
            } catch (Exception ignore) {}
        }
    }

    // Basic validation
    StringBuilder missing = new StringBuilder();
    if (name == null || name.trim().isEmpty()) missing.append("name, ");
    if (email == null || email.trim().isEmpty()) missing.append("email, ");
    if (mobile == null || mobile.trim().isEmpty()) missing.append("mobile, ");
    if (address == null || address.trim().isEmpty()) missing.append("address, ");
    if (category == null || category.trim().isEmpty()) missing.append("category, ");
    if (description == null || description.trim().isEmpty()) missing.append("description, ");
    if (missing.length() > 0) {
        safeRedirect(response, registerComplaintPath + "?error=" + URLEncoder.encode("please fill all required fields.", "UTF-8"));
        return;
    }

    // File upload handling: prefer base64 payload from standard form, fallback to multipart part.
    String photoPath = null;
    try {
        String photoData = request.getParameter("photoData");
        String photoName = request.getParameter("photoName");

        if (photoData != null && !photoData.trim().isEmpty()) {
            int commaIdx = photoData.indexOf(',');
            if (commaIdx > 0 && commaIdx < photoData.length() - 1) {
                String payload = photoData.substring(commaIdx + 1);
                byte[] fileBytes = Base64.getDecoder().decode(payload);

                String original = (photoName == null || photoName.trim().isEmpty()) ? "upload.jpg" : photoName;
                String safeName = original.replaceAll("[^a-zA-Z0-9._-]", "_");
                String fileName = System.currentTimeMillis() + "_" + safeName;
                String basePath = application.getRealPath("/");
                String uploadDir = basePath + (basePath.endsWith(File.separator) ? "" : File.separator) + "assets" + File.separator + "images" + File.separator + "uploads" + File.separator;
                File dir = new File(uploadDir);
                if (!dir.exists()) dir.mkdirs();

                try (FileOutputStream fos = new FileOutputStream(uploadDir + fileName)) {
                    fos.write(fileBytes);
                }
                photoPath = "assets/images/uploads/" + fileName;
            }
        } else {
            Part photoPart = request.getPart("photo");
            if (photoPart != null && photoPart.getSize() > 0) 
            {
                String original = photoPart.getSubmittedFileName();
                String safeName = (original == null ? "upload.jpg" : original.replaceAll("[^a-zA-Z0-9._-]", "_"));
                String fileName = System.currentTimeMillis() + "_" + safeName;
                String basePath = application.getRealPath("/");
                String uploadDir = basePath + (basePath.endsWith(File.separator) ? "" : File.separator) + "assets" + File.separator + "images" + File.separator + "uploads" + File.separator;
                File dir = new File(uploadDir);
                if (!dir.exists()) dir.mkdirs();
                photoPart.write(uploadDir + fileName);
                photoPath = "assets/images/uploads/" + fileName;
            }
        }
    } catch (Throwable uploadEx) {
        // If multipart isn't configured, skip photo and proceed
        uploadEx.printStackTrace();
    }

    // Direct JDBC connection
    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        safeRedirect(response, registerComplaintPath + "?error=" + URLEncoder.encode("Database is not configured. Contact admin.", "UTF-8"));
        return;
    }

    Connection con = null;
    try 
    {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
        int userId = sessionUserId.intValue();

        PreparedStatement pstUser = con.prepareStatement("SELECT name, email, mobile FROM users WHERE user_id=? AND role='user'");
        pstUser.setInt(1, userId);
        ResultSet rsUser = pstUser.executeQuery();
        if (rsUser.next()) {
            name = rsUser.getString("name");
            email = rsUser.getString("email");
            mobile = rsUser.getString("mobile");
        } else {
            safeRedirect(response, base + "/userLogin.jsp?required=1");
            return;
        }
        rsUser.close();
        pstUser.close();

        // Generate unique complaint_code like CMP-YYYYMMDD-XXXXXX
        String today = new java.text.SimpleDateFormat("yyyyMMdd").format(new java.util.Date());
        String complaintCode = null;
        boolean unique = false;
        while(!unique){
            String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            StringBuilder sb = new StringBuilder();
            java.util.Random rnd = new java.util.Random();
            for(int i=0;i<6;i++){ sb.append(chars.charAt(rnd.nextInt(chars.length()))); }
            complaintCode = "CMP-" + today + "-" + sb.toString();
            PreparedStatement chk = con.prepareStatement("SELECT 1 FROM complaints WHERE complaint_code=? LIMIT 1");
            chk.setString(1, complaintCode);
            ResultSet crs = chk.executeQuery();
            unique = !crs.next();
            crs.close();
            chk.close();
        }

        // Insert complaint (requires complaints.complaint_code column)
        PreparedStatement pst = con.prepareStatement("INSERT INTO complaints(user_id,category,description,address,photo_path,complaint_code) VALUES(?,?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS);
        pst.setInt(1, userId);
        pst.setString(2, category);
        pst.setString(3, description);
        pst.setString(4, address);
        pst.setString(5, photoPath);
        pst.setString(6, complaintCode);
        pst.executeUpdate();
        ResultSet rs = pst.getGeneratedKeys();
        int complaintId = 0;
        if(rs.next()) complaintId = rs.getInt(1);

        // Optionally send email (inline Jakarta Mail)
        try {
            final String SYSTEM_EMAIL = ConfigLoader.getSmtpUser();
            final String SYSTEM_PASSWORD = ConfigLoader.getSmtpPassword();
            final String SMTP_HOST = ConfigLoader.getSmtpHost();
            final String SMTP_PORT = ConfigLoader.getSmtpPort();

            if (SYSTEM_EMAIL != null && !SYSTEM_EMAIL.trim().isEmpty() && SYSTEM_PASSWORD != null && !SYSTEM_PASSWORD.trim().isEmpty()
                    && SMTP_HOST != null && !SMTP_HOST.trim().isEmpty() && SMTP_PORT != null && !SMTP_PORT.trim().isEmpty()) {
                Properties props = new Properties();
                props.put("mail.smtp.auth", "true");
                props.put("mail.smtp.starttls.enable", "true");
                props.put("mail.smtp.host", SMTP_HOST);
                props.put("mail.smtp.port", SMTP_PORT);
                Session mailSession = Session.getInstance(props, new Authenticator() {
                    @Override
                    protected PasswordAuthentication getPasswordAuthentication() {
                        return new PasswordAuthentication(SYSTEM_EMAIL, SYSTEM_PASSWORD);
                    }
                });
                Message message = new MimeMessage(mailSession);
                message.setFrom(new InternetAddress(SYSTEM_EMAIL));
                message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(email));
                message.setSubject("Complaint Registered Successfully");
                message.setText("Dear " + name + ",\n\n"
                    + "Your complaint has been registered successfully.\n"
                    + "Complaint ID: " + complaintId + "\n"
                    + "Complaint Code: " + complaintCode + "\n\n"
                    + "Please keep both details for tracking updates.\n"
                    + "We will update you once it is resolved.");
                Transport.send(message);
            }
        } catch (Exception mailEx) {
            // Log but do not block flow
            mailEx.printStackTrace();
        }

        // Redirect to a dedicated success page
        String safeName = (name == null || name.trim().isEmpty()) ? "User" : name;
        String target = complaintSuccessPath + "?id=" + complaintId + "&code=" + URLEncoder.encode(complaintCode, "UTF-8") + "&name=" + URLEncoder.encode(safeName, "UTF-8");
        safeRedirect(response, target);
    } 
    catch(Exception e)
    {
        e.printStackTrace();
        safeRedirect(response, registerComplaintPath + "?error=" + URLEncoder.encode("Error occurred while submitting complaint.", "UTF-8"));
    } 
    finally 
    {
        try {
            if (con != null) con.close();
        } catch (Exception ignore) {
            // Ignore close errors during cleanup
        }
    }
%>
