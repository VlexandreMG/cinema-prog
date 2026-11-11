<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // 1. LIRE ce qui a déjà été choisi
    String idParent = request.getParameter("idparent");

    // 2. APPELER le service (avec null : il ouvre et ferme sa connexion)
    Parent[] parents = MonService.listerParents(null);
%>
<div class="content-wrapper">
    <!-- 3. AFFICHER, en protégeant chaque texte venu de la base -->
    
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>