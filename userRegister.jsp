<%
    String target = request.getContextPath() + "/WebContent/userRegister.jsp";
    String query = request.getQueryString();
    if (query != null && !query.isBlank()) {
        target = target + "?" + query;
    }
    response.sendRedirect(target);
%>
