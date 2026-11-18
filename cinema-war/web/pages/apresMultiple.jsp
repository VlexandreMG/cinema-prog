<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="bean.ClassMAPTable" %>
<%@ page import="affichage.PageInsertMultiple" %>
<%@ page import="utilitaire.Utilitaire" %>
<%@ page import="user.UserEJB" %>
<%
try {
    UserEJB u   = (UserEJB) session.getAttribute("u");
    String lien = (String) session.getAttribute("lien");

    String acte   = request.getParameter("acte");
    String bute   = request.getParameter("bute");
    String classe = request.getParameter("classe");
    String id     = null;                                   // l'id vers lequel on redirige

    if ("insert".equalsIgnoreCase(acte)) {
        // ── CRÉER une mère + ses lignes cochées ──
        String classefille = request.getParameter("classefille");
        String nomtable    = request.getParameter("nomtable");
        String colonneMere = request.getParameter("colonneMere");
        int nbLigne        = Utilitaire.stringToInt(request.getParameter("nombreLigne"));
        String[] cochees   = request.getParameterValues("ids");

        ClassMAPTable mere  = (ClassMAPTable) Class.forName(classe).newInstance();
        ClassMAPTable fille = (ClassMAPTable) Class.forName(classefille).newInstance();
        PageInsertMultiple p = new PageInsertMultiple(mere, fille, request, nbLigne, cochees);
        ClassMAPTable   cmere  = p.getObjectAvecValeur();
        ClassMAPTable[] cfille = p.getObjectFilleAvecValeur();
        for (ClassMAPTable f : cfille) f.setNomTable(nomtable);

        ClassMAPTable o = (ClassMAPTable) u.createObjectMultiple(cmere, colonneMere, cfille);
        id = o.getTuppleID();

    } else if ("valider".equalsIgnoreCase(acte)) {
        // ── VISER un objet existant ──
        ClassMAPTable t = (ClassMAPTable) Class.forName(classe).newInstance();   // ① un objet vide...
        t.setValChamp(t.getAttributIDName(), request.getParameter("id"));        // ② ...avec juste son id
        u.validerObject(t);                                                       // ③ l'APJ recharge, vise, commit
        id = t.getTuppleID();

    } else {
        throw new Exception("Action non prise en charge : " + acte);
    }
%>
<script>document.location.replace("<%= lien %>?but=<%= bute %>&id=<%= id %>");</script>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
