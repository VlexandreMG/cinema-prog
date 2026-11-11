package jouet;

import bean.ClassMAPTable;

public class JouetLib extends ClassMAPTable {

    // ① Un attribut par colonne, même nom
    private String id;
    private String lib;
    private String nom;
    private double prix;

    // ② Le constructeur donne le nom de la table
    public JouetLib() {
        this.setNomTable("JOUET_LIB");
    }

    // ④ Dire à APJ quel attribut est la clé
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ⑤ Getters / setters pour CHAQUE attribut
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getLib() { return lib; }
    public void setLib(String lib) { this.lib = lib; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
