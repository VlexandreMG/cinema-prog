<%--
    État de la caisse : le solde, puis les mouvements (entrées / sorties) avec une recherche.
    URL : module.jsp?but=caisse/caisse-etat.jsp
    Squelette : docs/apprentissageAPJ/squelettes_pages_apj.md §6 (liste avec recherche)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="affichage.PageRecherche" %>
<%@ page import="caisse.CaisseService, caisse.Caisse, caisse.MouvementCaisse" %>
<%@ page import="utils.CinemaUtil" %>
<%@ page import="user.UserEJB" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";
    UserEJB u = (UserEJB) session.getValue("u");

    // ── LA CAISSE ET SON SOLDE (calculé par le service) ──
    Caisse caisse = CaisseService.caissePrincipale(null);
    double solde = CaisseService.solde(caisse.getId(), null);

    // ── SES MOUVEMENTS : plusieurs lignes, avec recherche → PageRecherche ──
    String[] criteres  = {"designation", "daty"};                  // les champs du formulaire de recherche
    String[] intervals = {"daty"};                                 // daty → daty1 (du) … daty2 (au)
    String[] colonnes  = {"daty", "designation", "entree", "sortie", "idorigine"};

    PageRecherche pr = new PageRecherche(new MouvementCaisse(), request, criteres, intervals, 3, colonnes, colonnes.length);
    pr.setTitre("&Eacute;tat de la caisse");
    pr.setUtilisateur(u);
    pr.setLien(lien);
    pr.setApres("caisse/caisse-etat.jsp");                         // la recherche revient sur cette page
    pr.setAWhere(" and idcaisse = '" + CinemaUtil.echapper(caisse.getId()) + "'");

    pr.getFormu().getChamp("designation").setLibelle("D&eacute;signation");
    pr.getFormu().getChamp("daty1").setLibelle("Du");
    pr.getFormu().getChamp("daty2").setLibelle("Au");

    pr.creerObjetPage(colonnes, new String[]{"entree", "sortie"}); // la requête ; totaux des entrées et sorties
    pr.getTableau().setLibelleAffiche(new String[]{"Date", "D&eacute;signation", "Entr&eacute;e (Ar)", "Sortie (Ar)", "Origine"});
%>
<div class="content-wrapper">
    <h1><%= pr.getTitre() %></h1>

    <table class="table table-condensed" style="max-width: 600px;">
        <tr><th>Caisse</th><td><%= CinemaUtil.html(caisse.getNom()) %></td></tr>
        <tr><th>Solde actuel</th><td><strong style="font-size: 1.3em;"><%= CinemaUtil.montant(solde) %> Ar</strong></td></tr>
    </table>

    <h3>Mouvements</h3>
    <form action="<%= lien %>?but=<%= pr.getApres() %>" method="post">
        <%= pr.getFormu().getHtmlEnsemble() %>
    </form>
    <%= pr.getTableauRecap().getHtml() %>
    <%= pr.getTableau().getHtml() %>
    <%= pr.getBasPage() %>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
