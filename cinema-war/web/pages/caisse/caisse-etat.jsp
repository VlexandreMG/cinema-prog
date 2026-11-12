<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="caisse.CaisseService, caisse.Caisse" %>
<%@ page import="utils.CinemaUtil" %>
<%
try {
    Caisse caisse = CaisseService.caissePrincipale(null);
    double solde = CaisseService.solde(caisse.getId(), null);
%>
<div class="content-wrapper">
    <h1>&Eacute;tat de la caisse</h1>

    <div class="container">
        <table class="table table-condensed" style="max-width: 600px;">
            <tr><th>Caisse</th><td><%= CinemaUtil.html(caisse.getNom()) %></td></tr>
            <tr><th>Solde actuel</th>
                <td><strong style="font-size: 1.3em;"><%= CinemaUtil.montant(solde) %> Ar</strong></td></tr>
        </table>
    </div>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
