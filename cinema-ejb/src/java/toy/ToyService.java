package toy;

import toy.Toy;
import bean.CGenUtil;
import pop.Popcorn;
import jouet.Jouet;
import jouet.JouetLib;
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
     * voir docs/apprentissageAPJ/vues_lib.md. Une fois creees, remplacer JouetLib par JouetLib
     * (et idJouets par idJouets), puis enlever ce commentaire.
     *
     * Les éléments choisis, avec leur type et leur prix (vue ELEMENT_LIB), dans l'ordre du choix.
     * @throws Exception si un id n'existe pas
     *
    */
    public static JouetLib[] chargerElements(String[] idJouets, Connection c) throws Exception {
        if (idJouets == null || idJouets.length == 0) return new JouetLib[0];   // ①
        boolean ouvert = false;
        try {
            if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }

            // ② UNE seule requête pour tous les ids : ... where id in ('ELT000003','ELT000007')
            Object[] res = CGenUtil.rechercher(new JouetLib(), null, null, c,
                    " and id in (" + listeSql(idJouets) + ")");

            // ③ Ranger le résultat par id, pour le retrouver vite
            Map<String, JouetLib> parId = new HashMap<String, JouetLib>();
            for (Object o : res) {
                JouetLib e = (JouetLib) o;
                parId.put(e.getId(), e);
            }

            // ④ Remettre dans l'ORDRE DU CHOIX, et refuser un id inconnu
            JouetLib[] elements = new JouetLib[idJouets.length];
            for (int i = 0; i < idJouets.length; i++) {
                elements[i] = parId.get(idJouets[i]);
                if (elements[i] == null) throw new Exception("Élément introuvable : " + idJouets[i]);
            }
            return elements;
        } finally {
            if (ouvert && c != null) c.close();
        }
    }    

    public static double calculerMontant(String[] idJouets, Connection c) throws Exception {
    double total = 0;
    for (JouetLib e : chargerElements(idJouets, c)) {   // chaque élément avec le prix de son type
        total += e.getPrix();
    }
    return total;
    }

    public static Toy creerToy(String idClient, String idPopcorn, String[] idJouets,
                            String u, Connection c) throws Exception {
    boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); c.setAutoCommit(false); ouvert = true; }
        if (idJouets == null || idJouets.length == 0) throw new Exception("Choisissez au moins un élément.");

        Toy a = new Toy();                         // 1. la mère : seulement les choix de l'écran
        a.setIdclient(idClient);
        a.setIdpopcorn(idPopcorn);

        ClassFille[] lignes = new ClassFille[idJouets.length];
        for (int i = 0; i < idJouets.length; i++) {  // 2. une ligne par élément choisi
            ToyDetail d = new ToyDetail();         //    ni id, ni liaison, ni prix
            d.setIdelement(idJouets[i]);
            lignes[i] = d;
        }
        a.setFille(lignes);                            // 3. attacher

        a.createObject(u, c);                          // 4. TOUTES les règles + INSERT mère puis lignes

        if (ouvert) c.commit();
        return a;
    } catch (Exception e) {
        if (ouvert && c != null) c.rollback();
        throw e;
    } finally {
        if (ouvert && c != null) c.close();
    }
}

}
