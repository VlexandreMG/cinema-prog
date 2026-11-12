package reservation;

import bean.CGenUtil;
import bean.ClassMAPTable;
import bean.ClassMere;
import client.Client;
import constante.ConstanteEtat;
import film.Film;
import film.Seance;
import java.sql.Connection;
import java.sql.Date;
import java.util.HashSet;
import java.util.Set;
import salle.Place;
import salle.TypePlace;
import utils.CinemaUtil;
import utilitaire.Utilitaire;

/**
 * L'achat d'un client pour une seance. Table RESERVATION (la mere).
 * Ses places sont les lignes RESERVATIONDETAIL (les filles), reliees par idreservation.
 *
 * Le paiement est immediat et complet : une reservation enregistree est une reservation payee.
 * etat : 11 = validee (payee), 0 = annulee (plus tard). Seules les reservations
 * non annulees occupent leurs places.
 */
public class Reservation extends ClassMere {

    private String id;
    private String idclient;
    private String idseance;
    private Date daty;              // date de la reservation
    private double montanttotal;
    private int etat;

    public Reservation() throws Exception {
        super.setNomTable("RESERVATION");
        this.setNomClasseFille("reservation.ReservationDetail");
        this.setLiaisonFille("idreservation");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("RSV", "GETSEQRESERVATION");
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

    // ═══ CONTROLES ET CALCULS (fonction reserver du scenario) ═══

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        CinemaUtil.parId(new Client(), idclient, c);                       // le client existe
        Seance seance = (Seance) CinemaUtil.parId(new Seance(), idseance, c);

        // Verrou sur la seance jusqu'a la fin de la transaction : si deux guichets reservent
        // pour la meme seance en meme temps, le second attend que le premier ait fini,
        // puis voit ses places comme deja prises.
        CGenUtil.rechercherSimple("select id from SEANCE where id = '"
                + CinemaUtil.echapper(idseance) + "' for update", c);
        Film film = (Film) CinemaUtil.parId(new Film(), seance.getIdfilm(), c);

        if (seance.calculerDebut() < System.currentTimeMillis()) {
            throw new Exception("La séance " + seance.getId() + " a déjà commencé : réservation impossible.");
        }

        ReservationDetail[] lignes = (ReservationDetail[]) this.getFille();
        if (lignes == null || lignes.length == 0) {
            throw new Exception("Choisissez au moins une place.");
        }

        double total = 0;
        Set<String> dejaChoisies = new HashSet<String>();
        for (ReservationDetail ligne : lignes) {
            Place place = (Place) CinemaUtil.parId(new Place(), ligne.getIdplace(), c);

            if (!dejaChoisies.add(place.getId())) {
                throw new Exception("La place " + place.getNumero() + " est choisie deux fois.");
            }
            if (!place.getIdsalle().equals(film.getIdsalle())) {
                throw new Exception("La place " + place.getNumero() + " n'est pas dans la salle du film.");
            }
            if (estReservee(place.getId(), seance.getId(), c)) {
                throw new Exception("La place " + place.getNumero() + " est déjà réservée pour cette séance.");
            }

            // Le prix vient du type de la place, cote serveur (on ne fait pas confiance a l'ecran)
            TypePlace type = (TypePlace) CinemaUtil.parId(new TypePlace(), place.getIdtypeplace(), c);
            ligne.setPrix(type.getPrix());
            total += type.getPrix();
        }

        this.setDaty(Utilitaire.dateDuJourSql());
        // Payee tout de suite : la reservation est enregistree VALIDEE (11).
        // Sans cette ligne, etat vaudrait 0 (= annulee) et ses places resteraient "libres".
        this.setEtat(ConstanteEtat.getEtatValider());
        this.setMontanttotal(total);
        return super.createObject(u, c);   // INSERT de la mere, puis des lignes, dans la meme transaction
    }

    /**
     * Une place est reservee pour une seance s'il existe une ligne de detail avec cette place,
     * dans une reservation non annulee de cette seance.
     */
    public static boolean estReservee(String idplace, String idseance, Connection c) throws Exception {
        String sql = "select count(*) from RESERVATIONDETAIL d"
                + " join RESERVATION r on r.id = d.idreservation"
                + " where d.idplace = '" + CinemaUtil.echapper(idplace) + "'"
                + " and r.idseance = '" + CinemaUtil.echapper(idseance) + "'"
                + " and r.etat <> 0";
        Object o = CGenUtil.rechercherSimple(sql, c);
        return (o instanceof Number) && ((Number) o).intValue() > 0;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdclient() { return idclient; }
    public void setIdclient(String idclient) { this.idclient = idclient; }

    public String getIdseance() { return idseance; }
    public void setIdseance(String idseance) { this.idseance = idseance; }

    public Date getDaty() { return daty; }
    public void setDaty(Date daty) { this.daty = daty; }

    public double getMontanttotal() { return montanttotal; }
    public void setMontanttotal(double montanttotal) { this.montanttotal = montanttotal; }

    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }

    public static Reservation getReservationByIdReservation(Connection c , String idRes) throws Exception {
         boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }   // j'ouvre si on ne m'a rien donné
        // ... le travail, en passant TOUJOURS c ...
        Object n = CGenUtil.rechercherSimple("select * from RESERVATION where id = '"
                + CinemaUtil.echapper(idRes) + "'", c);
                Reservation res = (Reservation) n;
        return res;
    } finally {
        if (ouvert && c != null) c.close();                            // je ferme seulement ce que j'ai ouvert
    }
    }
}

