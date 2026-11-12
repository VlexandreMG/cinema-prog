package facture;

import bean.CGenUtil;
import bean.ClassFille;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Calendar;
import reservation.ReservationDetailLib;
import reservation.ReservationLib;
import reservation.ReservationService;
import utilitaire.UtilDB;
import utils.CinemaUtil;

/**
 * Les fonctions métier de la facture client (docs/conception/08_facture_client.md).
 */
public class FactureService {

    // ═══════════════════════════════════════════════════════════════
    //  ÉCRITURE : émettre la facture d'une réservation payée
    // ═══════════════════════════════════════════════════════════════

    /**
     * Construit et enregistre la facture d'une réservation, à partir de son id.
     * Tout est RECOPIÉ depuis la réservation : nom du client, objet (film, séance, salle),
     * et une ligne par place (désignation + prix payé).
     *
     * c != null : on travaille dans la transaction de l'appelant (ex. le paiement), sans commit.
     * c == null : la fonction ouvre sa transaction, puis commit (ou rollback en cas d'erreur).
     *
     * @param u l'id de l'utilisateur connecté (numérique : écrit dans HISTORIQUE)
     * @return la facture créée (id, numéro, total)
     */
    public static Facture genererFacture(String idReservation, String u, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); c.setAutoCommit(false); ouvert = true; }

            // 1. LIRE la réservation et ses places, avec leurs libellés (vues _LIB), DANS la même connexion
            ReservationLib r = ReservationService.chargerReservation(idReservation, c);
            ReservationDetailLib[] places = ReservationService.listerLignes(idReservation, c);

            // 2. La mère : les textes de l'en-tête sont RECOPIÉS (la facture est figée)
            String objet = r.getFilm() + " — " + CinemaUtil.date(r.getDateseance()) + " " + r.getHeure()
                    + " — " + r.getSalle();
            Facture f = new Facture();
            f.setIdreservation(r.getId());
            f.setClient(r.getClient());
            f.setObjet(objet);

            // 3. Une ligne par place : désignation recopiée + prix PAYÉ (celui de RESERVATIONDETAIL)
            ClassFille[] lignes = new ClassFille[places.length];
            for (int i = 0; i < places.length; i++) {
                FactureDetail d = new FactureDetail();                 // ni id, ni idfacture : APJ les remplit
                d.setDesignation(objet + " — Place " + places[i].getNumero()
                        + " (" + places[i].getTypeplace() + ")");
                d.setPrix(places[i].getPrix());
                lignes[i] = d;
            }
            f.setFille(lignes);

            // 4. Toutes les règles + numéro légal + INSERT facture puis lignes (Facture.createObject)
            f.createObject(u, c);

            if (ouvert) c.commit();
            return f;
        } catch (Exception e) {
            if (ouvert && c != null) c.rollback();
            throw e;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /**
     * Le prochain numéro LÉGAL de facture de l'année : 0001/2026, 0002/2026...
     * Continu et SANS TROU : le compteur est lu et mis à jour DANS la transaction de l'appelant.
     *   - FOR UPDATE : un autre paiement attend que celui-ci ait fini (pas de doublon) ;
     *   - un rollback annule aussi la mise à jour du compteur (pas de trou).
     * Le calcul (+1, format, changement d'année) est fait ICI, en Java ; la base garde la valeur et le verrou.
     *
     * @param c OBLIGATOIRE : la connexion de la transaction en cours (jamais null)
     */
    public static String prochainNumero(Connection c) throws Exception {
        if (c == null) throw new Exception("prochainNumero doit être appelé dans une transaction.");
        int annee = Calendar.getInstance().get(Calendar.YEAR);

        Integer dernier = lireDernierVerrouille(annee, c);
        if (dernier == null) {
            // 1re facture de l'année : on crée la ligne de l'année, puis on la verrouille
            try (PreparedStatement ps = c.prepareStatement(
                    "insert into COMPTEURFACTURE (annee, dernier) values (?, 0)")) {
                ps.setInt(1, annee);
                ps.executeUpdate();
            } catch (SQLException e) {
                // Un autre paiement l'a créée au même instant (clé en double) : on continue avec la sienne
                if (e.getErrorCode() != 1) throw e;
            }
            dernier = lireDernierVerrouille(annee, c);
        }

        int prochain = dernier + 1;
        try (PreparedStatement ps = c.prepareStatement(
                "update COMPTEURFACTURE set dernier = ? where annee = ?")) {
            ps.setInt(1, prochain);
            ps.setInt(2, annee);
            ps.executeUpdate();
        }
        return String.format("%04d/%d", prochain, annee);         // 3 → "0003/2026"
    }

    /** Lit le dernier numéro de l'année en VERROUILLANT la ligne ; null si l'année n'existe pas encore. */
    private static Integer lireDernierVerrouille(int annee, Connection c) throws Exception {
        try (PreparedStatement ps = c.prepareStatement(
                "select dernier from COMPTEURFACTURE where annee = ? for update")) {
            ps.setInt(1, annee);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  LECTURES : afficher une facture (pas de vue _LIB : la facture contient déjà ses textes)
    // ═══════════════════════════════════════════════════════════════

    /** Une facture par son id technique (FAC…). */
    public static Facture chargerFacture(String idFacture, Connection c) throws Exception {
        return (Facture) CinemaUtil.parId(new Facture(), idFacture, c);
    }

    /** Les lignes d'une facture, dans l'ordre de création. */
    public static FactureDetail[] listerLignes(String idFacture, Connection c) throws Exception {
        Object[] res = CGenUtil.rechercher(new FactureDetail(), null, null, c,
                " and idfacture = '" + CinemaUtil.echapper(idFacture) + "' order by id asc");
        return (FactureDetail[]) res;
    }

    /** La facture d'une réservation, ou null si elle n'est pas (encore) facturée. */
    public static Facture factureDeLaReservation(String idReservation, Connection c) throws Exception {
        Object[] res = CGenUtil.rechercher(new Facture(), null, null, c,
                " and idreservation = '" + CinemaUtil.echapper(idReservation) + "'");
        return res.length > 0 ? (Facture) res[0] : null;
    }
}
