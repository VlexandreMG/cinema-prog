<%--
    Réservation, étape 1 : choisir le client, le film, la séance et les places.
    URL : module.jsp?but=reservation/reservation-saisie.jsp

    La page se recharge elle-même (GET) à chaque choix dans une liste :
      film choisi    -> salle (lecture seule) + séances à venir
      séance choisie -> places libres
    Le total se met à jour en JavaScript quand on coche une place (affichage seulement).
    « Continuer vers le paiement » envoie le choix à reservation-paiement.jsp.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="reservation.ReservationService" %>
<%@ page import="client.Client" %>
<%@ page import="film.Film, film.Seance" %>
<%@ page import="salle.Salle, salle.PlaceLib" %>
<%@ page import="utils.CinemaUtil" %>
<%@ page import="java.util.Arrays, java.util.HashSet, java.util.Set" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // ── Ce qui a déjà été choisi (paramètres de l'URL) ──
    String idclient = request.getParameter("idclient");
    String idfilm   = request.getParameter("idfilm");
    String idseance = request.getParameter("idseance");
    String[] coches = request.getParameterValues("idplace");
    Set<String> placesCochees = new HashSet<String>();
    if (coches != null) placesCochees.addAll(Arrays.asList(coches));

    // ── Les données des listes ──
    Client[] clients = ReservationService.listerClients(null);
    Film[]   films   = ReservationService.listerFilms(null);
    Salle    salle   = null;
    Seance[] seances = new Seance[0];
    PlaceLib[] places = new PlaceLib[0];

    if (idfilm != null && !idfilm.isEmpty()) {
        salle   = ReservationService.salleDuFilm(idfilm, null);
        seances = ReservationService.listerSeances(idfilm, null);
        // La séance choisie doit appartenir au film (sinon on a changé de film) et être à venir
        boolean seanceValide = false;
        for (Seance s : seances) {
            if (s.getId().equals(idseance)) seanceValide = true;
        }
        if (!seanceValide) idseance = null;
    } else {
        idseance = null;
    }
    if (idseance != null) {
        places = ReservationService.listerPlacesLibres(idseance, null);
    }
%>
<div class="content-wrapper">
    <h1>R&eacute;server des places</h1>
    <p class="text-muted">Choisissez le client, le film et la s&eacute;ance, puis cochez les places.</p>

    <form id="formReservation" class="container" action="<%= lien %>" method="get">
        <input type="hidden" name="but" id="but" value="reservation/reservation-saisie.jsp">

        <div class="row">
            <div class="col-md-4 form-group">
                <label for="idclient">Client</label>
                <select name="idclient" id="idclient" class="form-control">
                    <option value="">-- Choisir --</option>
                    <% for (Client c : clients) { %>
                    <option value="<%= CinemaUtil.html(c.getId()) %>"
                            <%= c.getId().equals(idclient) ? "selected" : "" %>>
                        <%= CinemaUtil.html(c.getNom()) %>
                    </option>
                    <% } %>
                </select>
            </div>

            <div class="col-md-4 form-group">
                <label for="idfilm">Film</label>
                <select name="idfilm" id="idfilm" class="form-control" onchange="changerFilm()">
                    <option value="">-- Choisir --</option>
                    <% for (Film f : films) { %>
                    <option value="<%= CinemaUtil.html(f.getId()) %>"
                            <%= f.getId().equals(idfilm) ? "selected" : "" %>>
                        <%= CinemaUtil.html(f.getTitre()) %> (<%= f.getDuree() %> min)
                    </option>
                    <% } %>
                </select>
            </div>

            <div class="col-md-4 form-group">
                <label for="salle">Salle</label>
                <input type="text" id="salle" class="form-control" readonly
                       value="<%= salle == null ? "" : CinemaUtil.html(salle.getNom()) %>">
            </div>
        </div>

        <div class="row">
            <div class="col-md-4 form-group">
                <label for="idseance">S&eacute;ance</label>
                <select name="idseance" id="idseance" class="form-control" onchange="recharger()"
                        <%= idfilm == null || idfilm.isEmpty() ? "disabled" : "" %>>
                    <option value="">-- Choisir --</option>
                    <% for (Seance s : seances) { %>
                    <option value="<%= CinemaUtil.html(s.getId()) %>"
                            <%= s.getId().equals(idseance) ? "selected" : "" %>>
                        <%= CinemaUtil.date(s.getDaty()) %> &agrave; <%= CinemaUtil.html(s.getHeure()) %>
                    </option>
                    <% } %>
                </select>
                <% if (idfilm != null && !idfilm.isEmpty() && seances.length == 0) { %>
                <small class="text-danger">Aucune s&eacute;ance &agrave; venir pour ce film.</small>
                <% } %>
            </div>
        </div>

        <% if (idseance != null) { %>
        <h3>Places libres</h3>
        <% if (places.length == 0) { %>
        <p class="text-danger">Cette s&eacute;ance est compl&egrave;te.</p>
        <% } else { %>
        <table class="table table-bordered table-hover">
            <thead>
                <tr><th></th><th>Place</th><th>Type</th><th class="text-right">Prix (Ar)</th></tr>
            </thead>
            <tbody>
            <% for (PlaceLib p : places) { %>
                <tr>
                    <td>
                        <input type="checkbox" name="idplace" class="case-place"
                               value="<%= CinemaUtil.html(p.getId()) %>" data-prix="<%= p.getPrix() %>"
                               <%= placesCochees.contains(p.getId()) ? "checked" : "" %>
                               onchange="majTotal()">
                    </td>
                    <td><%= CinemaUtil.html(p.getNumero()) %></td>
                    <td><%= CinemaUtil.html(p.getTypeplace()) %></td>
                    <td class="text-right"><%= CinemaUtil.montant(p.getPrix()) %></td>
                </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
        <% } %>

        <div class="row">
            <div class="col-md-4 form-group">
                <label for="total">Total (Ar)</label>
                <input type="text" id="total" class="form-control" readonly value="0">
            </div>
            <div class="col-md-8 form-group" style="padding-top: 25px;">
                <button type="button" class="btn btn-primary pull-right" onclick="continuer()">
                    Continuer vers le paiement
                </button>
            </div>
        </div>
    </form>
</div>

<script>
    // Recharge la page pour mettre à jour les listes qui dépendent du choix
    function recharger() {
        document.getElementById('but').value = 'reservation/reservation-saisie.jsp';
        document.getElementById('formReservation').submit();
    }

    // Changer de film : l'ancienne séance et les places cochées ne valent plus
    function changerFilm() {
        document.getElementById('idseance').value = '';
        var cases = document.querySelectorAll('.case-place');
        for (var i = 0; i < cases.length; i++) cases[i].checked = false;
        recharger();
    }

    // Total des places cochées (affichage seulement : le serveur recalcule au paiement)
    function majTotal() {
        var total = 0;
        var cases = document.querySelectorAll('.case-place:checked');
        for (var i = 0; i < cases.length; i++) total += parseFloat(cases[i].getAttribute('data-prix'));
        document.getElementById('total').value = total.toLocaleString('fr-FR');
    }

    // Passe au récapitulatif, si le choix est complet
    function continuer() {
        if (!document.getElementById('idclient').value) { alert('Choisissez un client.'); return; }
        if (!document.getElementById('idseance').value) { alert('Choisissez un film et une séance.'); return; }
        if (document.querySelectorAll('.case-place:checked').length === 0) { alert('Cochez au moins une place.'); return; }
        document.getElementById('but').value = 'reservation/reservation-paiement.jsp';
        document.getElementById('formReservation').submit();
    }

    majTotal();
</script>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
