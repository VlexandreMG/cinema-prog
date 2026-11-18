<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="affichage.PageConsulte" %>
<%@ page import="reservation.ReservationLib" %>
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

    // ── RÉGLAGES (à venir) ──

%>
<div class="content-wrapper">
    <h1>R&eacute;servation <%= r.getId() %></h1>

    <%-- ── AFFICHAGE ── --%>
    <%= pc.getHtml() %>                                            <%-- ④ --%>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
