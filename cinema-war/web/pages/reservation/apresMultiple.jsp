<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="bean.ClassMAPTable" %>
<%@ page import="affichage.PageInsertMultiple" %>
<%@ page import="utilitaire.Utilitaire" %>
<%@ page import="user.UserEJB" %>
<%
try {
    // ① L'utilisateur et le lien de base
    UserEJB u   = (UserEJB) session.getAttribute("u");
    String lien = (String) session.getAttribute("lien");

    // ② Les instructions envoyées par les champs cachés de la page de saisie
    String acte        = request.getParameter("acte");
    String bute        = request.getParameter("bute");
    String classe      = request.getParameter("classe");
    String classefille = request.getParameter("classefille");
    String nomtable    = request.getParameter("nomtable");
    String colonneMere = request.getParameter("colonneMere");
    int nbLigne        = Utilitaire.stringToInt(request.getParameter("nombreLigne"));
    String[] cochees   = request.getParameterValues("ids");

    if (!"insert".equalsIgnoreCase(acte)) {
        throw new Exception("Action non prise en charge : " + acte);
    }

    // ③ Créer des objets vides À PARTIR DE LEUR NOM (réflexion)
    ClassMAPTable mere  = (ClassMAPTable) Class.forName(classe).newInstance();
    ClassMAPTable fille = (ClassMAPTable) Class.forName(classefille).newInstance();

    // ④ Remplir la mère et les lignes cochées avec ce que le formulaire a envoyé
    PageInsertMultiple p = new PageInsertMultiple(mere, fille, request, nbLigne, cochees);
    ClassMAPTable   cmere  = p.getObjectAvecValeur();
    ClassMAPTable[] cfille = p.getObjectFilleAvecValeur();
    for (ClassMAPTable f : cfille) f.setNomTable(nomtable);

    // ⑤ Enregistrer : mère + lignes, dans UNE transaction (→ Reservation.createObject)
    ClassMAPTable o = (ClassMAPTable) u.createObjectMultiple(cmere, colonneMere, cfille);

    // ⑥ Aller à la fiche de ce qu'on vient de créer
%>
<script>document.location.replace("<%= lien %>?but=<%= bute %>&id=<%= o.getTuppleID() %>");</script>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
