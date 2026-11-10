package reservation;

import bean.ClassMAPTable;

/**
 * Une place reservee, avec son numero et son type. Lecture seule : vue RESERVATIONDETAIL_LIB.
 * Le prix est celui paye (recopie dans RESERVATIONDETAIL), pas le prix actuel du type.
 */
public class ReservationDetailLib extends ClassMAPTable {

    private String id;
    private String idreservation;
    private String idplace;
    private String numero;
    private String typeplace;
    private double prix;

    public ReservationDetailLib() {
        this.setNomTable("RESERVATIONDETAIL_LIB");
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

    public String getIdreservation() { return idreservation; }
    public void setIdreservation(String idreservation) { this.idreservation = idreservation; }

    public String getIdplace() { return idplace; }
    public void setIdplace(String idplace) { this.idplace = idplace; }

    public String getNumero() { return numero; }
    public void setNumero(String numero) { this.numero = numero; }

    public String getTypeplace() { return typeplace; }
    public void setTypeplace(String typeplace) { this.typeplace = typeplace; }

    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
