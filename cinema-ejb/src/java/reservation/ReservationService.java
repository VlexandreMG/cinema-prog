package reservation;

import bean.CGenUtil;
import bean.ClassFille;
import client.Client;
import film.Film;
import film.Seance;
import java.sql.Connection;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import salle.PlaceLib;
import salle.Salle;
import utils.CinemaUtil;
import utilitaire.UtilDB;

/**
 * Les fonctions metier de l'ecran de reservation (scenario 1).
 * Une fonction par champ de l'ecran :
 *
 *   Client       -> listerClients()
 *   Film         -> listerFilms()
 *   Salle        -> salleDuFilm(idFilm)            (lecture seule, deduite du film)
 *   Seance       -> listerSeances(idFilm)
 *   Liste place  -> listerPlacesLibres(idSeance)
 *   Prix (total) -> calculerMontant(idPlaces)
 *   Reserver     -> reserver(idClient, idSeance, idPlaces, user)
 *
 * Toutes recoivent une Connection c, comme dans le reste du socle :
 *  - c != null : on travaille dans la transaction de l'appelant, sans commit ni fermeture ;
 *  - c == null : la fonction ouvre sa propre connexion, puis la ferme (et commit pour reserver).
 */
public class ReservationService {

    // ═══════════════════════════════════════════════════════════════
    //  LECTURES : remplir les champs de l'ecran
    // ═══════════════════════════════════════════════════════════════

