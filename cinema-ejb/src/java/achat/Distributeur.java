package achat;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * À qui le cinéma achète ses films (Netflix, Disney, Warner...). Table DISTRIBUTEUR.
 * C'est le FOURNISSEUR du socle, réduit à l'essentiel. Voir docs/conception/10_achat_film.md.
 */
public class Distributeur extends ClassMAPTable {

    private String id;
    private String nom;
    private String contact;

    public Distributeur() {
        this.setNomTable("DISTRIBUTEUR");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("DIS", "GETSEQDISTRIBUTEUR");   // -> DIS000001
        this.setId(makePK(c));
    }

    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (nom == null || nom.trim().isEmpty()) {
            throw new Exception("Le nom du distributeur est obligatoire.");
        }
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getContact() { return contact; }
    public void setContact(String contact) { this.contact = contact; }
}
