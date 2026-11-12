package salle;

import bean.ClassMAPTable;
import java.sql.Connection;
import utils.CinemaUtil;
import bean.CGenUtil;
import utilitaire.UtilDB;



/**
 * Un siege d'une salle. Table PLACE.
 * Elle porte idsalle (une salle a plusieurs places, une place n'a qu'une salle)
 * et idtypeplace (qui donne son prix).
 *
 * Il n'y a pas de colonne "libre / reservee" : une place est occupee
 * pour une seance, et cela se deduit des reservations de cette seance.
 */
public class Place extends ClassMAPTable {

    private String id;
    private String idsalle;
    private String numero;
    private String idtypeplace;

    public Place() {
        this.setNomTable("PLACE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("PLC", "GETSEQPLACE");
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
        if (numero == null || numero.trim().isEmpty()) {
            throw new Exception("Le numéro de la place est obligatoire.");
        }
        CinemaUtil.parId(new Salle(), idsalle, c);          // la salle doit exister
        CinemaUtil.parId(new TypePlace(), idtypeplace, c);  // le type aussi
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdsalle() { return idsalle; }
    public void setIdsalle(String idsalle) { this.idsalle = idsalle; }

    public String getNumero() { return numero; }
    public void setNumero(String numero) { this.numero = numero; }

    public String getIdtypeplace() { return idtypeplace; }
    public void setIdtypeplace(String idtypeplace) { this.idtypeplace = idtypeplace; }

    public static double getIdtypeplaceByIdPlace(Connection c , String idPlace) throws Exception {
         boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }   // j'ouvre si on ne m'a rien donné
        // ... le travail, en passant TOUJOURS c ...
        Object n = CGenUtil.rechercherSimple("select idtypeplace from PLACE where id = '"
                + CinemaUtil.echapper(idPlace) + "'", c);
                String idTypePlace = (String) n;
                double val = TypePlace.getPrixbyIdTypePlace(c,idTypePlace);
                return val;
    } finally {
        if (ouvert && c != null) c.close();                            // je ferme seulement ce que j'ai ouvert
    }
    }

    
}
