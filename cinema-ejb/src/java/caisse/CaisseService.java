package caisse;

import bean.CGenUtil;
import facture.Facture;
import facture.FactureService;
import java.sql.Connection;
import utilitaire.UtilDB;
import utils.CinemaUtil;

/**
 * Les fonctions métier de la caisse (docs/conception/09_caisse.md §7).
 *
 * Toutes reçoivent une Connection c, comme le reste du projet :
 *  - c != null : on travaille dans la transaction de l'appelant (ex. le paiement), sans commit ;
 *  - c == null : la fonction ouvre sa connexion, puis la ferme (et commit pour une écriture).
 */
public class CaisseService {

    /** Le nom de l'unique caisse du cinéma (pour l'instant). */
    public static final String NOM_CAISSE_PRINCIPALE = "Guichet principal";

    // ═══════════════════════════════════════════════════════════════
    //  LECTURES
    // ═══════════════════════════════════════════════════════════════

    /**
     * La caisse unique du cinéma, cherchée PAR SON NOM : son id (CAI000002 aujourd'hui)
     * dépend de la séquence et ne doit jamais être écrit en dur.
     */
    public static Caisse caissePrincipale(Connection c) throws Exception {
        Object[] res = CGenUtil.rechercher(new Caisse(), null, null, c,
                " and nom = '" + CinemaUtil.echapper(NOM_CAISSE_PRINCIPALE) + "'");
        if (res.length == 0) {
            throw new Exception("La caisse « " + NOM_CAISSE_PRINCIPALE + " » n'existe pas (voir 01_tables_metier.sql).");
        }
        return (Caisse) res[0];
    }

    /** Les mouvements validés d'une caisse, du plus récent au plus ancien. */
    public static MouvementCaisse[] listerMouvements(String idCaisse, Connection c) throws Exception {
        Object[] res = CGenUtil.rechercher(new MouvementCaisse(), null, null, c,
                " and idcaisse = '" + CinemaUtil.echapper(idCaisse) + "' and etat >= 11 order by id desc");
        return (MouvementCaisse[]) res;
    }

    // ═══════════════════════════════════════════════════════════════
    //  ÉCRITURES
    // ═══════════════════════════════════════════════════════════════

    /**
     * L'ENTRÉE en caisse d'une facture payée : montant = total de la facture
     * (pas le montant reçu : la monnaie rendue ressort aussitôt du tiroir).
     * Appelée pendant le paiement, avec la connexion c : même transaction que la réservation et la facture.
     */
    public static MouvementCaisse encaisserFacture(String idFacture, String u, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); c.setAutoCommit(false); ouvert = true; }

            Facture f = FactureService.chargerFacture(idFacture, c);
            MouvementCaisse m = new MouvementCaisse();
            m.setIdcaisse(caissePrincipale(c).getId());
            m.setDesignation("Facture n° " + f.getNumero() + " — " + f.getClient());   // texte RECOPIÉ
            m.setEntree(f.getMontanttotal());
            m.setSortie(0);
            m.setIdorigine(f.getId());                       // une facture n'est encaissée qu'une fois
            m.createObject(u, c);                            // toutes les règles (MouvementCaisse §6)

            if (ouvert) c.commit();
            return m;
        } catch (Exception e) {
            if (ouvert && c != null) c.rollback();
            throw e;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /**
     * Une SORTIE d'argent (prévue pour l'achat de films, fonctionnalité 4).
     * Refusée si le solde deviendrait négatif (règle dans MouvementCaisse.createObject).
     *
     * @param idOrigine le document qui cause la sortie (ex. l'achat), ou null
     */
    public static MouvementCaisse decaisser(String idCaisse, double montant, String designation,
                                           String idOrigine, String u, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); c.setAutoCommit(false); ouvert = true; }

            MouvementCaisse m = new MouvementCaisse();
            m.setIdcaisse(idCaisse);
            m.setDesignation(designation);
            m.setEntree(0);
            m.setSortie(montant);
            m.setIdorigine(idOrigine);
            m.createObject(u, c);

            if (ouvert) c.commit();
            return m;
        } catch (Exception e) {
            if (ouvert && c != null) c.rollback();
            throw e;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /**
     * Le solde d'une caisse = Σ entrées − Σ sorties de ses mouvements VALIDÉS.
     * Le CALCUL est fait ici, en Java : la base ne fait que stocker les mouvements.
     * Avec c != null, on voit aussi les mouvements de la transaction en cours.
     */
    public static double solde(String idCaisse, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            Object[] res = CGenUtil.rechercher(new MouvementCaisse(), null, null, c,
                    " and idcaisse = '" + CinemaUtil.echapper(idCaisse) + "' and etat >= 11");
            double solde = 0;
            for (Object o : res) {
                MouvementCaisse m = (MouvementCaisse) o;
                solde = solde + m.getEntree() - m.getSortie();
            }
            return solde;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }
}
