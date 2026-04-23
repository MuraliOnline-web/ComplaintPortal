<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
    response.setStatus(302);
    response.setHeader("Location", ctx + "/WebContent/index.jsp");
%>
