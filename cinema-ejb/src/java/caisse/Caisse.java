package caisse;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Une caisse du cinéma. Table CAISSE.
 * Pour l'instant il n'y en a qu'une : « Guichet principal ».
 *
 * Elle ne stocke PAS son solde : il se calcule à partir de ses mouvements
 * (CaisseService.solde = Σ entrées − Σ sorties). Voir docs/conception/09_caisse.md.
 */
public class Caisse extends ClassMAPTable {

    private String id;
    private String nom;

    public Caisse() {
        this.setNomTable("CAISSE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CAI", "GETSEQCAISSE");   // -> CAI000001
        this.setId(makePK(c));
    }

    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (nom == null || nom.trim().isEmpty()) {
            throw new Exception("Le nom de la caisse est obligatoire.");
        }
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
}
