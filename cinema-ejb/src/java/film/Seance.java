package film;

import bean.CGenUtil;
import bean.ClassMAPTable;
import java.sql.Connection;
import java.sql.Date;
import utils.CinemaUtil;

/**
 * Une projection d'un film a une date et une heure. Table SEANCE.
 *
 * La date (daty) et l'heure (heure, "HH:mm") sont separees, comme dans le reste
 * du socle APJ. L'heure de fin n'est pas stockee : debut + duree du film.
 *
 * Regle : deux seances d'une meme salle ne se chevauchent pas.
 */
public class Seance extends ClassMAPTable {

    private String id;
    private String idfilm;
    private Date daty;
    private String heure;

    public Seance() {
        this.setNomTable("SEANCE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("SEA", "GETSEQSEANCE");
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

    // ═══ CALCULS ═══

    /** Le debut de la seance, en millisecondes (date + heure). */
    public long calculerDebut() throws Exception {
        if (daty == null) {
            throw new Exception("La date de la séance est obligatoire.");
        }
        return daty.getTime() + CinemaUtil.minutesDepuisMinuit(heure) * 60000L;
    }

    /** La fin de la seance, en millisecondes : debut + duree du film. */
    public long calculerFin(Film film) throws Exception {
        return calculerDebut() + film.getDuree() * 60000L;
    }

    // ═══ CONTROLES ═══

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        Film film = (Film) CinemaUtil.parId(new Film(), idfilm, c);
        long debut = calculerDebut();          // verifie aussi date et heure
        long fin = calculerFin(film);
        verifierChevauchement(film, debut, fin, c);
        return super.createObject(u, c);
    }

    /**
     * Refuse la seance si une autre seance de la meme salle se deroule en meme temps.
     * Deux intervalles [debut, fin[ se chevauchent si chacun commence avant la fin de l'autre.
     */
    private void verifierChevauchement(Film film, long debut, long fin, Connection c) throws Exception {
        String filtre = " and idfilm in (select id from FILM where idsalle = '"
                + CinemaUtil.echapper(film.getIdsalle()) + "')";
        Object[] autres = CGenUtil.rechercher(new Seance(), null, null, c, filtre);
        for (Object o : autres) {
            Seance s = (Seance) o;
            if (s.getId() != null && s.getId().equals(this.id)) {
                continue;   // c'est moi-meme (cas d'une modification)
            }
            Film autreFilm = (Film) CinemaUtil.parId(new Film(), s.getIdfilm(), c);
            long debut2 = s.calculerDebut();
            long fin2 = s.calculerFin(autreFilm);
            if (debut < fin2 && debut2 < fin) {
                throw new Exception("La salle est déjà occupée par « " + autreFilm.getTitre()
                        + " » (séance " + s.getId() + " à " + s.getHeure() + ").");
            }
        }
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdfilm() { return idfilm; }
    public void setIdfilm(String idfilm) { this.idfilm = idfilm; }

    public Date getDaty() { return daty; }
    public void setDaty(Date daty) { this.daty = daty; }

    public String getHeure() { return heure; }
    public void setHeure(String heure) { this.heure = heure; }
}
