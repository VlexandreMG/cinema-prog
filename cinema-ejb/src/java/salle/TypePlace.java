package salle;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Une categorie de place (Standard, VIP...) et son prix. Table TYPEPLACE.
 * Le prix est ici, et non sur chaque place : toutes les places d'un meme type coutent pareil.
 */
public class TypePlace extends ClassMAPTable {

    private String id;
    private String libelle;
    private double prix;

    public TypePlace() {
        this.setNomTable("TYPEPLACE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("TPL", "GETSEQTYPEPLACE");
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
        if (libelle == null || libelle.trim().isEmpty()) {
            throw new Exception("Le libellé du type de place est obligatoire.");
        }
        if (prix <= 0) {
            throw new Exception("Le prix doit être supérieur à 0.");
        }
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }

    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
