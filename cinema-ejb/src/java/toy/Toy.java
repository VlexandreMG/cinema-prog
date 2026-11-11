package toy;

import bean.ClassMere;
import bean.ClassMAPTable;
import java.sql.Connection;

public class Toy extends ClassMere {

    // ① Un attribut par colonne, même nom
    private String id;
    private String idclient;
    private double montanttotal;

    // ② Le constructeur : la table + le lien vers les lignes
    public Toy() throws Exception {
        super.setNomTable("TOY");
        this.setNomClasseFille("toy.ToyDetail");
        this.setLiaisonFille("idtoy");          // la colonne de TOYDETAIL qui pointe vers moi
    }

    // ③ La clé : préfixe + fonction Oracle
    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("TOY", "GETSEQTOY");   // -> TOY000001, TOY000002...
        this.setId(makePK(c));
    }

    // ④ Dire à APJ quel attribut est la clé
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }


    // ⑤ Getters / setters pour CHAQUE attribut
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getIdclient() { return idclient; }
    public void setIdclient(String idclient) { this.idclient = idclient; }
    public double getMontanttotal() { return montanttotal; }
    public void setMontanttotal(double montanttotal) { this.montanttotal = montanttotal; }
}
