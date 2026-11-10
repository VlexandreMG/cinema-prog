<%--
    Réservation, étape 2 : vérifier le choix, puis payer.
    URL : module.jsp?but=reservation/reservation-paiement.jsp&idclient=..&idseance=..&idplace=..&idplace=..

    Sans « acte » : affiche le récapitulatif (client, film, salle, séance, places, total)
                    et le formulaire de paiement (montant reçu -> monnaie à rendre).
    Avec acte=payer (POST) : vérifie le montant reçu, appelle ReservationService.reserver,
                    puis redirige vers la fiche de la réservation.

    Le paiement est immédiat et complet : la réservation n'est créée qu'au paiement.
    Le montant reçu n'est pas enregistré, il sert à calculer la monnaie à rendre.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="reservation.ReservationService, reservation.Reservation" %>
<%@ page import="client.Client" %>
<%@ page import="film.Film, film.Seance" %>
<%@ page import="salle.Salle, salle.PlaceLib" %>
<%@ page import="utils.CinemaUtil" %>
<%@ page import="user.UserEJB" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    String idclient = request.getParameter("idclient");
    String idseance = request.getParameter("idseance");
    String[] idplaces = request.getParameterValues("idplace");
    if (idclient == null || idclient.isEmpty()) throw new Exception("Choisissez un client.");
    if (idseance == null || idseance.isEmpty()) throw new Exception("Choisissez une séance.");
    if (idplaces == null || idplaces.length == 0) throw new Exception("Choisissez au moins une place.");

    // Le total vient toujours du serveur, jamais du navigateur
    double total = ReservationService.calculerMontant(idplaces, null);

    // ═══ PAYER ═══
    if ("payer".equals(request.getParameter("acte")) && "POST".equalsIgnoreCase(request.getMethod())) {
        UserEJB u = (UserEJB) session.getAttribute("u");
        if (u == null) throw new Exception("Session expirée : reconnectez-vous.");

        double recu;
        try {
            recu = Double.parseDouble(request.getParameter("montantrecu").trim().replace(" ", "").replace(",", "."));
        } catch (Exception ex) {
            throw new Exception("Montant reçu invalide.");
        }
        if (recu < total) {
            throw new Exception("Montant reçu insuffisant : il manque " + CinemaUtil.montant(total - recu) + " Ar.");
        }

        Reservation r = ReservationService.reserver(idclient, idseance, idplaces,
                u.getUser().getTuppleID(), null);
%>
<script>
    document.location.replace("<%= lien %>?but=reservation/reservation-fiche.jsp&id=<%= r.getId() %>&recu=<%= recu %>");
</script>
<%
        return;
    }

    // ═══ RÉCAPITULATIF ═══
    Client client = (Client) CinemaUtil.parId(new Client(), idclient, null);
    Seance seance = (Seance) CinemaUtil.parId(new Seance(), idseance, null);
    Film   film   = (Film) CinemaUtil.parId(new Film(), seance.getIdfilm(), null);
    Salle  salle  = ReservationService.salleDuFilm(film.getId(), null);
    PlaceLib[] places = ReservationService.chargerPlaces(idplaces, null);

    // Lien « Modifier » : retour à la saisie avec le même choix
    StringBuilder retour = new StringBuilder(lien + "?but=reservation/reservation-saisie.jsp");
    retour.append("&idclient=").append(java.net.URLEncoder.encode(idclient, "UTF-8"));
    retour.append("&idfilm=").append(java.net.URLEncoder.encode(film.getId(), "UTF-8"));
    retour.append("&idseance=").append(java.net.URLEncoder.encode(idseance, "UTF-8"));
    for (String p : idplaces) retour.append("&idplace=").append(java.net.URLEncoder.encode(p, "UTF-8"));
%>
<div class="content-wrapper">
    <h1>V&eacute;rifier et payer</h1>

    <div class="container">
        <table class="table table-condensed" style="max-width: 600px;">
            <tr><th>Client</th><td><%= CinemaUtil.html(client.getNom()) %></td></tr>
            <tr><th>Film</th><td><%= CinemaUtil.html(film.getTitre()) %> (<%= film.getDuree() %> min)</td></tr>
            <tr><th>Salle</th><td><%= CinemaUtil.html(salle.getNom()) %></td></tr>
            <tr><th>S&eacute;ance</th><td><%= CinemaUtil.date(seance.getDaty()) %> &agrave; <%= CinemaUtil.html(seance.getHeure()) %></td></tr>
        </table>

        <h3>Places (<%= places.length %>)</h3>
        <table class="table table-bordered" style="max-width: 600px;">
            <thead><tr><th>Place</th><th>Type</th><th class="text-right">Prix (Ar)</th></tr></thead>
            <tbody>
            <% for (PlaceLib p : places) { %>
                <tr>
                    <td><%= CinemaUtil.html(p.getNumero()) %></td>
                    <td><%= CinemaUtil.html(p.getTypeplace()) %></td>
                    <td class="text-right"><%= CinemaUtil.montant(p.getPrix()) %></td>
                </tr>
            <% } %>
            </tbody>
            <tfoot>
                <tr><th colspan="2">Total</th><th class="text-right"><%= CinemaUtil.montant(total) %></th></tr>
            </tfoot>
        </table>

        <h3>Paiement</h3>
        <form id="formPaiement" action="<%= lien %>" method="post" style="max-width: 600px;"
              onsubmit="return verifier();">
            <input type="hidden" name="but"      value="reservation/reservation-paiement.jsp">
            <input type="hidden" name="acte"     value="payer">
            <input type="hidden" name="idclient" value="<%= CinemaUtil.html(idclient) %>">
            <input type="hidden" name="idseance" value="<%= CinemaUtil.html(idseance) %>">
            <% for (String p : idplaces) { %>
            <input type="hidden" name="idplace" value="<%= CinemaUtil.html(p) %>">
            <% } %>

            <div class="form-group">
                <label>Montant &agrave; payer (Ar)</label>
                <input type="text" class="form-control" readonly value="<%= CinemaUtil.montant(total) %>">
            </div>
            <div class="form-group">
                <label for="montantrecu">Montant re&ccedil;u (Ar)</label>
                <input type="number" name="montantrecu" id="montantrecu" class="form-control"
                       min="<%= (long) total %>" step="any" value="<%= (long) total %>" oninput="majMonnaie()" required>
            </div>
            <div class="form-group">
                <label for="monnaie">Monnaie &agrave; rendre (Ar)</label>
                <input type="text" id="monnaie" class="form-control" readonly value="0">
            </div>

            <a class="btn btn-default" href="<%= retour %>">Modifier</a>
            <button type="submit" id="btnPayer" class="btn btn-success pull-right">Payer</button>
        </form>
    </div>
</div>

<script>
    var TOTAL = <%= total %>;

    function majMonnaie() {
        var recu = parseFloat(document.getElementById('montantrecu').value) || 0;
        var monnaie = recu - TOTAL;
        document.getElementById('monnaie').value = monnaie >= 0 ? monnaie.toLocaleString('fr-FR') : 'insuffisant';
    }

    function verifier() {
        var recu = parseFloat(document.getElementById('montantrecu').value) || 0;
        if (recu < TOTAL) { alert('Le montant reçu est insuffisant.'); return false; }
        document.getElementById('btnPayer').disabled = true;   // évite un double paiement (double clic)
        return true;
    }

    majMonnaie();
</script>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
