<%--
    Page « après » de l'achat d'un film : pas d'affichage, elle enregistre puis redirige.
    Reçoit (POST, depuis achat-saisie.jsp) : titre, duree, idsalle, iddistributeur, montant.

    Pourquoi pas apresMultiple.jsp ? Le formulaire mélange le FILM et l'ACHAT : l'APJ ne saurait
    enregistrer qu'une seule classe. On appelle donc le service, qui fait film + achat + sortie
    de caisse dans UNE transaction (c = null : acheterFilm gère commit / rollback).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="achat.AchatService" %>
<%@ page import="user.UserEJB" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    UserEJB u = (UserEJB) session.getAttribute("u");
    if (u == null) throw new Exception("Session expirée : reconnectez-vous.");
    if (!"POST".equalsIgnoreCase(request.getMethod())) throw new Exception("Un achat s'enregistre par le formulaire.");

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

    AchatService.acheterFilm(titre, duree, idsalle, iddistributeur, montant, u.getUser().getTuppleID(), null);
%>
<script>document.location.replace("<%= lien %>?but=caisse/caisse-etat.jsp");</script>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
