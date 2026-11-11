package jouet;

import bean.ClassMAPTable;
import java.sql.Connection;

public class Jouet extends ClassMAPTable {

    // ① Un attribut par colonne, même nom
    private String id;
    private String libelle;
    private String idpopcorn;
    private String idtypejouet;

    // ② Le constructeur donne le nom de la table
    public Jouet() {
        this.setNomTable("JOUET");
    }

    // ③ La clé : préfixe + fonction Oracle
    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("JOT", "GETSEQJOUET");   // -> FLM000001, FLM000002...
        this.setId(makePK(c));
    }

    // ④ Dire à APJ quel attribut est la clé
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ⑤ Getters / setters pour CHAQUE attribut
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }
    public String getIdpopcorn() { return idpopcorn; }
    public void setIdpopcorn(String idpopcorn) { this.idpopcorn = idpopcorn; }
    public String getIdtypejouet() { return idtypejouet; }
    public void setIdtypejouet(String idtypejouet) { this.idtypejouet = idtypejouet; }
}
