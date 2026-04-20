<%
    String target = request.getContextPath() + "/WebContent/registerComplaint.jsp";
    String query = request.getQueryString();
    if (query != null && !query.isBlank()) {
        target = target + "?" + query;
    }
    response.sendRedirect(target);
%>
