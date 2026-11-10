package utils;

import bean.CGenUtil;
import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Petits outils communs aux classes du cinema.
 */
public class CinemaUtil {

    /**
     * Charge un enregistrement par son id.
     * Exemple : Film f = (Film) CinemaUtil.parId(new Film(), "FLM000001", c);
     *
     * @param modele un objet vide de la classe voulue (il donne la table)
     * @param id     l'id cherche
     * @param c      la connexion de la transaction en cours
     * @throws Exception si l'id est vide ou introuvable
     */
    public static ClassMAPTable parId(ClassMAPTable modele, String id, Connection c) throws Exception {
        if (id == null || id.trim().isEmpty()) {
            throw new Exception("Identifiant manquant pour " + modele.getClass().getSimpleName() + ".");
        }
        Object[] res = CGenUtil.rechercher(modele, null, null, c, " and id = '" + echapper(id) + "'");
        if (res == null || res.length == 0) {
            throw new Exception(modele.getClass().getSimpleName() + " introuvable : " + id);
        }
        return (ClassMAPTable) res[0];
    }

    /**
     * Double les apostrophes, pour coller une valeur dans une requete SQL sans la casser.
     */
    public static String echapper(String valeur) {
        return valeur == null ? "" : valeur.replace("'", "''");
    }

    /**
     * Lit une heure "HH:mm" et renvoie le nombre de minutes depuis minuit.
     * Exemple : "18:30" -> 1110.
     *
     * @throws Exception si le format est invalide
     */
    public static int minutesDepuisMinuit(String heure) throws Exception {
        if (heure == null || !heure.trim().matches("\\d{1,2}:\\d{2}")) {
            throw new Exception("Heure invalide : '" + heure + "'. Format attendu : HH:mm (ex. 18:00).");
        }
        String[] hm = heure.trim().split(":");
        int h = Integer.parseInt(hm[0]);
        int m = Integer.parseInt(hm[1]);
        if (h > 23 || m > 59) {
            throw new Exception("Heure invalide : '" + heure + "'.");
        }
        return h * 60 + m;
    }
}
