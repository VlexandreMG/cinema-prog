package achat;

import bean.CGenUtil;
import bean.ClassMAPTable;
import constante.ConstanteEtat;
import film.Film;
import java.sql.Connection;
import java.sql.Date;
import utilitaire.Utilitaire;
import utils.CinemaUtil;

/**
 * L'achat des droits d'un film à un distributeur. Table ACHAT.
 * Un achat = un distributeur, UN film, un montant : pas de lignes (ClassMAPTable, pas ClassMere).
 *
 * Payé immédiatement : la SORTIE de caisse est faite par AchatService.acheterFilm, dans la même
 * transaction (CaisseService.decaisser). La règle « assez d'argent en caisse » n'est donc PAS ici :
 * elle est déjà dans MouvementCaisse.createObject (règle ⑤).
 */
public class Achat extends ClassMAPTable {

    private String id;
    private Date daty;
    private String iddistributeur;
    private String idfilm;          // un film n'est acheté qu'une fois (UNIQUE en base)
    private double montant;
    private int etat;               // 11 = payé ; 0 = annulé (plus tard)

    public Achat() {
        this.setNomTable("ACHAT");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("ACH", "GETSEQACHAT");   // -> ACH000001
        this.setId(makePK(c));
    }

    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ═══ RÈGLES (docs/conception/10_achat_film.md §6) ═══

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {

        // ── ① le distributeur existe ──
        CinemaUtil.parId(new Distributeur(), iddistributeur, c);

        // ── ② le film existe (créé juste avant, dans la même transaction) ──
        CinemaUtil.parId(new Film(), idfilm, c);

        // ── ③ le film n'a pas déjà été acheté (la base le garantit aussi : idfilm UNIQUE) ──
        Object n = CGenUtil.rechercherSimple("select count(*) from ACHAT where idfilm = '"
                + CinemaUtil.echapper(idfilm) + "'", c);
        if (n instanceof Number && ((Number) n).intValue() > 0) {
            throw new Exception("Le film " + idfilm + " a déjà été acheté.");
        }

        // ── ④ un montant positif ──
        if (montant <= 0) {
            throw new Exception("Le montant de l'achat doit être supérieur à 0.");
        }

        // ── ⑤ compléter : date du jour, état payé (fixé EXPLICITEMENT : sinon 0 = annulé) ──
        this.setDaty(Utilitaire.dateDuJourSql());
        this.setEtat(ConstanteEtat.getEtatValider());

        // ── ⑥ enregistrer ──
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public Date getDaty() { return daty; }
    public void setDaty(Date daty) { this.daty = daty; }
    public String getIddistributeur() { return iddistributeur; }
    public void setIddistributeur(String iddistributeur) { this.iddistributeur = iddistributeur; }
    public String getIdfilm() { return idfilm; }
    public void setIdfilm(String idfilm) { this.idfilm = idfilm; }
    public double getMontant() { return montant; }
    public void setMontant(double montant) { this.montant = montant; }
    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
