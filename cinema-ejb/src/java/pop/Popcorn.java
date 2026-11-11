package pop;

import bean.ClassMAPTable;
import java.sql.Connection;

public class Popcorn extends ClassMAPTable {

    // ① Un attribut par colonne, même nom
    private String id;
    private String nom;

    // ② Le constructeur donne le nom de la table
    public Popcorn() {
        this.setNomTable("POPCORN");
    }

    // ③ La clé : préfixe + fonction Oracle
    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("POP", "GETSEQPOP");   // -> POP000001, POP000002...
        this.setId(makePK(c));
    }

    // ④ Dire à APJ quel attribut est la clé
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ⑤ Getters / setters pour CHAQUE attribut
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
}
