package reservation;

import bean.ClassMAPTable;
import java.sql.Date;

/**
 * Une reservation avec les libelles utiles a l'ecran (client, film, salle, seance).
 * Lecture seule : elle lit la vue RESERVATION_LIB.
 */
public class ReservationLib extends ClassMAPTable {

    private String id;
    private String idclient;
    private String client;
    private String idseance;
    private Date dateseance;
    private String heure;
    private String idfilm;
    private String film;
    private String salle;
    private Date daty;              // date de la reservation
    private double montanttotal;
    private int etat;

    public ReservationLib() {
        this.setNomTable("RESERVATION_LIB");
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

    public String getIdclient() { return idclient; }
    public void setIdclient(String idclient) { this.idclient = idclient; }

    public String getClient() { return client; }
    public void setClient(String client) { this.client = client; }

    public String getIdseance() { return idseance; }
    public void setIdseance(String idseance) { this.idseance = idseance; }

    public Date getDateseance() { return dateseance; }
    public void setDateseance(Date dateseance) { this.dateseance = dateseance; }

    public String getHeure() { return heure; }
    public void setHeure(String heure) { this.heure = heure; }

    public String getIdfilm() { return idfilm; }
    public void setIdfilm(String idfilm) { this.idfilm = idfilm; }

    public String getFilm() { return film; }
    public void setFilm(String film) { this.film = film; }

    public String getSalle() { return salle; }
    public void setSalle(String salle) { this.salle = salle; }

    public Date getDaty() { return daty; }
    public void setDaty(Date daty) { this.daty = daty; }

    public double getMontanttotal() { return montanttotal; }
    public void setMontanttotal(double montanttotal) { this.montanttotal = montanttotal; }

    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
