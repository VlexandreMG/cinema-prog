package toy;

import bean.ClassFille;
import java.sql.Connection;

public class ToyDetail extends ClassFille {
    private String id;
    private String idtoy;          // la colonne de liaison
    private String idjouet;
    private double prix;

    public ToyDetail() throws Exception {
        super.setNomTable("TOYDETAIL");
        this.setNomClasseMere("toy.Toy");
        this.setLiaisonMere("idtoy");
    }

    @Override public void construirePK(Connection c) throws Exception {
        this.preparePk("TOD", "GETSEQTOYDETAIL");
        this.setId(makePK(c));
    }
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }
    @Override public String getNomClasseMere()  { return "toy.Toy"; }
    @Override public String getLiaisonMere()    { return "idreservation"; }

    // getters / setters de chaque attribut
     public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdtoy() { return idtoy; }
    public void setIdtoy(String idtoy) { this.idtoy = idtoy; }

    public String getIdjouet() { return idjouet; }
    public void setIdjouet(String idjouet) { this.idjouet = idjouet; }

    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}