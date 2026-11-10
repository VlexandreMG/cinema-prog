package user;

import bean.ClassMAPTable;
import bean.ResultatEtSomme;
import bean.TypeObjet;
import historique.MapUtilisateur;
import java.sql.Connection;
import java.util.HashMap;
import java.util.Map;
import mg.cnaps.configuration.Configuration;
import mg.cnaps.utilisateur.CNAPSUser;
import societe.Societe;
import utilisateur.ActionRole;

/**
 * Interface UserEJB ALLEGEE pour le cinema : seulement les methodes appelees
 * par apj-core / apj-core2 et par les pages gardees. Voir docs/etape1/.
 */
public interface UserEJB {
    public String getLangue() throws  Exception;
    public void setLangue(String langue) throws  Exception;
    public Map<String, String> getMapTraduction() throws  Exception;
    public void setMapTraduction(Map<String, String> mapTraduction) throws  Exception;
    public String getTraduction(String mot) throws  Exception;
    public ActionRole[] getActionRole();
    public void setActionRole(ActionRole[] actionRoles);
    public Object[] getData(ClassMAPTable e, String req, Connection c) throws Exception;
    public String getHome_page();
    public void ejbRemove();
    public Configuration[] getListeConfig() throws Exception;
    public String getHomePageUrl() throws Exception;


    public CNAPSUser getCnapsUser();

    public Configuration[] findConfiguration() throws Exception;
        
    public ResultatEtSomme getDataPageMax(ClassMAPTable e, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, Connection c) throws Exception;

    public ResultatEtSomme getDataPageMax(ClassMAPTable e, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, Connection c, int npp) throws Exception;

    public TypeObjet[] getListeSource() throws Exception;

    public ResultatEtSomme getDataPageMaxSansRecap(ClassMAPTable e, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, Connection c, int npp) throws Exception;

    public void updateEtat(ClassMAPTable e, int valeurEtat, String id) throws Exception;

    public MapUtilisateur getUser();

    public void testLogin(String user, String pass, String interim, String service) throws Exception;


    public String findHomePageServices(String codeService) throws Exception;

    public ResultatEtSomme getDataPage(ClassMAPTable e, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, Connection c) throws Exception;

    public ResultatEtSomme getDataPage(ClassMAPTable e, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, Connection c, int npp) throws Exception;

    public ResultatEtSomme getDataPageGroupe(ClassMAPTable e, String[] groupe, String[] sommeGroupe, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre, Connection c) throws Exception;

    public ResultatEtSomme getDataPageGroupe(ClassMAPTable e, String[] groupe, String[] sommeGroupe, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre, Connection c, int npp) throws Exception;

    public Object[] getData(ClassMAPTable e, String[] colInt, String[] valInt, Connection c, String apresWhere) throws Exception;

    public Object createObject(ClassMAPTable o) throws Exception;

    public Object createObject(ClassMAPTable[] o) throws Exception;

    public Object createObject(ClassMAPTable o, Connection c) throws Exception;

    public Object updateObject(ClassMAPTable o) throws Exception;

    public Object validerObject(ClassMAPTable o) throws Exception;

    public void deleteObject(ClassMAPTable o) throws Exception;

    public void setIdDirection(String idDirection);

    public String getIdDirection();//Upload generaliser

    public void deleteUploadedPj(String nomtable, String id) throws Exception;

    public Object updateObject(ClassMAPTable o, Connection c) throws Exception;

    public String getAddrIp();

    public void setAddrIp(String addrIp);

    public void deleteObject(ClassMAPTable o, Connection c) throws Exception;

    public ResultatEtSomme getDataPageGroupeMultiple(ClassMAPTable e, String[] groupe, String[] sommeGroupe, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre, Connection c) throws Exception;

    public ResultatEtSomme getDataPageGroupeMultiple(ClassMAPTable e, String[] groupe, String[] sommeGroupe, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre, Connection c, int npp) throws Exception;

    public ResultatEtSomme getDataPageGroupeMultiple(ClassMAPTable e, String[] groupe, String[] sommeGroupe, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre, Connection c, int npp, String count) throws Exception;

    public void updateEtat(ClassMAPTable e, int valeurEtat, String id, Connection c) throws Exception;


    public Object createObject(ClassMAPTable o, String action) throws Exception;
    
    public HashMap<String, String> getMapAutoComplete();
    public ClassMAPTable[] getDataPage(ClassMAPTable e, String requete, Connection c) throws Exception;

    public Societe getMaSociete() ;
}
