package jouet;

import bean.ClassMAPTable;
import java.sql.Connection;

public class TypeJouet extends ClassMAPTable {

    // ① Un attribut par colonne, même nom
    private String id;
    private String lib;
    private double prix;

    // ② Le constructeur donne le nom de la table
    public TypeJouet() {
        this.setNomTable("TYPEJOUET");
    }

    // ③ La clé : préfixe + fonction Oracle
    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("TPJ", "GETSEQTYPEJOUET");   // -> TPJ000001, TPJ000002...
        this.setId(makePK(c));
    }

    // ④ Dire à APJ quel attribut est la clé
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ⑤ Getters / setters pour CHAQUE attribut
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getLib() { return lib; }
    public void setLib(String lib) { this.lib = lib; }
    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
