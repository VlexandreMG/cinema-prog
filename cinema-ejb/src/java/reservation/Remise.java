package reservation;

import bean.ClassMAPTable;
import java.sql.Connection;
import utils.CinemaUtil;
import utilitaire.UtilDB;


/**
 * Une remise entre types de place. Table REMISE.
 *   catres : le type de place RÉSERVÉ (id de TYPEPLACE)
 *   catrem : le type de place REMISÉ  (id de TYPEPLACE)
 */
public class Remise extends ClassMAPTable {

    private String id;
    private int nombre;
    private double valeur;
    private String catres;
    private String catrem;
    private int etat;                 // 1 = pas encore appliquée, 11 = appliquée (ne se redéclenche plus)

    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }


    public Remise() {
        this.setNomTable("REMISE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("REM", "GETSEQREMISE");
        this.setId(makePK(c));
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (catres == null || catres.trim().isEmpty()) {
            throw new Exception("Le type de place réservé est obligatoire.");
        }
        if (catrem == null || catrem.trim().isEmpty()) {
            throw new Exception("Le type de place remisé est obligatoire.");
        }
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public int getNombre() { return nombre; }
    public void setNombre(int nombre) { this.nombre = nombre; }

    public double getValeur() { return valeur; }
    public void setValeur(double valeur) { this.valeur = valeur; }

    public String getCatres() { return catres; }
    public void setCatres(String catres) { this.catres = catres; }

    public String getCatrem() { return catrem; }
    public void setCatrem(String catrem) { this.catrem = catrem; }

    /**
     * Les remises qui se déclenchent quand on réserve des places du type idTypePlace (catres = idTypePlace).
     * Tableau vide s'il n'y en a aucune.
     */
    public static Remise[] listerParTypeReserve(String idTypePlace, Connection c) throws Exception {
        Object[] res = bean.CGenUtil.rechercher(new Remise(), null, null, c,
                " and catres = '" + CinemaUtil.echapper(idTypePlace) + "'");
        return (Remise[]) res;
    }

    public static Remise getRemisByIdTypePlace(Connection c , String idRes) throws Exception {
             boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }   // j'ouvre si on ne m'a rien donné
        // ... le travail, en passant TOUJOURS c ...
        Object n = CinemaUtil.parId(new Remise(),idRes,c);
                Remise res = (Remise) n;
        return res;
    } finally {
        if (ouvert && c != null) c.close();                            // je ferme seulement ce que j'ai ouvert
    }
    }
    }

