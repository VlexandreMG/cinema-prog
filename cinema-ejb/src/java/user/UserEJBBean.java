package user;

import java.sql.Connection;
import java.util.HashMap;
import java.util.Map;
import bean.*;
import societe.Societe;
import utilisateur.*;
import utilitaire.UtilDB;
import historique.MapUtilisateur;
import historique.MapHistorique;
import historique.MapUtilisateurServiceDirection;
import historique.UtilisateurUtil;
import mg.cnaps.configuration.Configuration;
import mg.cnaps.notification.NotificationService;
import mg.cnaps.notification.NotificationLibelle;
import mg.cnaps.utilisateur.CNAPSUser;
import utilitaire.Utilitaire;
import constante.ConstanteEtat;
import bean.CGenUtil;

/**
 * UserEJBBean ALLEGE pour le cinema (genere depuis celui d'arbiochem).
 * On ne garde que les methodes utilisees par apj-core / apj-core2 et par les pages
 * de connexion, module.jsp, en-tete et menu. Voir docs/etape1/.
 */
public class UserEJBBean implements UserEJB {

    TypeObjet[] listeSource = null;
    MapUtilisateurServiceDirection u;
    MapUtilisateur uVue;
    Configuration[] listeConfig;
    String type;
    CNAPSUser cnapsUser;
    String home_page = "accueil.jsp";
    String idDirection;
    private String addrIp;
    private HashMap<String, String> mapAutoComplete = new HashMap<>();
    String homePageUrl;
    ActionRole[] actionRole;
    Societe maSociete;

    String langue;
    Map<String,String> mapTraduction;


    public Societe getMaSociete() {
        return maSociete;
    }

    public void setMaSociete(Societe maSociete) {
        this.maSociete = maSociete;
    }

    public ActionRole[] getActionRole() {
        return actionRole;
    }


    public void setActionRole(ActionRole[] actionRole) {
        this.actionRole = actionRole;
    }


    public String getLangue() throws  Exception{
        return langue;
    }

    public void setLangue(String langue) throws  Exception{
        this.langue = langue;
    }

    public Map<String, String> getMapTraduction()throws  Exception {
        return mapTraduction;
    }

    public void setMapTraduction(Map<String, String> mapTraduction)throws  Exception {
        this.mapTraduction = mapTraduction;
    }
    public String getTraduction(String mot)throws  Exception{
        String result = mot;
        if (this.getLangue()!=null&& this.getLangue().equalsIgnoreCase("fr")==false){
            String valeur = this.getMapTraduction().get(mot);
            if (valeur!=null){
                result = valeur;
            }
        }
        return result;
    }

    public String getHomePageUrl() throws Exception {
        return homePageUrl;
    }

    public void setHomePageUrl(String homePageUrl)throws Exception {
        this.homePageUrl = homePageUrl;
    }

    public MapUtilisateur getuVue() {
        return uVue;
    }

    public void setuVue(MapUtilisateur uVue) {
        this.uVue = uVue;
    }

    public Configuration[] getListeConfig() throws Exception {
        return listeConfig;
    }

    public void setListeConfig(Configuration[] listeConfig) {
        this.listeConfig = listeConfig;
    }

    @Override
    public CNAPSUser getCnapsUser() {
        return cnapsUser;
    }

    public String getHome_page() {
        return home_page;
    }

    public TypeObjet[] getListeSource() {
        return listeSource;
    }

    public void setListeSource(TypeObjet[] listeSource) {
        this.listeSource = listeSource;
    }

    /**
     * Tester si le nom d'utilisateur et le mot de passe correspondant à un
     * utilisateur
     *
     * @param user nom d'utilisateur
     * @param pass mot de passe non crypté de l'utilisateur
     * @param interim autorisé interim ou pas
     * @param service service où on essaie de se connecter
     * @return utilisateur correspondant au nom d'utilisateur et mot de passe
     * @throws Exception
     */
    public MapUtilisateurServiceDirection testeValide(String user, String pass, String interim, String service,Connection c) throws Exception {
        try {
            historique.UtilisateurUtil uI = new UtilisateurUtil(c);
            return (MapUtilisateurServiceDirection) uI.testeValide(user, pass,c);
        } catch (Exception ex) {
            ex.printStackTrace();
            throw new Exception(ex.getMessage());
        }
    }

