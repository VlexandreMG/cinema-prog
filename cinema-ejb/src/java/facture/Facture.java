package facture;

import bean.CGenUtil;
import bean.ClassMAPTable;
import bean.ClassMere;
import constante.ConstanteEtat;
import java.sql.Connection;
import java.sql.Date;
import reservation.Reservation;
import utilitaire.Utilitaire;
import utils.CinemaUtil;

/**
 * La facture client d'une réservation payée. Table FACTURE (la mère).
 * Ses lignes : FACTUREDETAIL (les filles), reliées par idfacture.
 *
 * La facture est la PREUVE DU PAIEMENT : elle est FIGÉE. Le nom du client, l'objet
 * (film, séance, salle) et chaque désignation sont RECOPIÉS en texte : elle s'affiche
 * sans jointure et ne change jamais, même si le client, le film ou la place changent.
 *
 * Deux numéros :
 *   - id     (FAC000001) : technique, par séquence (des trous sont possibles) ;
 *   - numero (0001/2026) : LÉGAL, continu, sans trou, par année (FactureService.prochainNumero).
 */
public class Facture extends ClassMere {

    private String id;
    private String numero;          // 0001/2026
    private Date daty;              // date d'émission
    private String idclient;
    private String client;          // nom recopié
    private String idreservation;   // une seule facture par réservation (UNIQUE en base)
    private String objet;           // « Dune 3 — 11/11/2026 18:00 — Salle 1 »
    private double montanttotal;
    private int etat;               // 11 = émise ; 0 = annulée (plus tard, par un avoir)

    public Facture() throws Exception {
        super.setNomTable("FACTURE");
        this.setNomClasseFille("facture.FactureDetail");
        this.setLiaisonFille("idfacture");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("FAC", "GETSEQFACTURE");   // -> FAC000001
        this.setId(makePK(c));
    }

    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ═══ RÈGLES (docs/conception/08_facture_client.md §8) ═══

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {

        // ── ① la réservation existe, et elle est validée (payée) ──
        Reservation reservation = (Reservation) CinemaUtil.parId(new Reservation(), idreservation, c);
        if (reservation.getEtat() < ConstanteEtat.getEtatValider()) {
            throw new Exception("La réservation " + idreservation + " n'est pas payée : facture impossible.");
        }

        // ── ② elle n'a pas déjà de facture (la base le garantit aussi : idreservation UNIQUE) ──
        Object dejaFacturee = CGenUtil.rechercherSimple("select count(*) from FACTURE where idreservation = '"
                + CinemaUtil.echapper(idreservation) + "'", c);
        if (dejaFacturee instanceof Number && ((Number) dejaFacturee).intValue() > 0) {
            throw new Exception("La réservation " + idreservation + " a déjà une facture.");
        }

        // ── ③ au moins une ligne ──
        FactureDetail[] lignes = (FactureDetail[]) this.getFille();
        if (lignes == null || lignes.length == 0) {
            throw new Exception("Une facture doit avoir au moins une ligne.");
        }

        // ── ④ total = somme des lignes, ET = total de la réservation ──
        double total = 0;
        for (FactureDetail ligne : lignes) {
            if (ligne.getDesignation() == null || ligne.getDesignation().trim().isEmpty()) {
                throw new Exception("Une ligne de facture n'a pas de désignation.");
            }
            total += ligne.getPrix();
        }
        if (Math.abs(total - reservation.getMontanttotal()) > 0.001) {
            throw new Exception("Incohérence : total des lignes (" + CinemaUtil.montant(total)
                    + ") différent du total de la réservation (" + CinemaUtil.montant(reservation.getMontanttotal()) + ").");
        }

        // ── ⑤ compléter : client, numéro légal, date, état ──
        this.setIdclient(reservation.getIdclient());
        this.setDaty(Utilitaire.dateDuJourSql());
        this.setNumero(FactureService.prochainNumero(c));     // calcul en Java, compteur verrouillé
        this.setMontanttotal(total);
        this.setEtat(ConstanteEtat.getEtatValider());         // émise (sinon etat = 0 = annulée)

        // ── ⑥ enregistrer : la facture, puis ses lignes, dans la transaction de l'appelant ──
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getNumero() { return numero; }
    public void setNumero(String numero) { this.numero = numero; }
    public Date getDaty() { return daty; }
    public void setDaty(Date daty) { this.daty = daty; }
    public String getIdclient() { return idclient; }
    public void setIdclient(String idclient) { this.idclient = idclient; }
    public String getClient() { return client; }
    public void setClient(String client) { this.client = client; }
    public String getIdreservation() { return idreservation; }
    public void setIdreservation(String idreservation) { this.idreservation = idreservation; }
    public String getObjet() { return objet; }
    public void setObjet(String objet) { this.objet = objet; }
    public double getMontanttotal() { return montanttotal; }
    public void setMontanttotal(double montanttotal) { this.montanttotal = montanttotal; }
    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
