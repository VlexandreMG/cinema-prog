package toy;

import bean.ClassMAPTable;

/**
 * Un jouet vendu avec son nom et son type. Lecture seule : vue TOYDETAIL_LIB.
 * Le prix est celui PAYE (recopie dans TOYDETAIL), pas le prix actuel du type.
 */
public class ToyDetailLib extends ClassMAPTable {

    private String id;
    private String idtoy;
    private String idjouet;
    private String lib;             // nom du jouet
    private String typejouet;       // libellé du type
    private double prix;            // prix payé

    public ToyDetailLib() {
        this.setNomTable("TOYDETAIL_LIB");
    }

    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getIdtoy() { return idtoy; }
    public void setIdtoy(String idtoy) { this.idtoy = idtoy; }
    public String getIdjouet() { return idjouet; }
    public void setIdjouet(String idjouet) { this.idjouet = idjouet; }
    public String getLib() { return lib; }
    public void setLib(String lib) { this.lib = lib; }
    public String getTypejouet() { return typejouet; }
    public void setTypejouet(String typejouet) { this.typejouet = typejouet; }
    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
