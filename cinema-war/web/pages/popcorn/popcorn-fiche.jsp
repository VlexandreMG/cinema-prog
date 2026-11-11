<%--
    Popcorn, étape 3 : la fiche d'une vente payée.
    URL : module.jsp?but=popcorn/popcorn-fiche.jsp&id=TOY000001[&recu=10000]
    Doc : docs/conception/06_popcorn_paiement_workflow.md

    « recu » n'est présent que juste après le paiement : il sert à afficher la monnaie rendue.
    Les prix affichés sont ceux PAYÉS (recopiés dans TOYDETAIL), pas les prix actuels des types.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="toy.ToyService, toy.ToyLib, toy.ToyDetailLib" %>
<%@ page import="utils.CinemaUtil" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    String id = request.getParameter("id");
    ToyLib vente = ToyService.chargerToy(id, null);            // vue TOY_LIB
    ToyDetailLib[] lignes = ToyService.listerLignes(id, null); // vue TOYDETAIL_LIB

    Double recu = null;
    try { recu = Double.valueOf(request.getParameter("recu")); } catch (Exception ignore) { }
%>
<div class="content-wrapper">
    <h1>Vente <%= CinemaUtil.html(vente.getId()) %></h1>

    <div class="container">
        <% if (recu != null) { %>
        <div class="alert alert-success" style="max-width: 600px;">
            Paiement enregistr&eacute;. Re&ccedil;u : <%= CinemaUtil.montant(recu) %> Ar
            &mdash; monnaie &agrave; rendre : <strong><%= CinemaUtil.montant(recu - vente.getMontanttotal()) %> Ar</strong>.
        </div>
        <% } %>

        <table class="table table-condensed" style="max-width: 600px;">
            <tr><th>Client</th><td><%= CinemaUtil.html(vente.getClient()) %></td></tr>
            <tr><th>Paquet de popcorn</th><td><%= CinemaUtil.html(vente.getPopcorn()) %></td></tr>
        </table>

        <h3>Jouets (<%= lignes.length %>)</h3>
        <table class="table table-bordered" style="max-width: 600px;">
            <thead><tr><th>Jouet</th><th>Type</th><th class="text-right">Prix pay&eacute; (Ar)</th></tr></thead>
            <tbody>
            <% for (ToyDetailLib l : lignes) { %>
                <tr>
                    <td><%= CinemaUtil.html(l.getLib()) %></td>
                    <td><%= CinemaUtil.html(l.getTypejouet()) %></td>
                    <td class="text-right"><%= CinemaUtil.montant(l.getPrix()) %></td>
                </tr>
            <% } %>
            </tbody>
            <tfoot>
                <tr><th colspan="2">Total pay&eacute;</th><th class="text-right"><%= CinemaUtil.montant(vente.getMontanttotal()) %></th></tr>
            </tfoot>
        </table>

        <a class="btn btn-primary" href="<%= lien %>?but=popcorn/popcorn-saisie.jsp">Nouvelle vente</a>
    </div>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
