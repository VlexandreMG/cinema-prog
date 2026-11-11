package toy;

import bean.CGenUtil;
import pop.Popcorn;
import utilitaire.UtilDB;
import java.sql.Connection;


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
}