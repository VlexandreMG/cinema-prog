import java.sql.Connection;
import reservation.*;

/**
 * Teste la réservation. Rien n'est gardé en base : tout est annulé à la fin.
 * Lancer : voir docs/apprentissageAPJ/tester_ses_fonctions.md §4
 */
public class TestReservation {

    public static void main(String[] args) throws Exception {
        Connection c = new utilitaire.UtilDB().GetConn();
        c.setAutoCommit(false);                          // ① rien ne sera validé...
        try {
            // ② retrouver les données PAR LEUR NOM, jamais par un id écrit en dur
            String client = (String) bean.CGenUtil.rechercherSimple(
                    "select min(id) from CLIENT", c);
            String seance = (String) bean.CGenUtil.rechercherSimple(
                    "select min(id) from SEANCE where heure = '17:00' and daty > sysdate", c);
            String place = ReservationService.listerPlacesLibres(seance, c)[0].getId();

            // ③ appeler la fonction testée, en passant la connexion c
            Reservation r = ReservationService.reserver(client, seance, new String[]{place}, "990001", c);

            // ④ afficher ce qu'on veut vérifier
            System.out.println("OK " + r.getId() + " total = " + r.getMontanttotal());

        } catch (Exception e) {
            System.out.println("ECHEC : " + e.getMessage());   // ⑤ le message de l'erreur
            e.printStackTrace();                               //    et OÙ elle est née
        } finally {
            c.rollback();                                      // ⑥ ...et tout est annulé
            c.close();
        }
    }
}
