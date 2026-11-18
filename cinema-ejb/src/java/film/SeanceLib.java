package film;

import bean.ClassMAPTable;
import java.sql.Date;

/** Une séance avec un libellé lisible. Lecture seule : elle lit la vue SEANCE_LIB. */
public class SeanceLib extends ClassMAPTable {

    private String id;
    private String idfilm;
    private Date daty;
    private String heure;
    private String libelle;

    public SeanceLib() {
        this.setNomTable("SEANCE_LIB");
    }

    @Override public String getTuppleID() { return id; }
    @Override public String getAttributIDName() { return "id"; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdfilm() { return idfilm; }
    public void setIdfilm(String idfilm) { this.idfilm = idfilm; }

    public Date getDaty() { return daty; }
    public void setDaty(Date daty) { this.daty = daty; }

    public String getHeure() { return heure; }
    public void setHeure(String heure) { this.heure = heure; }

    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }
}
