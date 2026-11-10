<%--
    Réservation, étape 3 : la fiche d'une réservation payée.
    URL : module.jsp?but=reservation/reservation-fiche.jsp&id=RSV000001[&recu=50000]

    « recu » n'est présent que juste après le paiement : il sert à afficher la monnaie rendue.
    Les prix affichés sont ceux payés (recopiés dans RESERVATIONDETAIL).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="reservation.ReservationService, reservation.ReservationLib, reservation.ReservationDetailLib" %>
<%@ page import="utils.CinemaUtil" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    String id = request.getParameter("id");
    ReservationLib r = ReservationService.chargerReservation(id, null);
    ReservationDetailLib[] lignes = ReservationService.listerLignes(id, null);

    Double recu = null;
    try { recu = Double.valueOf(request.getParameter("recu")); } catch (Exception ignore) { }
%>
<div class="content-wrapper">
    <h1>R&eacute;servation <%= CinemaUtil.html(r.getId()) %></h1>

    <div class="container">
        <% if (recu != null) { %>
        <div class="alert alert-success" style="max-width: 600px;">
            Paiement enregistr&eacute;. Re&ccedil;u : <%= CinemaUtil.montant(recu) %> Ar
            &mdash; monnaie rendue : <strong><%= CinemaUtil.montant(recu - r.getMontanttotal()) %> Ar</strong>.
        </div>
        <% } %>

        <table class="table table-condensed" style="max-width: 600px;">
            <tr><th>Client</th><td><%= CinemaUtil.html(r.getClient()) %></td></tr>
            <tr><th>Film</th><td><%= CinemaUtil.html(r.getFilm()) %></td></tr>
            <tr><th>Salle</th><td><%= CinemaUtil.html(r.getSalle()) %></td></tr>
            <tr><th>S&eacute;ance</th><td><%= CinemaUtil.date(r.getDateseance()) %> &agrave; <%= CinemaUtil.html(r.getHeure()) %></td></tr>
            <tr><th>R&eacute;serv&eacute;e le</th><td><%= CinemaUtil.date(r.getDaty()) %></td></tr>
        </table>

        <h3>Places (<%= lignes.length %>)</h3>
        <table class="table table-bordered" style="max-width: 600px;">
            <thead><tr><th>Place</th><th>Type</th><th class="text-right">Prix pay&eacute; (Ar)</th></tr></thead>
            <tbody>
            <% for (ReservationDetailLib l : lignes) { %>
                <tr>
                    <td><%= CinemaUtil.html(l.getNumero()) %></td>
                    <td><%= CinemaUtil.html(l.getTypeplace()) %></td>
                    <td class="text-right"><%= CinemaUtil.montant(l.getPrix()) %></td>
                </tr>
            <% } %>
            </tbody>
            <tfoot>
                <tr><th colspan="2">Total pay&eacute;</th><th class="text-right"><%= CinemaUtil.montant(r.getMontanttotal()) %></th></tr>
            </tfoot>
        </table>

        <a class="btn btn-primary" href="<%= lien %>?but=reservation/reservation-saisie.jsp">Nouvelle r&eacute;servation</a>
    </div>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
