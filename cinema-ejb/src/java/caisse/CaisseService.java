package caisse;

import bean.CGenUtil;
import java.sql.Connection;
import utilitaire.UtilDB;
import utils.CinemaUtil;

/**
 * Les fonctions métier de la caisse (docs/conception/09_caisse.md §7).
 * Pour l'instant : seulement solde(), dont MouvementCaisse.createObject a besoin.
 * À venir : caissePrincipale, encaisserFacture, listerMouvements, decaisser.
 */
public class CaisseService {

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
