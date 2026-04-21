<!-- Generate report data -->
 <%@ page import="java.sql.*" %>
<%@ page import="util.ConfigLoader" %>
<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%
    String dbUrl = ConfigLoader.getDbUrl();
    String dbUser = ConfigLoader.getDbUser();
    String dbPassword = ConfigLoader.getDbPassword();
    if (dbUrl == null || dbUrl.trim().isEmpty() || dbUser == null || dbUser.trim().isEmpty() || dbPassword == null || dbPassword.trim().isEmpty()) {
        out.print("{\"error\":\"Database configuration missing\"}");
        return;
    }

    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
    StringBuilder json = new StringBuilder();
    json.append("{");

    try 
    {
        PreparedStatement pst1 = con.prepareStatement("SELECT status, COUNT(*) as cnt FROM complaints GROUP BY status");
        ResultSet rs1 = pst1.executeQuery();
        json.append("\"status\":{");
        while(rs1.next()){
            json.append("\"").append(rs1.getString("status")).append("\":").append(rs1.getInt("cnt")).append(",");
        }
        if(json.charAt(json.length()-1)==',') json.setLength(json.length()-1);
        json.append("},");

        PreparedStatement pst2 = con.prepareStatement("SELECT category, COUNT(*) as cnt FROM complaints GROUP BY category");
        ResultSet rs2 = pst2.executeQuery();
        json.append("\"category\":{");
        while(rs2.next()){
            json.append("\"").append(rs2.getString("category")).append("\":").append(rs2.getInt("cnt")).append(",");
        }
        if(json.charAt(json.length()-1)==',') json.setLength(json.length()-1);
        json.append("}");
        json.append("}");

        out.print(json.toString());
    } 
    catch(Exception e)
    {
        e.printStackTrace();
        out.print("{\"error\":\"Unable to generate reports\"}");
    } 
    finally 
    {
        if(con!=null) con.close();
    }
%>