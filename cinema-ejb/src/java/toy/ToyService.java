package toy;

import bean.CGenUtil;
import pop.Popcorn;
import jouet.Jouet;
import utilitaire.UtilDB;
import java.sql.Connection;
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

    public static Jouet[] listerJouetByPopcorn(String idPopcorn , Connection c) throws Exception {
    boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
        // « les éléments de CE conteneur »
        Object[] res = CGenUtil.rechercher(new Jouet(), null, null, c,
        " and idconteneur = '" + CinemaUtil.echapper(idPopcorn) + "' order by numero asc");
        return (Jouet[]) res;
    } finally {
        if (ouvert && c != null) c.close();
    }
}
}