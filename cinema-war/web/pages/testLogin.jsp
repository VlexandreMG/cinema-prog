
<%@page import="bean.TypeObjet"%>
<%@page import="mg.cnaps.configuration.Configuration"%>
<%@page import="user.*"%>
<%@ page import="utilitaire.*" %>
<%@ page import="bean.CGenUtil" %>
<%@ page import="java.net.InetAddress" %>
<%@ page import="java.io.FileReader" %>
<%
    UserEJB u = new UserEJBBean();
    String username = null;
    String pwd = null;
    String interim = null;
    String service = null;
    historique.MapUtilisateur ut = null;
    String lien;
    String queryString;
    String ip = null;
    String host = null;
    String mot_vide = "";
    String mot_avec_espace = "mot espace";
    String mot = "mot";
    String mot_null = null;
    Configuration[] configo = null;
    String escale=null;
    String idPoint = "";

%>

<%    try {
    
        username = request.getParameter("identifiant");
        pwd = request.getParameter("passe");
        escale = request.getParameter("escale");
        interim = request.getParameter("interim");
        service = request.getParameter("service");
        //u = UserEJBClient.lookupUserEJBBeanLocal();
        
        u.testLogin(username, pwd, interim, service);
        String langue = "fr";
        if (request.getParameter("langue") != null && !request.getParameter("langue").isEmpty()) langue = request.getParameter("langue");
        u.setLangue(langue);
        if (langue.equalsIgnoreCase("fr")==false){
            String filePath = request.getServletContext().getRealPath("/traduction.txt");
            u.setMapTraduction(MultiLangue.fileToHash(new FileReader(filePath)));
        }
        session.setAttribute("langue",langue);
        configo = u.findConfiguration();
        session.setMaxInactiveInterval(216000);
        session.setAttribute("u", u);
        session.setAttribute("config", configo);
        ut = u.getUser();
        // Cinema : pas de direction (table LOG_DIRECTION de l'ancienne application retiree)
        session.setAttribute("entmenu", "_all-skins");
        session.setAttribute("langue", "fr");
        lien = "module.jsp";
        if(session.getAttribute("pageName") != null){
            String pageName = session.getValue("pageName").toString();
            if(!pageName.equals("")){
               lien = pageName; 
            }
        }        
        queryString = "but="+u.findHomePageServices(u.getUser().getIdrole());
        String queryURL = request.getQueryString();
        if(queryURL != null && !queryURL.equals("")){

            queryString = queryURL;
        }
        session.setAttribute("dirlib","%");
        session.setAttribute("dir","%");
        session.setAttribute("lien", lien);
        String menu = "admin.jsp";
        session.setAttribute("menu", menu);

        out.println("<script language='JavaScript'> document.location.replace('" + lien + "?" + queryString + "');</script>");
        
    } catch (Exception e) {

        e.printStackTrace();
%>
<script language="JavaScript">
    alert('<%=e.getMessage() %>');
    history.back();
</script>
<%
        return;
    }
%>



<script language='JavaScript'> document.location.replace('<%=lien%>?"<%=queryString%>');</script>
