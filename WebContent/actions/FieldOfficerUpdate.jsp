<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="jakarta.servlet.http.*" %>
<%@ page import="jakarta.mail.*,jakarta.mail.internet.*,java.util.Properties" %>
<%@ page import="util.ConfigLoader" %>
<%@ page import="java.net.URLEncoder" %>
<%!
    private static void safeRedirect(jakarta.servlet.http.HttpServletResponse response, String location) throws java.io.IOException {
        response.setStatus(302);
        response.setHeader("Location", location);
    }
%>

<%
    String role = (String) session.getAttribute("role");
    if (role == null || (!"officer".equals(role) && !"admin".equals(role))) {
        safeRedirect(response, "../login.jsp?denied=1");
        return;
    }

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        try {
            String complaintIdRaw = request.getParameter("complaintId");
            String officerNotes = request.getParameter("officerNotes");
            String officerName = request.getParameter("officerName");

            if (complaintIdRaw == null || complaintIdRaw.isBlank() || officerNotes == null || officerNotes.isBlank() || officerName == null || officerName.isBlank()) {
                safeRedirect(response, "../officerDashboard.jsp?error=" + URLEncoder.encode("All required fields must be filled.", "UTF-8"));
                return;
            }

            int complaintId;
            try {
                complaintId = Integer.parseInt(complaintIdRaw.trim());
            } catch (Exception ex) {
                safeRedirect(response, "../officerDashboard.jsp?error=" + URLEncoder.encode("Invalid complaint id.", "UTF-8"));
                return;
            }

            // Handle report photo upload
            String reportPhotoPath = null;
            Part reportPhotoPart = request.getPart("reportPhoto");
            if (reportPhotoPart != null && reportPhotoPart.getSize() > 0) {
                String fileName = System.currentTimeMillis() + "_" + reportPhotoPart.getSubmittedFileName();
                String uploadDir = application.getRealPath("/") + "assets/images/uploads/";
                File dir = new File(uploadDir);
                if (!dir.exists()) dir.mkdirs();
                reportPhotoPart.write(uploadDir + fileName);
                reportPhotoPath = "assets/images/uploads/" + fileName;
            }

            // Load MySQL driver
            Class.forName("com.mysql.cj.jdbc.Driver");

            String dbUrl = ConfigLoader.getDbUrl();
            String dbUser = ConfigLoader.getDbUser();
            String dbPassword = ConfigLoader.getDbPassword();
            if (dbUrl == null || dbUrl.isBlank() || dbUser == null || dbUser.isBlank() || dbPassword == null || dbPassword.isBlank()) {
                safeRedirect(response, "../officerDashboard.jsp?error=" + URLEncoder.encode("Database is not configured. Contact admin.", "UTF-8"));
                return;
            }

            // Database connection
            Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);

            // Insert officer report only (admin performs complaint status changes)
            String sql = "INSERT INTO officer_reports(complaint_id, officer_name, report_notes, report_photo_path) VALUES(?,?,?,?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, complaintId);
            ps.setString(2, officerName);
            ps.setString(3, officerNotes);
            ps.setString(4, reportPhotoPath);
            ps.executeUpdate();

            // Send notification email to user
            String emailSql = "SELECT u.email, u.name FROM complaints c JOIN users u ON c.user_id=u.user_id WHERE c.complaint_id=?";
            PreparedStatement emailPs = con.prepareStatement(emailSql);
            emailPs.setInt(1, complaintId);
            ResultSet rs = emailPs.executeQuery();
            
            if (rs.next()) {
                String userEmail = rs.getString("email");
                String userName = rs.getString("name");
                String subject = "Complaint Status Update - #" + complaintId;
                String body = "Dear " + userName + ",\n\n" +
                             "Field officer " + officerName + " submitted a visit report for complaint #" + complaintId + ".\n" +
                             "Report Notes: " + officerNotes + "\n\n" +
                             "Admin will verify and update final status shortly.\n\n" +
                             "Thank you for using our complaint portal.";
                
                try {
                    String SYSTEM_EMAIL = ConfigLoader.getSmtpUser();
                    String SYSTEM_PASSWORD = ConfigLoader.getSmtpPassword();
                    String SMTP_HOST = ConfigLoader.getSmtpHost();
                    String SMTP_PORT = ConfigLoader.getSmtpPort();
                    if (SYSTEM_EMAIL == null || SYSTEM_EMAIL.isBlank() || SYSTEM_PASSWORD == null || SYSTEM_PASSWORD.isBlank()
                            || SMTP_HOST == null || SMTP_HOST.isBlank() || SMTP_PORT == null || SMTP_PORT.isBlank()) {
                        SYSTEM_EMAIL = null;
                    }
                    if (SYSTEM_EMAIL != null) {
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
                        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(userEmail));
                        message.setSubject(subject);
                        message.setText(body);
                        Transport.send(message);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            // Cleanup
            rs.close();
            emailPs.close();
            ps.close();
            con.close();

            safeRedirect(response, "../officerDashboard.jsp?success=" + URLEncoder.encode("Visit report submitted successfully", "UTF-8"));

        } catch (Exception e) {
            e.printStackTrace();
            safeRedirect(response, "../officerDashboard.jsp?error=" + URLEncoder.encode("Error submitting report. Please try again.", "UTF-8"));
        }
    } else {
        safeRedirect(response, "../officerDashboard.jsp");
    }
%>
