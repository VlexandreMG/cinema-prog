package facture;

import bean.ClassFille;
import java.sql.Connection;

/**
 * Une ligne de facture. Table FACTUREDETAIL.
 * FIGEE : la désignation et le prix sont RECOPIÉS au moment de la facture
 * (« Dune 3 — 11/11/2026 18:00 — Salle 1 — Place E8 (VIP) », 25 000).
 */
public class FactureDetail extends ClassFille {

    private String id;
    private String idfacture;       // la colonne de liaison
    private String designation;     // texte recopié
    private double prix;            // prix PAYÉ, recopié de RESERVATIONDETAIL

    public FactureDetail() throws Exception {
        super.setNomTable("FACTUREDETAIL");
        this.setNomClasseMere("facture.Facture");
        this.setLiaisonMere("idfacture");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("FAD", "GETSEQFACTUREDETAIL");   // -> FAD000001
        this.setId(makePK(c));
    }

    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }
    @Override public String getNomClasseMere()  { return "facture.Facture"; }
    @Override public String getLiaisonMere()    { return "idfacture"; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getIdfacture() { return idfacture; }
    public void setIdfacture(String idfacture) { this.idfacture = idfacture; }
    public String getDesignation() { return designation; }
    public void setDesignation(String designation) { this.designation = designation; }
    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
