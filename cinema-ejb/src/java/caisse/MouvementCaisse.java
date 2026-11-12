package caisse;

import bean.CGenUtil;
import bean.ClassMAPTable;
import constante.ConstanteEtat;
import java.sql.Connection;
import java.sql.Date;
import utilitaire.Utilitaire;
import utils.CinemaUtil;

/**
 * Une entrée OU une sortie d'argent dans une caisse. Table MOUVEMENTCAISSE.
 *
 * FIGÉ : un mouvement n'est jamais modifié ni supprimé (une erreur se corrigera
 * par un mouvement inverse). La désignation est un texte RECOPIÉ
 * (« Facture n° 0003 — Rakoto Jean »).
 *
 * Exactement UN des deux montants est rempli : entree > 0 (ex. une facture payée)
 * ou sortie > 0 (ex. l'achat d'un film, plus tard).
 */
public class MouvementCaisse extends ClassMAPTable {

    private String id;
    private Date daty;
    private String idcaisse;
    private String designation;     // texte recopié
    private double entree;
    private double sortie;
    private String idorigine;       // la facture (ou l'achat) qui a causé le mouvement ; UNIQUE
    private int etat;               // 11 = validé ; 0 = annulé (plus tard)

    public MouvementCaisse() {
        this.setNomTable("MOUVEMENTCAISSE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("MVC", "GETSEQMOUVEMENTCAISSE");   // -> MVC000001
        this.setId(makePK(c));
    }

    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ═══ RÈGLES (docs/conception/09_caisse.md §6) ═══

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {

        // ── ① la caisse existe ──
        CinemaUtil.parId(new Caisse(), idcaisse, c);

        // ── ② exactement UN des deux montants est positif (la base le garantit aussi) ──
        boolean estEntree = entree > 0 && sortie == 0;
        boolean estSortie = sortie > 0 && entree == 0;
        if (!estEntree && !estSortie) {
            throw new Exception("Un mouvement de caisse est soit une entrée, soit une sortie, d'un montant positif.");
        }

        // ── ③ une désignation ──
        if (designation == null || designation.trim().isEmpty()) {
            throw new Exception("Un mouvement de caisse doit avoir une désignation.");
        }

        // ── ④ une origine n'est encaissée (ou décaissée) qu'une fois (la base le garantit aussi : UNIQUE) ──
        if (idorigine != null && !idorigine.trim().isEmpty()) {
            Object n = CGenUtil.rechercherSimple("select count(*) from MOUVEMENTCAISSE where idorigine = '"
                    + CinemaUtil.echapper(idorigine) + "'", c);
            if (n instanceof Number && ((Number) n).intValue() > 0) {
                throw new Exception("Le document " + idorigine + " a déjà un mouvement de caisse.");
            }
        }

        // ── ⑤ une SORTIE ne doit pas rendre le solde négatif ──
        if (estSortie) {
            // Verrou sur la caisse : deux sorties simultanées ne peuvent pas passer toutes les deux
            CGenUtil.rechercherSimple("select id from CAISSE where id = '"
                    + CinemaUtil.echapper(idcaisse) + "' for update", c);
            double solde = CaisseService.solde(idcaisse, c);        // calcul en Java
            if (solde - sortie < 0) {
                throw new Exception("Solde insuffisant : la caisse contient " + CinemaUtil.montant(solde)
                        + " Ar, impossible de sortir " + CinemaUtil.montant(sortie) + " Ar.");
            }
        }

        // ── ⑥ compléter : date du jour, état validé (fixé EXPLICITEMENT : sinon 0 = annulé) ──
        this.setDaty(Utilitaire.dateDuJourSql());
        this.setEtat(ConstanteEtat.getEtatValider());

        // ── ⑦ enregistrer ──
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public Date getDaty() { return daty; }
    public void setDaty(Date daty) { this.daty = daty; }
    public String getIdcaisse() { return idcaisse; }
    public void setIdcaisse(String idcaisse) { this.idcaisse = idcaisse; }
    public String getDesignation() { return designation; }
    public void setDesignation(String designation) { this.designation = designation; }
    public double getEntree() { return entree; }
    public void setEntree(double entree) { this.entree = entree; }
    public double getSortie() { return sortie; }
    public void setSortie(double sortie) { this.sortie = sortie; }
    public String getIdorigine() { return idorigine; }
    public void setIdorigine(String idorigine) { this.idorigine = idorigine; }
    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
