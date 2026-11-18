package salle;

import bean.ClassMAPTable;

/**
 * Une place LIBRE pour une séance, avec un libellé lisible (ex. "E8 - VIP (15000 Ar)").
 * Lecture seule : elle lit la vue PLACE_SEANCE_LIB.
 * Sert à la liste déroulante des places, filtrée par idseance.
 */
public class PlaceSeanceLib extends ClassMAPTable {

    private String id;          // l'id de la PLACE : c'est lui qui part dans idplace
    private String idseance;
    private String numero;
    private String libelle;

    public PlaceSeanceLib() {
        this.setNomTable("PLACE_SEANCE_LIB");
    }

    @Override public String getTuppleID() { return id; }
    @Override public String getAttributIDName() { return "id"; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdseance() { return idseance; }
    public void setIdseance(String idseance) { this.idseance = idseance; }

    public String getNumero() { return numero; }
    public void setNumero(String numero) { this.numero = numero; }

    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }
}