    /**
     * Cette fonction sert à réaliser une recherche paginée avec nombre
     * d'élèments de la page fixé au nombre configuré si nombre d'élèments
     * donnés invalides
     *
     * @param e objet de mapping
     * @param colInt liste des intervalles des intervalles
     * @param valInt liste des valeurs des colonnes d'intervalle
     * @param numPage numéro de page actuel
     * @param apresWhere partie de requête après where
     * @param nomColSomme liste des colonnes de somme
     * @param c connexion ouverte à la base de données Le nombre d'élèment dans
     * une page n'est pas preciser
     */
    @Override
    public ResultatEtSomme getDataPageMax(ClassMAPTable e, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, Connection c) throws Exception {
        return getDataPageMax(e, colInt, valInt, numPage, apresWhere, nomColSomme, c, 0);
    }

    /**
     * Cette fonction sert à rechercher une paginée avec nombre d'élèments de la
     * page fixé au nombre configuré si nombre d'élèments donnés invalides
     *
     * @param e objet de mapping
     * @param colInt liste des intervalles des intervalles
     * @param valInt liste des valeurs des colonnes d'intervalle
     * @param numPage numéro de page actuel
     * @param apresWhere partie de requête après where
     * @param nomColSomme liste des colonnes de somme
     * @param c connexion ouverte à la base de données
     * @param npp : nombre d'élèment dans une page
     */
    @Override
    public ResultatEtSomme getDataPageMax(ClassMAPTable e, String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, Connection c, int npp) throws Exception {
        e.setMode("select");
        if (ListeColonneTable.getChamp(e, "iduser", c) != null) {
            ClassUser temp = (ClassUser) e;
            //apresWhere = testRangUser(e, c) + apresWhere;
        }
        if (e.getNomTableSelect().compareToIgnoreCase("SIG_TRAVAILLEUR_INFO_COMPLET") == 0) {
            return CGenUtil.rechercherPageMaxSansRecap(e, colInt, valInt, numPage, apresWhere, nomColSomme, c, npp);
        }
        return CGenUtil.rechercherPageMax(e, colInt, valInt, numPage, apresWhere, nomColSomme, c, npp);
    }

    /**
     * Recherche paginée avec nombre d'élèments de la page fixé au nombre
     * configuré si nombre d'élèments donnés invalides, puis les colonnes de
     * sommes ignorées
     *
     * @param e objet de mapping
     * @param colInt liste de colonnes d'intervalles
     * @param valInt liste des valeurs des colonnes d'intervalle
     * @param numPage numéro de page actuel
     * @param apresWhere partie de requête après where
     * @param nomColSomme liste des colonnes de somme
     * @param c connexion ouverte à la base de données
     * @param nbPage nombre d'élèment dans une page
     * @return instance avec les résultas de la recherches
     * @throws Exception
     */
    @Override
    public ResultatEtSomme getDataPageMaxSansRecap(ClassMAPTable e, String[] colInt, String[] valInt, int numPage,
            String apresWhere, String[] nomColSomme, Connection c, int npp) throws Exception {
        e.setMode("select");
        if (ListeColonneTable.getChamp(e, "iduser", c) != null) {
            ClassUser temp = (ClassUser) e;
            //apresWhere = testRangUser(e, c) + apresWhere;
        }

        return CGenUtil.rechercherPageMaxSansRecap(e, colInt, valInt, numPage, apresWhere, nomColSomme, c, npp);
    }

