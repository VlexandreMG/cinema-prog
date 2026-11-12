<%--
    Achat d'un film : saisir le film, le distributeur et le montant, puis « Acheter ».
    URL : module.jsp?but=achat/achat-saisie.jsp
    Doc : docs/conception/10_achat_film.md §13

    Deux comportements dans la même page :
      - SANS acte         : le formulaire + le solde de la caisse (ce qu'on peut dépenser) ;
      - acte=acheter (POST) : AchatService.acheterFilm (film + achat + sortie de caisse, une transaction),
                              puis redirection vers l'état de la caisse.
    Pas de JavaScript : le navigateur vérifie les champs (required, min), le serveur revérifie
    (Film.createObject, Achat.createObject, MouvementCaisse.createObject).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="achat.AchatService, achat.Distributeur, achat.Achat" %>
<%@ page import="caisse.CaisseService" %>
<%@ page import="salle.Salle" %>
<%@ page import="utils.CinemaUtil" %>
<%@ page import="user.UserEJB" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // ═══ ACHETER : enregistrer l'achat ═══
    if ("acheter".equals(request.getParameter("acte")) && "POST".equalsIgnoreCase(request.getMethod())) {
        UserEJB u = (UserEJB) session.getAttribute("u");
        if (u == null) throw new Exception("Session expirée : reconnectez-vous.");

        String titre          = request.getParameter("titre");
        String idsalle        = request.getParameter("idsalle");
        String iddistributeur = request.getParameter("iddistributeur");
        int duree;
        double montant;
        try {
            duree   = Integer.parseInt(request.getParameter("duree").trim());
            montant = Double.parseDouble(request.getParameter("montant").trim().replace(" ", "").replace(",", "."));
        } catch (Exception ex) {
            throw new Exception("Durée ou montant invalide.");
        }

        // Film + achat + sortie de caisse, en UNE transaction (c = null : acheterFilm gère commit / rollback)
        Achat achat = AchatService.acheterFilm(titre, duree, idsalle, iddistributeur, montant,
                u.getUser().getTuppleID(), null);
%>
<script>
    document.location.replace("<%= lien %>?but=caisse/caisse-etat.jsp");
</script>
<%
        return;
    }

    // ═══ FORMULAIRE ═══
    Salle[] salles = AchatService.listerSalles(null);
    Distributeur[] distributeurs = AchatService.listerDistributeurs(null);
    double solde = CaisseService.solde(CaisseService.caissePrincipale(null).getId(), null);
%>
<div class="content-wrapper">
    <h1>Acheter un film</h1>
    <p class="text-muted">Le film est ajout&eacute; au catalogue et son prix sort de la caisse, en une seule op&eacute;ration.</p>

    <div class="container">
        <form method="post" action="<%= lien %>?but=achat/achat-saisie.jsp" style="max-width: 600px;">
            <input type="hidden" name="acte" value="acheter">

            <div class="form-group">
                <label>Solde de la caisse (Ar)</label>
                <input type="text" class="form-control" readonly value="<%= CinemaUtil.montant(solde) %>">
            </div>

            <h3>Le film</h3>
            <div class="form-group">
                <label for="titre">Titre</label>
                <input type="text" name="titre" id="titre" class="form-control" maxlength="200" required>
            </div>
            <div class="form-group">
                <label for="duree">Dur&eacute;e (minutes)</label>
                <input type="number" name="duree" id="duree" class="form-control" min="1" step="1" required>
            </div>
            <div class="form-group">
                <label for="idsalle">Salle</label>
                <select name="idsalle" id="idsalle" class="form-control" required>
                    <option value="">-- Choisir --</option>
                    <% for (Salle s : salles) { %>
                    <option value="<%= CinemaUtil.html(s.getId()) %>"><%= CinemaUtil.html(s.getNom()) %></option>
                    <% } %>
                </select>
            </div>

            <h3>L'achat</h3>
            <div class="form-group">
                <label for="iddistributeur">Distributeur</label>
                <select name="iddistributeur" id="iddistributeur" class="form-control" required>
                    <option value="">-- Choisir --</option>
                    <% for (Distributeur d : distributeurs) { %>
                    <option value="<%= CinemaUtil.html(d.getId()) %>"><%= CinemaUtil.html(d.getNom()) %></option>
                    <% } %>
                </select>
            </div>
            <div class="form-group">
                <label for="montant">Montant (Ar)</label>
                <input type="number" name="montant" id="montant" class="form-control" min="1" step="any" required>
            </div>

            <button type="submit" class="btn btn-success pull-right">Acheter</button>
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
