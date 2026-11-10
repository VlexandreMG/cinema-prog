package salle;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Une salle du cinema. Table SALLE.
 * Ses places sont dans la table PLACE (Place.idsalle pointe vers elle).
 */
public class Salle extends ClassMAPTable {

    private String id;
    private String nom;

    public Salle() {
        this.setNomTable("SALLE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("SAL", "GETSEQSALLE");   // -> SAL000001, SAL000002...
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
        if (nom == null || nom.trim().isEmpty()) {
            throw new Exception("Le nom de la salle est obligatoire.");
        }
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
}
