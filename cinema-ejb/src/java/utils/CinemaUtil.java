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
     * Protege un texte avant de l'ecrire dans une page HTML (< > & " ').
     * Exemple : un client nomme "<b>Rakoto" s'affiche tel quel, sans casser la page.
     */
    public static String html(String texte) {
        if (texte == null) return "";
        return texte.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                    .replace("\"", "&quot;").replace("'", "&#39;");
    }

    /** 38000.0 -> "38 000" (separateur des milliers : espace). */
    public static String montant(double valeur) {
        java.text.DecimalFormatSymbols sym = new java.text.DecimalFormatSymbols();
        sym.setGroupingSeparator(' ');
        return new java.text.DecimalFormat("#,##0", sym).format(valeur);
    }

    /** Une date SQL en "jj/mm/aaaa" (vide si null). */
    public static String date(java.sql.Date d) {
        return d == null ? "" : new java.text.SimpleDateFormat("dd/MM/yyyy").format(d);
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
