package client;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Une personne qui reserve. Table CLIENT.
 * Pour rester simple, on choisit le client dans une liste deja remplie.
 */
public class Client extends ClassMAPTable {

    private String id;
    private String nom;
    private String contact;

    public Client() {
        this.setNomTable("CLIENT");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CLI", "GETSEQCLIENT");
        this.setId(makePK(c));
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (nom == null || nom.trim().isEmpty()) {
            throw new Exception("Le nom du client est obligatoire.");
        }
        return super.createObject(u, c);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getContact() { return contact; }
    public void setContact(String contact) { this.contact = contact; }
}
