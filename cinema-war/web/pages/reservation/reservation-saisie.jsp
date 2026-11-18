<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>1c

<%@ page import="affichage.PageInsertMultiple" %>
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

    int nbLigne = 5;

    PageInsertMultiple p = new PageInsertMultiple(r,rd,request,nbLigne,u);
    

%>
<div class="content-wrapper">
    <h1>R&eacute;server des places</h1>

    <%-- ── AFFICHAGE : ici, on construira le formulaire ── --%>

</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
