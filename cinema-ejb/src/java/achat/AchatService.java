package achat;

import bean.CGenUtil;
import caisse.CaisseService;
import film.Film;
import java.sql.Connection;
import salle.Salle;
import utilitaire.UtilDB;
import utils.CinemaUtil;

/**
 * Les fonctions métier de l'achat de films (docs/conception/10_achat_film.md §7).
 *
 * Toutes reçoivent une Connection c, comme le reste du projet :
 *  - c != null : on travaille dans la transaction de l'appelant, sans commit ;
 *  - c == null : la fonction ouvre sa connexion, puis la ferme (et commit / rollback pour une écriture).
 */
public class AchatService {

    // ═══════════════════════════════════════════════════════════════
    //  LECTURES : remplir les listes de l'écran d'achat
    // ═══════════════════════════════════════════════════════════════

    /** Les distributeurs, par nom (liste déroulante « Distributeur »). */
    public static Distributeur[] listerDistributeurs(Connection c) throws Exception {
        Object[] res = CGenUtil.rechercher(new Distributeur(), null, null, c, " order by nom asc");
        return (Distributeur[]) res;
    }

    /** Les salles, par nom (liste déroulante « Salle » du film acheté). */
    public static Salle[] listerSalles(Connection c) throws Exception {
        Object[] res = CGenUtil.rechercher(new Salle(), null, null, c, " order by nom asc");
        return (Salle[]) res;
    }

    // ═══════════════════════════════════════════════════════════════
    //  ÉCRITURE : acheter un film
    // ═══════════════════════════════════════════════════════════════

    /**
     * Achète les droits d'un film, en UNE transaction :
     *   1. crée le film dans le catalogue  (Film.createObject : titre, durée > 0, salle existe) ;
     *   2. enregistre l'achat             (Achat.createObject : distributeur, film pas déjà acheté, montant > 0) ;
     *   3. fait SORTIR l'argent de la caisse (CaisseService.decaisser → MouvementCaisse.createObject :
     *      verrou sur la caisse + refus si le solde deviendrait négatif).
     * L'ordre compte : l'achat a besoin de l'id du film, la sortie a besoin de l'id de l'achat (origine).
     *
     * Si une étape échoue (ex. « Solde insuffisant »), tout est annulé : le film et l'achat aussi.
     * ⚠ Avec c != null, c'est l'APPELANT qui doit faire le rollback en cas d'erreur.
     *
     * @param u l'id de l'utilisateur connecté (numérique : écrit dans HISTORIQUE)
     * @return l'achat créé (id, film, montant)
     */
    public static Achat acheterFilm(String titre, int duree, String idSalle, String idDistributeur,
                                    double montant, String u, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); c.setAutoCommit(false); ouvert = true; }

            // 1. Le film entre au catalogue
            Film film = new Film();
            film.setTitre(titre);
            film.setDuree(duree);
            film.setIdsalle(idSalle);
            film.createObject(u, c);

            // 2. L'achat de ses droits
            Achat achat = new Achat();
            achat.setIddistributeur(idDistributeur);
            achat.setIdfilm(film.getId());
            achat.setMontant(montant);
            achat.createObject(u, c);

            // 3. L'argent sort de la caisse (refusé si elle n'en a pas assez)
            Distributeur distributeur = (Distributeur) CinemaUtil.parId(new Distributeur(), idDistributeur, c);
            String designation = "Achat des droits — " + titre + " — " + distributeur.getNom();   // texte RECOPIÉ
            CaisseService.decaisser(CaisseService.caissePrincipale(c).getId(), montant, designation,
                    achat.getId(), u, c);

            if (ouvert) c.commit();
            return achat;
        } catch (Exception e) {
            if (ouvert && c != null) c.rollback();
            throw e;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }
}