    /** Tous les clients, par nom. */
    public static Client[] listerClients(Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            Object[] res = CGenUtil.rechercher(new Client(), null, null, c, " order by nom asc");
            return (Client[]) res;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /** Tous les films, par titre. */
    public static Film[] listerFilms(Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            Object[] res = CGenUtil.rechercher(new Film(), null, null, c, " order by titre asc");
            return (Film[]) res;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /** La salle d'un film : elle remplit le champ Salle (lecture seule) quand on choisit le film. */
    public static Salle salleDuFilm(String idFilm, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            Film film = (Film) CinemaUtil.parId(new Film(), idFilm, c);
            return (Salle) CinemaUtil.parId(new Salle(), film.getIdsalle(), c);
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /**
     * Les seances A VENIR d'un film, de la plus proche a la plus lointaine.
     * Le SQL garde les seances d'aujourd'hui et apres ; Java retire celles d'aujourd'hui deja commencees.
     */
    public static Seance[] listerSeances(String idFilm, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            String filtre = " and idfilm = '" + CinemaUtil.echapper(idFilm) + "'"
                    + " and daty >= trunc(sysdate) order by daty asc, heure asc";
            Object[] res = CGenUtil.rechercher(new Seance(), null, null, c, filtre);

            long maintenant = System.currentTimeMillis();
            List<Seance> aVenir = new ArrayList<Seance>();
            for (Object o : res) {
                Seance s = (Seance) o;
                if (s.calculerDebut() > maintenant) aVenir.add(s);
            }
            return aVenir.toArray(new Seance[aVenir.size()]);
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /**
     * Les places libres d'une seance : les places de la salle du film,
     * sauf celles deja dans une reservation non annulee de cette seance.
     * Chaque place vient avec son type et son prix (vue PLACE_LIB).
     */
    public static PlaceLib[] listerPlacesLibres(String idSeance, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            Seance seance = (Seance) CinemaUtil.parId(new Seance(), idSeance, c);
            Film film = (Film) CinemaUtil.parId(new Film(), seance.getIdfilm(), c);

            String filtre = " and idsalle = '" + CinemaUtil.echapper(film.getIdsalle()) + "'"
                    + " and id not in ("
                    + "   select d.idplace from RESERVATIONDETAIL d"
                    + "   join RESERVATION r on r.id = d.idreservation"
                    + "   where r.idseance = '" + CinemaUtil.echapper(idSeance) + "' and r.etat <> 0)"
                    + " order by numero asc";
            Object[] res = CGenUtil.rechercher(new PlaceLib(), null, null, c, filtre);
            return (PlaceLib[]) res;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /**
     * Le total a payer pour les places choisies : la somme des prix de leur type.
     * Sert a l'affichage ; reserver() refait le calcul cote serveur.
     */
    public static double calculerMontant(String[] idPlaces, Connection c) throws Exception {
        double total = 0;
        for (PlaceLib p : chargerPlaces(idPlaces, c)) {
            total += p.getPrix();
        }
        return total;
    }

    /**
     * Les places choisies, avec leur type et leur prix, dans l'ordre ou elles ont ete choisies.
     * Sert au recapitulatif avant paiement.
     * @throws Exception si une place n'existe pas
     */
    public static PlaceLib[] chargerPlaces(String[] idPlaces, Connection c) throws Exception {
        if (idPlaces == null || idPlaces.length == 0) return new PlaceLib[0];
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            Object[] res = CGenUtil.rechercher(new PlaceLib(), null, null, c,
                    " and id in (" + listeSql(idPlaces) + ")");
            Map<String, PlaceLib> parId = new HashMap<String, PlaceLib>();
            for (Object o : res) {
                PlaceLib p = (PlaceLib) o;
                parId.put(p.getId(), p);
            }
            PlaceLib[] places = new PlaceLib[idPlaces.length];
            for (int i = 0; i < idPlaces.length; i++) {
                places[i] = parId.get(idPlaces[i]);
                if (places[i] == null) throw new Exception("Place introuvable : " + idPlaces[i]);
            }
            return places;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  LECTURES : la fiche d'une reservation (apres paiement)
    // ═══════════════════════════════════════════════════════════════

    /** Une reservation avec les libelles du client, du film, de la salle et de la seance. */
    public static ReservationLib chargerReservation(String idReservation, Connection c) throws Exception {
        return (ReservationLib) CinemaUtil.parId(new ReservationLib(), idReservation, c);
    }

    /** Les places d'une reservation, avec le prix paye pour chacune. */
    public static ReservationDetailLib[] listerLignes(String idReservation, Connection c) throws Exception {
        Object[] res = CGenUtil.rechercher(new ReservationDetailLib(), null, null, c,
                " and idreservation = '" + CinemaUtil.echapper(idReservation) + "' order by numero asc");
        return (ReservationDetailLib[]) res;
    }

    // ═══════════════════════════════════════════════════════════════
    //  ECRITURE : le bouton Reserver
    // ═══════════════════════════════════════════════════════════════

    /**
     * Cree la reservation et une ligne par place, en une seule transaction.
     * Les controles et le calcul des prix sont dans Reservation.createObject.
     *
     * @param u l'id de l'utilisateur connecte (APJ le garde dans l'historique)
     * @return la reservation creee, avec son id et son montant total
     */
    public static Reservation reserver(String idClient, String idSeance, String[] idPlaces,
                                       String u, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                c.setAutoCommit(false);
                ouvert = true;
            }
            if (idPlaces == null || idPlaces.length == 0) {
                throw new Exception("Choisissez au moins une place.");
            }

            Reservation r = new Reservation();
            r.setIdclient(idClient);
            r.setIdseance(idSeance);

            ClassFille[] lignes = new ClassFille[idPlaces.length];
            for (int i = 0; i < idPlaces.length; i++) {
                ReservationDetail d = new ReservationDetail();
                d.setIdplace(idPlaces[i]);
                lignes[i] = d;
            }
            r.setFille(lignes);

            r.createObject(u, c);       // controles + INSERT de la mere puis des lignes

            if (ouvert) c.commit();
            return r;
        } catch (Exception e) {
            if (ouvert && c != null) c.rollback();
            throw e;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /** {"A","B"} -> 'A','B' (valeurs echappees), pour un "in (...)". */
    private static String listeSql(String[] valeurs) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < valeurs.length; i++) {
            if (i > 0) sb.append(",");
            sb.append("'").append(CinemaUtil.echapper(valeurs[i])).append("'");
        }
        return sb.toString();
    }
}
