package toy;

import bean.ClassMAPTable;

/**
 * Une vente de jouets avec le nom du client et du paquet. Lecture seule : vue TOY_LIB.
 * Sert a la fiche (popcorn-fiche.jsp).
 */
public class ToyLib extends ClassMAPTable {

    private String id;
    private String idclient;
    private String client;          // nom du client
    private String idpopcorn;
    private String popcorn;         // nom du paquet
    private double montanttotal;
    private int etat;

    public ToyLib() {
        this.setNomTable("TOY_LIB");
    }

    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getIdclient() { return idclient; }
    public void setIdclient(String idclient) { this.idclient = idclient; }
    public String getClient() { return client; }
    public void setClient(String client) { this.client = client; }
    public String getIdpopcorn() { return idpopcorn; }
    public void setIdpopcorn(String idpopcorn) { this.idpopcorn = idpopcorn; }
    public String getPopcorn() { return popcorn; }
    public void setPopcorn(String popcorn) { this.popcorn = popcorn; }
    public double getMontanttotal() { return montanttotal; }
    public void setMontanttotal(double montanttotal) { this.montanttotal = montanttotal; }
    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
