<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="affichage.PageConsulte, affichage.PageRecherche" %>
<%@ page import="facture.Facture, facture.FactureDetail" %>
<%@ page import="user.UserEJB" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";
    UserEJB u = (UserEJB) session.getValue("u");

    // ── LA FACTURE : un seul objet → PageConsulte ──
    Facture f = new Facture();                                       // ① la TABLE : la facture est figée, pas besoin de vue
    PageConsulte pc = new PageConsulte(f, request, u);               //   lit &id=FAC… dans l'URL
    f = (Facture) pc.getBase();

    pc.getChampByName("id").setVisible(false);
    pc.getChampByName("idclient").setVisible(false);
    pc.getChampByName("numero").setLibelle("N&deg; de facture");
    pc.getChampByName("daty").setLibelle("Date");
    pc.getChampByName("client").setLibelle("Client");
    pc.getChampByName("objet").setLibelle("Objet");
    pc.getChampByName("montanttotal").setLibelle("Montant total (Ar)");
    pc.getChampByName("etat").setLibelle("&Eacute;tat");
    pc.getChampByName("idreservation").setLibelle("R&eacute;servation");
    pc.getChampByName("idreservation").setLien(lien + "?but=reservation/reservation-fiche.jsp", "id=");   // ②

    // ── SES LIGNES : plusieurs lignes → PageRecherche ──
    String[] col = {"designation", "prix"};
    PageRecherche pr = new PageRecherche(new FactureDetail(), request, new String[]{}, new String[]{}, 3, col, col.length);
    pr.setUtilisateur(u);
    pr.setLien(lien);
    pr.setAWhere(" and idfacture = '" + f.getId() + "'");              // ③
    pr.creerObjetPage(col, new String[]{"prix"});
    pr.getTableau().setLibelleAffiche(new String[]{"D&eacute;signation", "Prix (Ar)"});
%>
<div class="content-wrapper">
    <h1>Facture N&deg; <%= f.getNumero() %></h1>

    <%= pc.getHtml() %>

    <h3>D&eacute;tail</h3>
    <%= pr.getTableau().getHtml() %>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
