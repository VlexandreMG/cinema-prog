<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // ── PRÉPARATION : ici, on lira les paramètres et on appellera le service ──

%>
<div class="content-wrapper">
    <h1>R&eacute;server des places</h1>

    <%-- ── AFFICHAGE : ici, on construira le formulaire ── --%>

</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
