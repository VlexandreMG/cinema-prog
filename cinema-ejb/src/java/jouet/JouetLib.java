package jouet;

import bean.ClassMAPTable;

public class JouetLib extends ClassMAPTable {

    // ① Un attribut par colonne, même nom
    private String id;
    private String lib;
    private String idpopcorn;       // pour filtrer "les jouets de CE paquet"
    private String nom;             // le nom du paquet de popcorn
    private String idtypejouet;
    private String typejouet;       // le libellé du type (Classique, Collector...)
    private double prix;            // le prix ACTUEL du type

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
    public String getIdpopcorn() { return idpopcorn; }
    public void setIdpopcorn(String idpopcorn) { this.idpopcorn = idpopcorn; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getIdtypejouet() { return idtypejouet; }
    public void setIdtypejouet(String idtypejouet) { this.idtypejouet = idtypejouet; }
    public String getTypejouet() { return typejouet; }
    public void setTypejouet(String typejouet) { this.typejouet = typejouet; }
    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
}
