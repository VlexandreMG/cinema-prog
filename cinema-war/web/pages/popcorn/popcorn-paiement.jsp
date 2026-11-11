<%--
    Popcorn, étape 2 : vérifier le choix, puis payer.
    URL : module.jsp?but=popcorn/popcorn-paiement.jsp   (reçoit idclient, idpopcorn, idjouet[] en POST)
    Doc : docs/conception/06_popcorn_paiement_workflow.md

    Deux comportements dans la même page :
      - SANS acte      : le récapitulatif (client, paquet, jouets, total) + le formulaire « Payer » ;
      - avec acte=payer (POST) : vérifie le montant reçu, appelle ToyService.creerToy (INSERT en base),
                                 puis redirige vers la fiche de la vente.
    Pas de JavaScript : le navigateur vérifie le montant (required, min), le serveur revérifie,
    la monnaie à rendre est affichée sur la fiche.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="toy.ToyService, toy.Toy" %>
<%@ page import="client.Client" %>
<%@ page import="pop.Popcorn" %>
<%@ page import="jouet.JouetLib" %>
<%@ page import="utils.CinemaUtil" %>
<%@ page import="user.UserEJB" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // ── 1. LIRE le choix venu de popcorn-saisie.jsp ──
    String idclient  = request.getParameter("idclient");
    String idpopcorn = request.getParameter("idpopcorn");
    String[] idjouets = request.getParameterValues("idjouet");
    if (idclient == null || idclient.isEmpty())   throw new Exception("Choisissez un client.");
    if (idpopcorn == null || idpopcorn.isEmpty()) throw new Exception("Choisissez un paquet de popcorn.");
    if (idjouets == null || idjouets.length == 0) throw new Exception("Cochez au moins un jouet.");

    // ── 2. Le total vient TOUJOURS du serveur (prix des types en base), jamais du navigateur ──
    double total = ToyService.calculerMontant(idjouets, null);

    // ═══ PAYER : enregistrer la vente ═══
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

        // INSERT de la vente (TOY) puis de ses lignes (TOYDETAIL), en une transaction, avec toutes les règles
        Toy vente = ToyService.creerToy(idclient, idpopcorn, idjouets, u.getUser().getTuppleID(), null);
%>
<script>
    document.location.replace("<%= lien %>?but=popcorn/popcorn-fiche.jsp&id=<%= vente.getId() %>&recu=<%= recu %>");
</script>
<%
        return;
    }

    // ═══ RÉCAPITULATIF ═══
    Client  client  = (Client)  CinemaUtil.parId(new Client(),  idclient,  null);
    Popcorn popcorn = (Popcorn) CinemaUtil.parId(new Popcorn(), idpopcorn, null);
    JouetLib[] jouets = ToyService.chargerElements(idjouets, null);   // dans l'ordre du choix, avec type et prix

    // Lien « Modifier » : retour à la saisie avec le même choix (GET)
    StringBuilder retour = new StringBuilder(lien + "?but=popcorn/popcorn-saisie.jsp");
    retour.append("&idclient=").append(java.net.URLEncoder.encode(idclient, "UTF-8"));
    retour.append("&idpopcorn=").append(java.net.URLEncoder.encode(idpopcorn, "UTF-8"));
    for (String j : idjouets) retour.append("&idjouet=").append(java.net.URLEncoder.encode(j, "UTF-8"));
%>
<div class="content-wrapper">
    <h1>V&eacute;rifier et payer</h1>

    <div class="container">
        <table class="table table-condensed" style="max-width: 600px;">
            <tr><th>Client</th><td><%= CinemaUtil.html(client.getNom()) %></td></tr>
            <tr><th>Paquet de popcorn</th><td><%= CinemaUtil.html(popcorn.getNom()) %></td></tr>
        </table>

        <h3>Jouets (<%= jouets.length %>)</h3>
        <table class="table table-bordered" style="max-width: 600px;">
            <thead><tr><th>Jouet</th><th>Type</th><th class="text-right">Prix (Ar)</th></tr></thead>
            <tbody>
            <% for (JouetLib j : jouets) { %>
                <tr>
                    <td><%= CinemaUtil.html(j.getLib()) %></td>
                    <td><%= CinemaUtil.html(j.getTypejouet()) %></td>
                    <td class="text-right"><%= CinemaUtil.montant(j.getPrix()) %></td>
                </tr>
            <% } %>
            </tbody>
            <tfoot>
                <tr><th colspan="2">Total</th><th class="text-right"><%= CinemaUtil.montant(total) %></th></tr>
            </tfoot>
        </table>

        <h3>Paiement</h3>
        <%-- POST vers CETTE page avec acte=payer : c'est ce qui déclenche l'enregistrement --%>
        <form method="post" action="<%= lien %>?but=popcorn/popcorn-paiement.jsp" style="max-width: 600px;">
            <input type="hidden" name="acte"      value="payer">
            <input type="hidden" name="idclient"  value="<%= CinemaUtil.html(idclient) %>">
            <input type="hidden" name="idpopcorn" value="<%= CinemaUtil.html(idpopcorn) %>">
            <% for (String j : idjouets) { %>
            <input type="hidden" name="idjouet" value="<%= CinemaUtil.html(j) %>">
            <% } %>

            <div class="form-group">
                <label>Montant &agrave; payer (Ar)</label>
                <input type="text" class="form-control" readonly value="<%= CinemaUtil.montant(total) %>">
            </div>
            <div class="form-group">
                <label for="montantrecu">Montant re&ccedil;u (Ar)</label>
                <input type="number" name="montantrecu" id="montantrecu" class="form-control"
                       min="<%= (long) total %>" step="any" value="<%= (long) total %>" required>
            </div>

            <a class="btn btn-default" href="<%= retour %>">Modifier</a>
            <button type="submit" class="btn btn-success pull-right">Payer</button>
        </form>
    </div>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
