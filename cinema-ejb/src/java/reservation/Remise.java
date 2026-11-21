package reservation;

import bean.ClassMAPTable;
import java.sql.Connection;

public class Remise extends ClassMAPTable {

    // ① Un attribut par colonne, même nom
    private String id;
    private int nombre;
    private double valeur;
    private int catres;
    private int catrem;
    private int etat;

    // ② Le constructeur donne le nom de la table
    public Remise() {
        this.setNomTable("REMISE");
    }

    // ③ La clé : préfixe + fonction Oracle
    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("REM", "GETSEQREMISE");   // -> FLM000001, FLM000002...
        this.setId(makePK(c));
    }

    // ④ Dire à APJ quel attribut est la clé
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ⑤ Getters / setters pour CHAQUE attribut
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public int getNombre() { return nombre; }
    public void setNombre(int nombre) { this.nombre = nombre; }
    public double getValeur() { return valeur; }
    public void setValeur(double valeur) { this.valeur = valeur; }
    public int getCatres() { return catres; }
    public void setCatres(int catres) { this.catres = catres; }
    public int getCatrem() { return catrem; }
    public void setCatrem(int catrem) { this.catrem = catrem; }
    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
