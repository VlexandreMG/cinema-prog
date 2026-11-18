<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%@ page import="affichage.PageInsertMultiple" %>
<%@ page import="affichage.Liste" %>
<%@ page import="client.Client" %>
<%@ page import="film.SeanceLib" %>
<%@ page import="reservation.Reservation, reservation.ReservationDetail" %>
<%@ page import="user.UserEJB" %>

<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // ── PRÉPARATION : ici, on lira les paramètres et on appellera le service ──
    UserEJB u = (UserEJB) session.getValue("u");

    Reservation r = new Reservation();
    ReservationDetail rd = new ReservationDetail();

    // Comment ça 5 lignes
    int nbLigne = 5;

    PageInsertMultiple p = new PageInsertMultiple(r,rd,request,nbLigne,u);
    // Pour que l'APJ créé ses propres liens
    p.setLien(lien);

    // ── RÉGLAGES DE L'EN-TÊTE ──
    p.getFormu().getChamp("daty").setVisible(false);
    p.getFormu().getChamp("montanttotal").setVisible(false);
    p.getFormu().getChamp("etat").setVisible(false);

    Liste[] listes = new Liste[2];
    listes[0] = new Liste("idclient", new Client(), "nom", "id");
    listes[1] = new Liste("idseance", new SeanceLib(), "libelle", "id", " and daty >= trunc(sysdate)");
    p.getFormu().changerEnChamp(listes);

    p.getFormu().getChamp("idclient").setLibelle("Client");
    p.getFormu().getChamp("idseance").setLibelle("S&eacute;ance");

    // Maka en base ny données ilainy 
    p.preparerDataFormu();
    // Ecris le html de l'input mais le garde dans p 
    p.getFormu().makeHtmlInsertTabIndex();
    p.getFormufle().makeHtmlInsertTableauIndex();


%>
<div class="content-wrapper">
    <h1>R&eacute;server des places</h1>

    <%-- ── AFFICHAGE : ici, on construira le formulaire ── --%>
    <%= p.getFormu().getHtmlInsert() %>

    <h3>Places</h3>
    <%= p.getFormufle().getHtmlTableauInsert() %>

</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
