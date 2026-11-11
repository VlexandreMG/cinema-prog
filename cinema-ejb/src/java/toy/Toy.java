package toy;

import bean.CGenUtil;
import bean.ClassMere;
import bean.ClassMAPTable;
import client.Client;
import constante.ConstanteEtat;
import java.sql.Connection;
import java.util.HashSet;
import java.util.Set;
import jouet.Jouet;
import jouet.TypeJouet;
import pop.Popcorn;
import utils.CinemaUtil;

/**
 * La vente de jouets d'un paquet de popcorn a un client. Table TOY (la mere).
 * Ses lignes sont les jouets vendus : TOYDETAIL (les filles), reliees par idtoy.
 *
 * Paiement immediat et complet : une vente enregistree est une vente payee (etat 11).
 * Un jouet vendu est pris POUR TOUJOURS (pas de notion de seance comme au scenario 1).
 */
public class Toy extends ClassMere {

    // ① Un attribut par colonne, même nom
    private String id;
    private String idclient;
    private String idpopcorn;       // le paquet choisi
    private double montanttotal;
    private int etat;               // 11 = validee (payee), 0 = annulee

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

    // ═══ CONTROLES ET CALCULS (la fonction "vendre") ═══

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {

        // ── ① CHARGER ce dont on a besoin (et vérifier que ça existe) ──
        CinemaUtil.parId(new Client(), idclient, c);                          // le client existe
        CinemaUtil.parId(new Popcorn(), idpopcorn, c);                        // le paquet existe
        // Verrou sur le paquet : deux ventes du même paquet en même temps → la 2e attend la 1re
        CGenUtil.rechercherSimple("select id from POPCORN where id = '"
                + CinemaUtil.echapper(idpopcorn) + "' for update", c);

        // ── ② RÈGLES SUR LE DOCUMENT : aucune (pas de date limite pour un paquet) ──

        // ── ③ AU MOINS UNE LIGNE ──
        ToyDetail[] lignes = (ToyDetail[]) this.getFille();
        if (lignes == null || lignes.length == 0) {
            throw new Exception("Choisissez au moins un jouet.");
        }

        // ── ④ POUR CHAQUE LIGNE : règles + prix recopié ──
        double total = 0;
        Set<String> dejaChoisis = new HashSet<String>();
        for (ToyDetail ligne : lignes) {
            Jouet jouet = (Jouet) CinemaUtil.parId(new Jouet(), ligne.getIdjouet(), c);

            if (!dejaChoisis.add(jouet.getId())) {                              // pas deux fois le même
                throw new Exception("Le jouet " + jouet.getLib() + " est choisi deux fois.");
            }
            if (!idpopcorn.equals(jouet.getIdpopcorn())) {                      // le bon paquet
                throw new Exception("Le jouet " + jouet.getLib() + " n'est pas dans ce paquet de popcorn.");
            }
            if (estVendu(jouet.getId(), c)) {                                   // encore disponible
                throw new Exception("Le jouet " + jouet.getLib() + " est déjà vendu.");
            }

            // Le prix vient du TYPE, lu en base (jamais de l'écran), et il est RECOPIÉ dans la ligne
            TypeJouet type = (TypeJouet) CinemaUtil.parId(new TypeJouet(), jouet.getIdtypejouet(), c);
            ligne.setPrix(type.getPrix());
            total += type.getPrix();
        }

        // ── ⑤ COMPLÉTER LA MÈRE ──
        this.setEtat(ConstanteEtat.getEtatValider());            // payée → VALIDÉE (sinon etat = 0 = annulée)
        this.setMontanttotal(total);                             // total = somme des lignes

        // ── ⑥ ENREGISTRER : la vente, puis ses lignes, dans la même transaction ──
        return super.createObject(u, c);
    }

    /**
     * Un jouet est vendu s'il est dans une ligne d'une vente NON ANNULEE.
     * Pris pour toujours : pas de condition de date ou de seance.
     */
    public static boolean estVendu(String idjouet, Connection c) throws Exception {
        String sql = "select count(*) from TOYDETAIL d"
                + " join TOY t on t.id = d.idtoy"
                + " where d.idjouet = '" + CinemaUtil.echapper(idjouet) + "'"
                + " and t.etat <> 0";
        Object o = CGenUtil.rechercherSimple(sql, c);
        return (o instanceof Number) && ((Number) o).intValue() > 0;
    }

    // ⑤ Getters / setters pour CHAQUE attribut
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getIdclient() { return idclient; }
    public void setIdclient(String idclient) { this.idclient = idclient; }
    public String getIdpopcorn() { return idpopcorn; }
    public void setIdpopcorn(String idpopcorn) { this.idpopcorn = idpopcorn; }
    public double getMontanttotal() { return montanttotal; }
    public void setMontanttotal(double montanttotal) { this.montanttotal = montanttotal; }
    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
