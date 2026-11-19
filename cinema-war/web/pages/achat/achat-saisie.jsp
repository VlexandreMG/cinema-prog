<%--
    Achat d'un film : saisir le film, le distributeur et le montant, puis « Ajouter ».
    URL : module.jsp?but=achat/achat-saisie.jsp
    Doc : docs/conception/10_achat_film.md §13 ; squelette : docs/apprentissageAPJ/squelettes_pages_apj.md §2

    Affichage APJ (PageInsert sur Achat) + enregistrement par le service :
      - le formulaire mélange des champs de l'ACHAT (distributeur, montant) et du FILM (titre, durée, salle) ;
      - l'APJ n'enregistre que les attributs d'UNE classe : les champs du film sont donc ajoutés avec ajouterChamp,
        et le formulaire est envoyé à achat/apresAchat.jsp, qui appelle AchatService.acheterFilm
        (film + achat + sortie de caisse, en UNE transaction).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="affichage.PageInsert, affichage.Liste" %>
<%@ page import="achat.Achat, achat.Distributeur" %>
<%@ page import="salle.Salle" %>
<%@ page import="caisse.CaisseService" %>
<%@ page import="utils.CinemaUtil" %>
<%@ page import="user.UserEJB" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";
    UserEJB u = (UserEJB) session.getValue("u");

    // ── PRÉPARATION ──
    Achat a = new Achat();                                         // le modèle : les champs de l'ACHAT
    PageInsert p = new PageInsert(a, request, u);
    p.setLien(lien);

    // ── RÉGLAGES ──
    // Calculés par le service / createObject : cachés
    p.getFormu().getChamp("daty").setVisible(false);
    p.getFormu().getChamp("etat").setVisible(false);
    p.getFormu().getChamp("idfilm").setVisible(false);             // le film est CRÉÉ par l'achat

    // Les champs du FILM : pas dans Achat → ajoutés au formulaire (ignorés par l'APJ, lus par apresAchat.jsp)
    p.getFormu().ajouterChamp(new String[]{"titre", "duree", "idsalle"});

    Liste[] listes = new Liste[2];
    listes[0] = new Liste("iddistributeur", new Distributeur(), "nom", "id");
    listes[1] = new Liste("idsalle", new Salle(), "nom", "id");
    listes[0].ajouterVide();
    listes[1].ajouterVide();
    p.getFormu().changerEnChamp(listes);

    p.getFormu().getChamp("titre").setLibelle("Titre du film");
    p.getFormu().getChamp("duree").setLibelle("Dur&eacute;e (minutes)");
    p.getFormu().getChamp("idsalle").setLibelle("Salle");
    p.getFormu().getChamp("iddistributeur").setLibelle("Distributeur");
    p.getFormu().getChamp("montant").setLibelle("Montant (Ar)");
    p.getFormu().setOrdre(new String[]{"titre", "duree", "idsalle", "iddistributeur", "montant"});

    // ── PRÉPARER, PUIS FABRIQUER LE HTML ──
    p.preparerDataFormu();
    p.getFormu().makeHtmlInsertTabIndex();

    // Ce qu'on peut dépenser (information)
    double solde = CaisseService.solde(CaisseService.caissePrincipale(null).getId(), null);
%>
<div class="content-wrapper">
    <h1>Acheter un film</h1>
    <p class="text-muted">
        Le film est ajout&eacute; au catalogue et son prix sort de la caisse, en une seule op&eacute;ration.
        Solde de la caisse : <strong><%= CinemaUtil.montant(solde) %> Ar</strong>.
    </p>

    <%-- ── AFFICHAGE ── --%>
    <form action="<%= lien %>?but=achat/apresAchat.jsp" method="post">
        <%= p.getFormu().getHtmlInsert() %>
    </form>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
