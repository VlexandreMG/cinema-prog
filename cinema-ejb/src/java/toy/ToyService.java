package toy;

import bean.CGenUtil;
import pop.Popcorn;
import jouet.Jouet;
import utilitaire.UtilDB;
import java.sql.Connection;
import java.util.HashMap;
import java.util.Map;
import utils.CinemaUtil;


public class ToyService {

    public static Popcorn[] listerPopcorn(Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            Object[] res = CGenUtil.rechercher(new Popcorn(), null, null, c, " order by nom asc");
            return (Popcorn[]) res;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    public static Jouet[] listerJouetByPopcorn(String idPopcorn, Connection c) throws Exception {
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
            // « les jouets de CE popcorn » : colonnes reelles de JOUET (idpopcorn, lib)
            Object[] res = CGenUtil.rechercher(new Jouet(), null, null, c,
                    " and idpopcorn = '" + CinemaUtil.echapper(idPopcorn) + "' order by lib asc");
            return (Jouet[]) res;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }

    /** {"A","B"} -> 'A','B' (valeurs échappées), pour un "in (...)". */
    private static String listeSql(String[] valeurs) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < valeurs.length; i++) {
            if (i > 0) sb.append(",");
            sb.append("'").append(CinemaUtil.echapper(valeurs[i])).append("'");
        }
        return sb.toString();
    }

    /*
     * A FAIRE : chargerElements a besoin d'une vue JOUET_LIB (le jouet + le lib et le prix
     * de son type) et d'une classe jouet.JouetLib qui la lit. Elles n'existent pas encore :
     * voir docs/apprentissageAPJ/vues_lib.md. Une fois creees, remplacer ElementLib par JouetLib
     * (et idElements par idJouets), puis enlever ce commentaire.
     *
     * Les éléments choisis, avec leur type et leur prix (vue ELEMENT_LIB), dans l'ordre du choix.
     * @throws Exception si un id n'existe pas
     *
    public static ElementLib[] chargerElements(String[] idElements, Connection c) throws Exception {
        if (idElements == null || idElements.length == 0) return new ElementLib[0];   // ①
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }

            // ② UNE seule requête pour tous les ids : ... where id in ('ELT000003','ELT000007')
            Object[] res = CGenUtil.rechercher(new ElementLib(), null, null, c,
                    " and id in (" + listeSql(idElements) + ")");

            // ③ Ranger le résultat par id, pour le retrouver vite
            Map<String, ElementLib> parId = new HashMap<String, ElementLib>();
            for (Object o : res) {
                ElementLib e = (ElementLib) o;
                parId.put(e.getId(), e);
            }

            // ④ Remettre dans l'ORDRE DU CHOIX, et refuser un id inconnu
            ElementLib[] elements = new ElementLib[idElements.length];
            for (int i = 0; i < idElements.length; i++) {
                elements[i] = parId.get(idElements[i]);
                if (elements[i] == null) throw new Exception("Élément introuvable : " + idElements[i]);
            }
            return elements;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }
    */
}
