package film;

import bean.ClassMAPTable;
import java.sql.Connection;
import salle.Salle;
import utils.CinemaUtil;

/**
 * Un film. Table FILM.
 * Il porte idsalle : un film passe toujours dans la meme salle.
 * Ses projections sont dans la table SEANCE (Seance.idfilm pointe vers lui).
 */
public class Film extends ClassMAPTable {

    private String id;
    private String titre;
    private int duree;        // en minutes
    private String idsalle;

    public Film() {
        this.setNomTable("FILM");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("FLM", "GETSEQFILM");
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
        if (titre == null || titre.trim().isEmpty()) {
            throw new Exception("Le titre du film est obligatoire.");
        }
        if (duree <= 0) {
            throw new Exception("La durée du film doit être supérieure à 0 minute.");
        }
        CinemaUtil.parId(new Salle(), idsalle, c);   // la salle doit exister
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }

    public int getDuree() { return duree; }
    public void setDuree(int duree) { this.duree = duree; }

    public String getIdsalle() { return idsalle; }
    public void setIdsalle(String idsalle) { this.idsalle = idsalle; }
}