    /**
     * ¨
     *
     * @deprecated ne fait rien
     */
    @Override
    public void updateEtat(ClassMAPTable e, int valeurEtat, String id) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            //updateEtat(e, valeurEtat, id, c);
            c.commit();
        } catch (Exception ex) {
            throw ex;
        } finally {
            if (c != null) {
                c.close();
            }
        }
    }

    /**
     * Obtenir l'utilisateur courant
     *
     * @return l'utilisateur courant
     */
    @Override
    public MapUtilisateur getUser() {
        return u;
    }

    public Object validerObject(ClassMAPTable o, Connection c) throws Exception {
        boolean estAutorise=ActionRole.estAutorise(this.getActionRole(),this.getuVue(),"validate",o);
        if(estAutorise==false)throw new Exception("Action de validation non autorise de "+this.getuVue().getLoginuser()+" sur l objet "+o.getNomTable());
        try {
            o.setUserEJBBean(this);
            return ValiderObject.validerObject(c, o, this, u, listeConfig);
        } catch (Exception ex) {
            c.rollback();
            ex.printStackTrace();
            throw ex;
        }
    }

    @Override
    public Configuration[] findConfiguration() throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            Configuration[] liste = (Configuration[]) CGenUtil.rechercher(new Configuration(), null, null, c, " order by typeconfig desc");
            return liste;
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        } finally {
            if (c != null) {
                c.close();
            }
        }
    }


    /**
     * Cette fonction sert à chercher l'url de la page d'accueil d'une personne
     * dependant de son service
     *
     * @param codeService service rattaché au role de l'utilisateur
     */
    @Override
    public String findHomePageServices(String codeService) throws Exception {
        Connection connection = null;
        try {
            connection = (new UtilDB()).GetConn();
            return findHomePageServices(codeService, connection);
        } catch (Exception ex) {
            ex.printStackTrace();
            throw new Exception(ex.getMessage());
        } finally {
            if (connection != null) {
                connection.close();
            }
        }
    }
    public String findHomePageServices(String codeService,Connection connection) throws Exception {
        try {
            HomePageURL[] hommePageList = (HomePageURL[]) CGenUtil.rechercher(new HomePageURL(), null, null, connection, " and idrole = '" + codeService + "'");
            if (hommePageList != null && hommePageList.length > 0) {
                this.home_page = hommePageList[0].getUrlpage();
            }
            return this.home_page;
        } catch (Exception ex) {
            ex.printStackTrace();
            throw new Exception(ex.getMessage());
        }
    }

    /**
     * Réaliser une recherche paginée(recapitulation y compris) avec le nombre
     * d'élèment par page fixé au nombre donné dans le paramètre global
     *
     * @param e : objet de mapping
     * @param colInt liste de colonnes d'intervalles
     * @param valInt liste des valeurs des colonnes d'intervalle
     * @param numPage numéro de page à prendre
     * @param apresWhere filtre SQL après where
     * @param nomColSomme noms des colonnes à sommer
     * @param c : connexion ouverte à la base de données
     */
    @Override
    public ResultatEtSomme getDataPage(ClassMAPTable e, String[] colInt, String[] valInt, int numPage,
            String apresWhere, String[] nomColSomme, Connection c) throws Exception {
        return getDataPage(e, colInt, valInt, numPage, apresWhere, nomColSomme, c, 0);
    }

    public String testRangUser(ClassMAPTable e, Connection c) throws Exception {
        String retour = "";
        if (e instanceof bean.ClassEtat || e instanceof bean.ClassUser) {
            if (e instanceof mg.cnaps.notification.NotificationLibelle) {
                return NotificationService.conditionLectureNotification(u);
            } else {
                UtilisateurRole[] utilEnCours = (UtilisateurRole[]) CGenUtil.rechercher(new UtilisateurRole(), null, null, c, " and refuser=" + u.getTuppleID());
                if (utilEnCours.length > 0) {
                    if (utilEnCours[0].getRang() < Constante.getRangMahitaNyHafa()) {
                        retour += " and iduser='" + utilEnCours[0].getRefuser() + "' ";
                    }
                }
            }
        }
        return retour;
    }

    /**
     * Sert à avoir les sommes de colonnes en tant que récapitulation
     *
     * @param e objet de mapping
     * @param colInt liste de colonnes d'intervalles
     * @param valInt liste des valeurs des colonnes d'intervalle
     * @param numPage numéro de page à prendre
     * @param apresWhere filtre SQL après where
     * @param nomColSomme noms des colonnes à sommer
     * @param c connexion ouverte à la base de données
     * @param npp nombre d'élèments dans une pages
     */
    @Override
    public ResultatEtSomme getDataPage(ClassMAPTable e, String[] colInt, String[] valInt, int numPage,
            String apresWhere, String[] nomColSomme, Connection c, int npp) throws Exception {
        e.setMode("select");
        e.setUserEJBBean(this);
        if (ListeColonneTable.getChamp(e, "iduser", c) != null) {
            apresWhere = testRangUser(e, c) + apresWhere;
        }
        return e.rechercherPage(colInt, valInt, numPage, apresWhere, nomColSomme, c, npp);
    }

    /**
     * Cette fonction fait la recherche groupée paginée avec récapitulation avec
     * nombre d'élèment dans une page fixé au valeur de configuration
     *
     * @param e objet de mapping
     * @param colInt liste de colonnes d'intervalles
     * @param valInt liste des valeurs des colonnes d'intervalle
     * @param numPage numéro de page à prendre
     * @param apresWhere filtre SQL après where
     * @param nomColSomme noms des colonnes à sommer
     * @param c connexion ouverte à la base de données
     * @param ordre requête d'ordre
     */
    @Override
    public ResultatEtSomme getDataPageGroupe(ClassMAPTable e, String[] groupe, String[] sommeGroupe, String[] colInt,
            String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre, Connection c)
            throws Exception {
        e.setMode("select");
        if (ListeColonneTable.getChamp(e, "iduser", c) != null) {
            apresWhere = testRangUser(e, c) + apresWhere;
        }
        return CGenUtil.rechercherPageGroupe(e, groupe, sommeGroupe, colInt, valInt, numPage, apresWhere, nomColSomme, ordre, c);
    }

    /**
     * Cette fonction fait la recherche groupée paginée avec récapitulation
     *
     * @param e objet de mapping
     * @param colInt liste de colonnes d'intervalles
     * @param valInt liste des valeurs des colonnes d'intervalle
     * @param numPage numéro de page à prendre
     * @param apresWhere filtre SQL après where
     * @param nomColSomme noms des colonnes à sommer
     * @param c connexion ouverte à la base de données
     * @param ordre requête d'ordre
     * @param npp nombre d'élèments dans une pages
     */
    @Override
    public ResultatEtSomme getDataPageGroupe(ClassMAPTable e, String[] groupe, String[] sommeGroupe, String[] colInt,
            String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre, Connection c, int npp)
            throws Exception {
        e.setMode("select");
        if (ListeColonneTable.getChamp(e, "iduser", c) != null) {
            apresWhere = testRangUser(e, c) + apresWhere;
        }
        return CGenUtil.rechercherPageGroupe(e, groupe, sommeGroupe, colInt, valInt, numPage, apresWhere, nomColSomme, ordre, c, npp);
    }
    @Override
    public Object[] getData(ClassMAPTable e, String req, Connection c) throws Exception {
        e.setMode("select");
        return CGenUtil.rechercher(e,req,c);
    }

    /**
     * Créer un objet avec trace de la personne modifiant
     *
     * @param o objet à créer
     * @return objet après la création
     */

    /**
     * Permet obtenir le resultat de la recherche de objet de mapping filtré
     *
     * @param e objet de mapping
     * @param colInt colonnes avec intervalles
     * @param valInt valeurs des colonnes d'intervalles
     * @param c: connection
     * @param apresWhere where statement personalisé
     */
    @Override
    public Object[] getData(ClassMAPTable e, String[] colInt, String[] valInt, Connection c, String apresWhere)
            throws Exception {
        e.setMode("select");
        if (ListeColonneTable.getChamp(e, "iduser", c) != null) {
            apresWhere = testRangUser(e, c) + apresWhere;
        }
        if (c == null) {
            return CGenUtil.rechercher(e, colInt, valInt, apresWhere);
        }
        return CGenUtil.rechercher(e, colInt, valInt, c, apresWhere);
    }

    /**
     * Créer un objet avec trace de la personne modifiant
     *
     * @param o objet à créer
     * @return objet après la création
     */
    @Override
    public Object createObject(ClassMAPTable o) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            Object ob = createObject(o, c);
            c.commit();
            return ob;
        } catch (Exception ex) {
            ex.printStackTrace();
            c.rollback();
            throw ex;
        } finally {
            if (c != null) {
                c.close();
            }
        }

    }

    @Override
    public Object createObject(ClassMAPTable[] o) throws Exception {
        return null;
    }

    /**
     * Créer un objet avec trace de la personne modifiant
     *
     * @param o objet à créer
     * @param c connexion ouverte à la base de données
     * @return objet après la création
     */
    @Override
    public Object createObject(ClassMAPTable o, Connection c) throws Exception {
        boolean estAutorise=ActionRole.estAutorise(this.getActionRole(),this.getuVue(),"insert",o);
        if(estAutorise==false)throw new Exception("Action de creation non autorise de "+this.getuVue().getLoginuser()+" sur l objet "+o.getNomTable());
        if (u.getRang() < 1) {
            throw new Exception("ERREUR DE DROIT");
        }
        try {
            o.setUserEJBBean(this);
            if (o.getMode() != null && o.getMode().compareToIgnoreCase("annul") == 0) {
                o.setMode("annul");
                CreateObject.createObject(o, c, u, this, listeConfig, getListeSource());
                return ValiderObject.validerObject(c, o, this, uVue, listeConfig);
            } else {
                o.setMode("modif");
                return CreateObject.createObject(o, c, u, this, listeConfig, getListeSource());
            }
        } catch (Exception ex) {
            //c.rollback();
            ex.printStackTrace();
            throw ex;
        }
    }

    /**
     * Modifier un objet avec trace de la personne modifiant avec initialisation
     * interne de la base de données
     *
     * @param o objet à créer
     * @return objet après la modification
     */
    @Override
    public Object updateObject(ClassMAPTable o) throws Exception {
        Connection c = null;

        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            updateObject(o, c);
            c.commit();
            return o;
        } catch (Exception ex) {
            c.rollback();
            ex.printStackTrace();
            throw ex;
        } finally {
            if (c != null) {
                c.close();
            }
        }
    }

    /**
     * Sert à valider(viser) un objet
     *
     * @param o C'est l'objet à valider
     * @return l'objet apres la mis à jour
     */
    @Override
    public Object validerObject(ClassMAPTable o) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            Object ob = validerObject(o, c);
            c.commit();
            return ob;
        } catch (Exception ex) {
            ex.printStackTrace();
            c.rollback();
            throw ex;
        } finally {
            if (c != null) {
                c.close();
            }
        }
    }

    /**
     * Supprimer un objet de mapping avec initialisation interne de la connexion
     * à la base de données
     *
     * @param o objet à supprimer
     *
     */
    @Override
    public void deleteObject(ClassMAPTable o) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            deleteObject(o, c);
            c.commit();
        } catch (Exception e) {
            throw e;
        } finally {
            if (c != null) {
                c.close();
            }
        }
    }

    /**
     * @param idDirection id de la direction associée à la session
     */
    @Override
    public void setIdDirection(String idDirection) {
        this.idDirection = idDirection;
    }

    /**
     * @return id de la direction associée à la session
     */
    @Override
    public String getIdDirection() {
        return idDirection;
    }

    /**
     * Supprimer un upload
     *
     * @param nomTable nom de la table
     * @param id id de la pièce jointe
     */
    @Override
    public void deleteUploadedPj(String nomtable, String id) throws Exception {
        Connection con = null;
        try {
            con = new UtilDB().GetConn();
            con.setAutoCommit(false);
            UploadPj up = new UploadPj(nomtable);
            UploadPj[] fichiers = (UploadPj[]) CGenUtil.rechercher(up, null, null, con, " AND ID = '" + id + "'");
            //  Utilitaire.deleteFileFromCdn(fichiers[0].getChemin());
            MapHistorique h = new MapHistorique(nomtable, "delete", u.getTuppleID(), id);
            h.setObjet("bean.UploadPj");
            fichiers[0].deleteToTable(con);
            con.commit();
        } catch (Exception ex) {
            ex.printStackTrace();
            con.rollback();
            throw ex;
        } finally {
            if (con != null) {
                con.close();
            }
        }
    }

    /**
     * Modifier un objet avec trace de la personne modifiant avec initialisation
     * interne de la base de données
     *
     * @param o objet à créer
     * @return objet après la modification
     */
    @Override
    public Object updateObject(ClassMAPTable o, Connection c) throws Exception {
        try {
            boolean estAutorise=ActionRole.estAutorise(this.getActionRole(),this.getuVue(),"update",o);
            if(estAutorise==false)throw new Exception("Action de mise e jour non autorise de "+this.getuVue().getLoginuser()+" sur l objet "+o.getNomTable());
            return UpdateObject.updateObject(o, c, u, this);
        } catch (Exception ex) {
            c.rollback();
            ex.printStackTrace();
            throw ex;
        }
    }

    @Override
    public String getAddrIp() {
        return addrIp;
    }

    @Override
    public void setAddrIp(String addrIp) {
        this.addrIp = addrIp;
    }

    public void testDelete(ClassMAPTable o, Connection c) throws Exception {
        try {
            if (o.getClass().getSuperclass().getSimpleName().compareToIgnoreCase("ClassEtat") == 0) {
                String id = o.getValInsert("id");
                ClassMAPTable[] liste = (ClassMAPTable[]) CGenUtil.rechercher(o, null, null, c, "");
                if (liste.length == 0) {
                    throw new Exception("Objet inexistant");
                }
                if (Utilitaire.stringToInt(liste[0].getValInsert("etat")) >= ConstanteEtat.getEtatValider()) {
                    throw new Exception("IMPOSSIBLE DE SUPPRIMER. OBJET DEJA VISER");
                }

            }
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
    }

    /**
     * Cette fonction supprime l'objet qui est trouvé selon le paramètre o
     *
     * @param o classe mapping
     * @param c connexion ouverte à la base de données
     */
    @Override
    public void deleteObject(ClassMAPTable o, Connection c) throws Exception {
        try {
            /*
             * if (u.isSuperUser() == false) { throw new Exception("Pas de
             * droit"); }
             */
            //System.out.println("objet supprimer: " + o.getTuppleID());
            testDelete(o, c);
            ClassMAPTable[] liste = (ClassMAPTable[]) CGenUtil.rechercher(o, null, null, c, "");
            if (liste.length > 0) {
                liste[0].deleteToTableWithHisto(u.getTuppleID(), c);

            } else {
                throw new Exception("Erreur durant la suppression, Objet introuvable");
            }
        } catch (Exception ex) {
            if (c != null) {
                c.rollback();
            }
            ex.printStackTrace();
            throw ex;
        }
    }

    /**
     * recherche groupée paginée avec une ligne par page avec récapitulation
     *
     * @param e objet de mapping
     * @param groupe liste de colonnes de groupages sans somme
     * @param sommeGroupe liste de colonnes avec sommes
     * @param colInt colonnes d'intervalle de filtre
     * @param valInt liste des valeurs de colonnes d'intervalle de filtre
     * @param numPage numéro de page actuel
     * @param apresWhere requête SQL après where pour le filtre
     * @param nomColSomme liste de colonnes de somme pour la récapitulation
     * @param ordre requête d'ordre
     * @param c connexion à la base de données, ouverte implicitement si valeur
     * null renseignée
     * @return instance avec les resultats de recherche et les valeurs des
     * sommes de récapitulation
     * @throws Exception
     */
    @Override
    public ResultatEtSomme getDataPageGroupeMultiple(ClassMAPTable e, String[] groupe, String[] sommeGroupe,
            String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre,
            Connection c) throws Exception {
        return CGenUtil.rechercherPageGroupeM(e, groupe, sommeGroupe, colInt, valInt, numPage, apresWhere, nomColSomme, ordre, c);

    }

    /**
     * recherche groupée paginée avec récapitulation
     *
     * @param e objet de mapping
     * @param groupe liste de colonnes de groupages sans somme
     * @param sommeGroupe liste de colonnes avec sommes
     * @param colInt colonnes d'intervalle de filtre
     * @param valInt liste des valeurs de colonnes d'intervalle de filtre
     * @param numPage numéro de page actuel
     * @param apresWhere requête SQL après where pour le filtre
     * @param nomColSomme liste de colonnes de somme pour la récapitulation
     * @param ordre requête d'ordre
     * @param c connexion à la base de données, ouverte implicitement si valeur
     * null renseignée
     * @param nppa nombre d'élèment par page, si négatif le nombre d'élèment par
     * page de la configuration sera pris
     * @return instance avec les resultats de recherche et les valeurs des
     * sommes de récapitulation
     * @throws Exception
     */
    @Override
    public ResultatEtSomme getDataPageGroupeMultiple(ClassMAPTable e, String[] groupe, String[] sommeGroupe,
            String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre,
            Connection c, int npp) throws Exception {
        return CGenUtil.rechercherPageGroupeM(e, groupe, sommeGroupe, colInt, valInt, numPage, apresWhere, nomColSomme, ordre, c, npp);
    }

    /**
     *
     */
    @Override
    public ResultatEtSomme getDataPageGroupeMultiple(ClassMAPTable e, String[] groupe, String[] sommeGroupe,
            String[] colInt, String[] valInt, int numPage, String apresWhere, String[] nomColSomme, String ordre,
            Connection c, int npp, String count) throws Exception {
        return CGenUtil.rechercherPageGroupeM(e, groupe, sommeGroupe, colInt, valInt, numPage, apresWhere, nomColSomme, ordre, c, npp, count);

    }

    /**
     * Sert à updater l'etat qui prend comme paramètre
     *
     * @param e classe mapping
     * @param valeurEtat valeur de l'etat
     * @param id identifiant de l'objet à modifier
     * @param c connexion ouverte à la base de données
     */
    @Override
    public void updateEtat(ClassMAPTable e, int valeurEtat, String id, Connection c) throws Exception {
        try {
            e.setValChamp("etat", valeurEtat);
            e.updateToTableWithHisto(this.getUser().getTuppleID(), c);
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public HashMap<String, String> getMapAutoComplete() {
        return mapAutoComplete;
    }

    @Override
    public Object createObject(ClassMAPTable o, String action) throws Exception {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void ejbRemove() {
       
    }
    public ClassMAPTable[] getDataPage(ClassMAPTable e, String requete, Connection c) throws Exception {
        return (ClassMAPTable[])CGenUtil.rechercher(e, requete, c);
    }
    /**
     * Connexion allegee pour le cinema : on ne garde que ce dont ont besoin
     * module.jsp, l'en-tete et le menu (utilisateur, roles, configuration,
     * page d'accueil, societe, CNAPSUser). L'original chargeait aussi magasin,
     * personnel, directions, caisses... propres a l'ancienne application.
     */
    public void testLogin(String user, String pass, String interim, String service) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            u = testeValide(user, pass, interim, service, c);
            UtilisateurUtil crt = new UtilisateurUtil(c);
            uVue = crt.testeValide("utilisateurVue", user, pass, c);
            type = u.getIdrole();
            CNAPSUser[] cnp = (CNAPSUser[]) CGenUtil.rechercher(new CNAPSUser(), null, null, c, " and id_utilisateur = '" + u.getRefuser() + "'");
            this.cnapsUser = (cnp != null && cnp.length > 0) ? cnp[0] : null;
            this.setListeConfig((Configuration[]) CGenUtil.rechercher(new Configuration(), null, null, c, " order by typeconfig desc"));
            this.setHomePageUrl(this.findHomePageServices(u.getIdrole(), c));
            this.setActionRole(uVue.getActionRoles(c));
            Societe[] soc = (Societe[]) CGenUtil.rechercher(new Societe(), null, null, c, "");
            if (soc.length > 0) this.setMaSociete(soc[0]);
            c.commit();
        } catch (Exception ex) {
            if (c != null) c.rollback();
            ex.printStackTrace();
            throw ex;
        } finally {
            if (c != null) c.close();
        }
    }

}
