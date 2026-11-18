<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="affichage.PageConsulte, affichage.PageRecherche" %>
<%@ page import="reservation.ReservationLib, reservation.ReservationDetailLib" %>
<%@ page import="user.UserEJB" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // ── PRÉPARATION ──
    UserEJB u = (UserEJB) session.getValue("u");

    ReservationLib r = new ReservationLib();                      // ①
    PageConsulte pc = new PageConsulte(r, request, u);            // ②
    r = (ReservationLib) pc.getBase();                            // ③

    // ── LES PLACES DE LA RÉSERVATION ──
    String[] colonnes = {"numero", "typeplace", "prix"};                                     // ①
    PageRecherche pr = new PageRecherche(new ReservationDetailLib(), request,
                                         new String[]{}, new String[]{}, 3,
                                         colonnes, colonnes.length);                         // ②
    pr.setUtilisateur(u);                                                                    // ③
    pr.setLien(lien);
    pr.setAWhere(" and idreservation = '" + r.getId() + "'");                                // ④
    pr.creerObjetPage(colonnes, new String[]{"prix"});                                       // ⑤
    pr.getTableau().setLibelleAffiche(new String[]{"Place", "Type", "Prix (Ar)"});           // ⑥


    // ── RÉGLAGES ──
    pc.getChampByName("idclient").setVisible(false);
    pc.getChampByName("idseance").setVisible(false);
    pc.getChampByName("idfilm").setVisible(false);

    pc.getChampByName("id").setLibelle("R&eacute;f&eacute;rence");
    pc.getChampByName("client").setLibelle("Client");
    pc.getChampByName("film").setLibelle("Film");
    pc.getChampByName("salle").setLibelle("Salle");
    pc.getChampByName("dateseance").setLibelle("Date de la s&eacute;ance");
    pc.getChampByName("heure").setLibelle("Heure");
    pc.getChampByName("daty").setLibelle("R&eacute;serv&eacute;e le");
    pc.getChampByName("montanttotal").setLibelle("Montant (Ar)");
    pc.getChampByName("etat").setLibelle("&Eacute;tat");

%>
<div class="content-wrapper">
    <h1>R&eacute;servation <%= r.getId() %></h1>

    <%-- ── AFFICHAGE ── --%>
    <%= pc.getHtml() %>                                            <%-- ④ --%>
    <% if (r.getEtat() < 11) { %>
        <a class="btn btn-primary"
           href="<%= lien %>?but=apresMultiple.jsp&acte=valider&id=<%= r.getId() %>&classe=reservation.Reservation&bute=reservation/reservation-fiche.jsp">
            Viser (encaisser)
        </a>
    <% } %>

    <h3>Places</h3>
    <%= pr.getTableau().getHtml() %>

</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
