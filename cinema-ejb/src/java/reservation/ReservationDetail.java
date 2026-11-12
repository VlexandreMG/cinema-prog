package reservation;

import bean.ClassFille;
import java.sql.Connection;

/**
 * Une place d'une reservation (une ligne). Table RESERVATIONDETAIL.
 *
 * Le prix est recopie depuis le type de la place au moment de la reservation,
 * pour que l'historique reste juste si le prix du type change plus tard.
 * Il est calcule par Reservation.createObject, pas saisi a l'ecran.
 */
public class ReservationDetail extends ClassFille {

    private String id;
    private String idreservation;
    private String idplace;
    private double prix;

    public ReservationDetail() throws Exception {
        super.setNomTable("RESERVATIONDETAIL");
        this.setNomClasseMere("reservation.Reservation");
        this.setLiaisonMere("idreservation");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("RSD", "GETSEQRESERVATIONDETAIL");
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
    public String getNomClasseMere() {
        return "reservation.Reservation";
    }

    @Override
    public String getLiaisonMere() {
        return "idreservation";
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdreservation() { return idreservation; }
    public void setIdreservation(String idreservation) { this.idreservation = idreservation; }

    public String getIdplace() { return idplace; }
    public void setIdplace(String idplace) { this.idplace = idplace; }

    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
