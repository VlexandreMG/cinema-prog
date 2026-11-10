package salle;

import bean.ClassMAPTable;

/**
 * Une place avec les libelles utiles a l'ecran : nom de la salle, type et prix.
 * Lecture seule : elle lit la vue PLACE_LIB (voir database/01_tables_metier.sql).
 */
public class PlaceLib extends ClassMAPTable {

    private String id;
    private String idsalle;
    private String salle;
    private String numero;
    private String idtypeplace;
    private String typeplace;
    private double prix;

    public PlaceLib() {
        this.setNomTable("PLACE_LIB");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdsalle() { return idsalle; }
    public void setIdsalle(String idsalle) { this.idsalle = idsalle; }

    public String getSalle() { return salle; }
    public void setSalle(String salle) { this.salle = salle; }

    public String getNumero() { return numero; }
    public void setNumero(String numero) { this.numero = numero; }

    public String getIdtypeplace() { return idtypeplace; }
    public void setIdtypeplace(String idtypeplace) { this.idtypeplace = idtypeplace; }

    public String getTypeplace() { return typeplace; }
    public void setTypeplace(String typeplace) { this.typeplace = typeplace; }

    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
