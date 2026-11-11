<%--
    Popcorn, étape 1 : choisir le client, le paquet de popcorn et les jouets à acheter.
    URL : module.jsp?but=popcorn/popcorn-saisie.jsp
    Doc : docs/conception/05_popcorn_saisie.md

    Le formulaire est envoyé en POST :
      - vers CETTE page quand on change de paquet (onchange) → la liste des jouets se met à jour ;
      - vers popcorn-paiement.jsp avec le bouton « Continuer » (attribut formaction, sans JavaScript).
    Le seul JavaScript : le total affiché quand on coche un jouet (affichage seulement,
    le serveur recalcule le vrai total dans Toy.createObject).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="reservation.ReservationService" %>
<%@ page import="toy.ToyService" %>
<%@ page import="client.Client" %>
<%@ page import="pop.Popcorn" %>
<%@ page import="jouet.JouetLib" %>
<%@ page import="utils.CinemaUtil" %>
<%@ page import="java.util.Arrays, java.util.HashSet, java.util.Set" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // ── 1. LIRE ce qui a déjà été choisi ──
    String idclient  = request.getParameter("idclient");
    String idpopcorn = request.getParameter("idpopcorn");
    String[] coches  = request.getParameterValues("idjouet");
    Set<String> jouetsCoches = new HashSet<String>();
    if (coches != null) jouetsCoches.addAll(Arrays.asList(coches));
    boolean paquetChoisi = idpopcorn != null && !idpopcorn.isEmpty();

    // ── 2. APPELER le service ──
    Client[]   clients  = ReservationService.listerClients(null);   // les clients sont communs au cinéma
    Popcorn[]  popcorns = ToyService.listerPopcorn(null);
    JouetLib[] jouets   = paquetChoisi
            ? ToyService.listerJouetsDisponibles(idpopcorn, null)   // seulement ceux encore à vendre
            : new JouetLib[0];
%>
<div class="content-wrapper">
    <h1>Vendre des jouets de popcorn</h1>
    <p class="text-muted">Choisissez le client et le paquet, puis cochez les jouets &agrave; acheter.</p>

    <form id="formPopcorn" class="container" method="post"
          action="<%= lien %>?but=popcorn/popcorn-saisie.jsp">

        <div class="row">
            <%-- Client --%>
            <div class="col-md-4 form-group">
                <label for="idclient">Client</label>
                <select name="idclient" id="idclient" class="form-control" required>
                    <option value="">-- Choisir --</option>
                    <% for (Client c : clients) { %>
                    <option value="<%= CinemaUtil.html(c.getId()) %>"
                            <%= c.getId().equals(idclient) ? "selected" : "" %>>
                        <%= CinemaUtil.html(c.getNom()) %>
                    </option>
                    <% } %>
                </select>
            </div>

            <%-- Paquet de popcorn : le changer recharge la page (sans fonction JavaScript) --%>
            <div class="col-md-4 form-group">
                <label for="idpopcorn">Paquet de popcorn</label>
                <select name="idpopcorn" id="idpopcorn" class="form-control" required
                        onchange="this.form.submit()">
                    <option value="">-- Choisir --</option>
                    <% for (Popcorn p : popcorns) { %>
                    <option value="<%= CinemaUtil.html(p.getId()) %>"
                            <%= p.getId().equals(idpopcorn) ? "selected" : "" %>>
                        <%= CinemaUtil.html(p.getNom()) %>
                    </option>
                    <% } %>
                </select>
            </div>
        </div>

        <%-- Les jouets disponibles du paquet choisi --%>
        <% if (paquetChoisi) { %>
        <h3>Jouets disponibles</h3>
            <% if (jouets.length == 0) { %>
        <p class="text-danger">Tous les jouets de ce paquet sont d&eacute;j&agrave; vendus.</p>
            <% } else { %>
        <table class="table table-bordered table-hover">
            <thead>
                <tr><th></th><th>Jouet</th><th>Type</th><th class="text-right">Prix (Ar)</th></tr>
            </thead>
            <tbody>
            <% for (JouetLib j : jouets) { %>
                <tr>
                    <td>
                        <input type="checkbox" name="idjouet" class="case-jouet"
                               value="<%= CinemaUtil.html(j.getId()) %>" data-prix="<%= j.getPrix() %>"
                               <%= jouetsCoches.contains(j.getId()) ? "checked" : "" %>
                               onchange="majTotal()">
                    </td>
                    <td><%= CinemaUtil.html(j.getLib()) %></td>
                    <td><%= CinemaUtil.html(j.getTypejouet()) %></td>
                    <td class="text-right"><%= CinemaUtil.montant(j.getPrix()) %></td>
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
                <%-- formaction : ce bouton envoie le formulaire vers la page de paiement --%>
                <button type="submit" class="btn btn-primary pull-right"
                        formaction="<%= lien %>?but=popcorn/popcorn-paiement.jsp"
                        <%= jouets.length == 0 ? "disabled" : "" %>>
                    Continuer vers le paiement
                </button>
            </div>
        </div>
    </form>
</div>

<script>
    // Le SEUL script de la page : le total des jouets cochés (affichage seulement).
    function majTotal() {
        var total = 0;
        var cases = document.querySelectorAll('.case-jouet:checked');
        for (var i = 0; i < cases.length; i++) total += parseFloat(cases[i].getAttribute('data-prix'));
        document.getElementById('total').value = total.toLocaleString('fr-FR');
    }
    majTotal();   // au chargement : les jouets déjà cochés (après un rechargement)
</script>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
