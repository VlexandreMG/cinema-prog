# Tuto — Créer une classe métier avec APJ

Ce tuto montre comment passer d'une table à une classe Java APJ. Exemple fil rouge : **Film**, puis le couple **Reservation / ReservationDetail** pour un document avec des lignes.

Sources : la fiche mémo du projet akoho (`CHEAT-SHEET-APJ.md`) et les signatures lues dans `apj-core.jar` avec `javap`.

---

## 0. La règle d'APJ

> **Une classe = une table. Un attribut `private` = une colonne = un input à l'écran.**

APJ lit les attributs de ta classe (par réflexion) pour fabriquer tout seul le `INSERT`, le `SELECT` et les champs des formulaires. Tu écris seulement la structure et les contrôles.

## 1. Choisir la classe à hériter

| Ta table… | Hérite de | Exemple cinéma |
|---|---|---|
| est simple : pas de lignes, pas d'état | `bean.ClassMAPTable` | Salle, Film, Client |
| est un document **avec des lignes** (et un état) | `bean.ClassMere` | Reservation |
| est **une ligne** d'un document | `bean.ClassFille` | ReservationDetail |
| est une nomenclature `id, val, desce` | `bean.TypeObjet` | (une liste de genres, par exemple) |

## 2. Créer la table Oracle, sa séquence et sa fonction

```sql
CREATE TABLE FILM (
  id       VARCHAR2(100) PRIMARY KEY,
  titre    VARCHAR2(200) NOT NULL,
  duree    NUMBER(4)     NOT NULL,
  idsalle  VARCHAR2(100) NOT NULL REFERENCES SALLE(id)
);

CREATE SEQUENCE SEQ_FILM;
CREATE OR REPLACE FUNCTION GETSEQFILM RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_FILM.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/
```

- **`id` en `VARCHAR2`** : APJ fabrique des ids texte comme `FLM000001`.
- **La fonction est obligatoire.** APJ appelle `GETSEQFILM`, pas la séquence directement. Sans elle : `ORA-00904 "GETSEQFILM"`.
- **Noms de colonnes en minuscules et collés** (`idsalle`), identiques aux attributs Java.

Tout sur les séquences (comment APJ fabrique l'id, les trous, les erreurs, remettre une séquence en avance) : [creer_une_sequence.md](creer_une_sequence.md).

## 3. Écrire la classe

Fichier `cinema-ejb/src/java/film/Film.java`. Le dossier = le `package`.

```java
package film;

import bean.ClassMAPTable;
import java.sql.Connection;

public class Film extends ClassMAPTable {

    // ① Un attribut par colonne, même nom
    private String id;
    private String titre;
    private int duree;
    private String idsalle;

    // ② Le constructeur donne le nom de la table
    public Film() {
        this.setNomTable("FILM");
    }

    // ③ La clé : préfixe + fonction Oracle
    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("FLM", "GETSEQFILM");   // -> FLM000001, FLM000002...
        this.setId(makePK(c));
    }

    // ④ Dire à APJ quel attribut est la clé
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // ⑤ Getters / setters pour CHAQUE attribut
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }
    public int getDuree() { return duree; }
    public void setDuree(int duree) { this.duree = duree; }
    public String getIdsalle() { return idsalle; }
    public void setIdsalle(String idsalle) { this.idsalle = idsalle; }
}
```

Les 5 morceaux sont **obligatoires**. `getTuppleID` et `getAttributIDName` sont abstraites dans `ClassMAPTable` : sans elles, la classe ne compile pas.

⚠ **Le nom des getters / setters est imposé** : `get` + l'attribut avec seulement sa **première lettre** en majuscule. `nom` → `getNom()`, `idclient` → `getIdclient()` (pas `getIdClient()`). Un getter mal nommé compile, mais APJ ne le trouve pas et la valeur reste vide. Toutes les règles de nommage : [conventions_apj.md](conventions_apj.md).

### Les types d'attributs autorisés

| Colonne Oracle | Type Java |
|---|---|
| `VARCHAR2` | `String` |
| `NUMBER` entier | `int` |
| `NUMBER` décimal | `double` |
| `DATE` | `java.sql.Date` |

⚠ **Jamais `Integer` ni `Double`** : APJ plante (« Erreur durant la recherche pagine … null »).

### Ce qu'il ne faut pas mettre dans la classe

APJ prend les attributs pour des colonnes. Donc :
- **pas d'attribut qui n'est pas une colonne**, même `static final` : mets tes constantes ailleurs (ex. `utils/`) ;
- **pas de méthode de calcul nommée `getXxx`** si `xxx` n'est pas une colonne : nomme-la `calculerXxx` (ex. `Seance.calculerFin`).

## 4. Ajouter les contrôles

On redéfinit `createObject`, qui est appelée à l'enregistrement. On lance une `Exception` pour refuser : APJ annule la transaction et affiche le message.

```java
@Override
public ClassMAPTable createObject(String u, Connection c) throws Exception {
    if (titre == null || titre.trim().isEmpty()) {
        throw new Exception("Le titre du film est obligatoire.");
    }
    if (duree <= 0) {
        throw new Exception("La durée du film doit être supérieure à 0 minute.");
    }
    CinemaUtil.parId(new Salle(), idsalle, c);   // la salle doit exister
    return super.createObject(u, c);             // ← c'est ici que se fait l'INSERT
}
```

| Je veux contrôler… | Méthode à redéfinir |
|---|---|
| à la création | `createObject(String u, Connection c)` |
| une ligne seule (classe fille) | `controler(Connection c)` |
| à la validation (état → 11) | `validerObject(String u, Connection c)` |
| à la modification | `controlerUpdate(Connection c)` |

**N'oublie pas `return super.createObject(u, c);`** à la fin, sinon rien n'est enregistré.

Ce que fait `createObject` étape par étape, qui l'appelle, et ses pièges (lignes d'une mère, `etat`, transaction) : [createObject.md](createObject.md).

## 5. Lire d'autres tables dans un contrôle

```java
import bean.CGenUtil;

// Plusieurs lignes (4 arguments + connexion ; le filtre commence par " and ")
Object[] res = CGenUtil.rechercher(new Seance(), null, null, c, " and idfilm = 'FLM000001'");
Seance s = (Seance) res[0];

// Une seule valeur
Object o = CGenUtil.rechercherSimple("select count(*) from PLACE where idsalle = 'SAL000001'", c);
int nb = ((Number) o).intValue();

// Raccourci du projet : un enregistrement par son id (exception s'il n'existe pas)
Film f = (Film) CinemaUtil.parId(new Film(), "FLM000001", c);
```

- Toujours passer **`c`**, la connexion reçue par `createObject` : on reste dans la même transaction.
- ⚠ **Jamais `CGenUtil.rechercher(objet, " and ...")` à 2 arguments** : le 2ᵉ est pris pour un nom de table → `ORA-00903`.
- Pour coller une valeur dans du SQL, passe-la dans `CinemaUtil.echapper(...)` (qui double les `'`).

## 6. Un document avec des lignes : mère + fille

### La mère

```java
public class Reservation extends ClassMere {
    private String id, idclient, idseance;
    private java.sql.Date daty;
    private double montanttotal;
    private int etat;                      // une ClassMere a un état

    public Reservation() throws Exception {
        super.setNomTable("RESERVATION");
        this.setNomClasseFille("reservation.ReservationDetail");  // nom complet, avec le package
        this.setLiaisonFille("idreservation");                    // colonne des lignes qui pointe vers moi
    }
    // construirePK, getTuppleID, getAttributIDName, getters/setters : comme au §3
}
```

### La fille

```java
public class ReservationDetail extends ClassFille {
    private String id, idreservation, idplace;
    private double prix;

    public ReservationDetail() throws Exception {
        super.setNomTable("RESERVATIONDETAIL");
        this.setNomClasseMere("reservation.Reservation");
        this.setLiaisonMere("idreservation");
    }
    @Override public String getNomClasseMere() { return "reservation.Reservation"; }
    @Override public String getLiaisonMere()   { return "idreservation"; }
    // construirePK, getTuppleID, getAttributIDName, getters/setters : comme au §3
}
```

### Contrôler les lignes depuis la mère

```java
@Override
public ClassMAPTable createObject(String u, Connection c) throws Exception {
    ReservationDetail[] lignes = (ReservationDetail[]) this.getFille();
    if (lignes == null || lignes.length == 0) throw new Exception("Choisissez au moins une place.");
    double total = 0;
    for (ReservationDetail l : lignes) {
        // ... contrôles sur chaque ligne ...
        l.setPrix(prixDeLaPlace);          // on peut modifier les lignes avant l'INSERT
        total += prixDeLaPlace;
    }
    this.setMontanttotal(total);
    return super.createObject(u, c);       // INSERT de la mère, puis des lignes
}
```

Les trois noms doivent correspondre : `setNomClasseFille` ↔ nom de la classe fille, `setLiaisonFille` ↔ `setLiaisonMere` ↔ la colonne dans la table des lignes.

Tout sur les mères et les filles (quand en faire, lignes en mémoire / en base, où contrôler, validation, et pourquoi le cinéma passe par un service plutôt que par `apresMultiple.jsp`) : [classes_mere_fille.md](classes_mere_fille.md).

## 7. Écrire une fonction métier (un service)

Les classes décrivent les tables. Les fonctions dont l'écran a besoin (« lister les séances d'un film », « réserver ») vont dans une classe de service, par exemple [ReservationService.java](../../cinema-ejb/src/java/reservation/ReservationService.java).

Le mindset et la stratégie complète (lister, charger par id, disponibles, montant, enregistrer mère + lignes, tester sans page) : [fonctions_metier.md](fonctions_metier.md).

Le modèle du socle : la fonction reçoit une `Connection c`, et ouvre la sienne si `c` est `null`.

```java
// Une LECTURE
public static Seance[] listerSeances(String idFilm, Connection c) throws Exception {
    boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
        Object[] res = CGenUtil.rechercher(new Seance(), null, null, c,
                " and idfilm = '" + CinemaUtil.echapper(idFilm) + "' order by daty asc");
        return (Seance[]) res;          // sûr : APJ crée un tableau du bon type
    } finally {
        if (ouvert && c != null) c.close();   // je ferme seulement ce que j'ai ouvert
    }
}

// Une ÉCRITURE : en plus, commit / rollback si c'est moi qui ai ouvert
public static Reservation reserver(..., String u, Connection c) throws Exception {
    boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); c.setAutoCommit(false); ouvert = true; }
        Reservation r = new Reservation();
        // ... remplir r, puis r.setFille(lignes) ...
        r.createObject(u, c);           // les contrôles sont dans la classe, pas ici
        if (ouvert) c.commit();
        return r;
    } catch (Exception e) {
        if (ouvert && c != null) c.rollback();
        throw e;
    } finally {
        if (ouvert && c != null) c.close();
    }
}
```

- **Les contrôles restent dans `createObject`** : ils s'appliquent ainsi quel que soit le chemin (service ou moteur APJ).
- Le filtre peut se terminer par `order by …` : APJ le colle à la fin de `select * from TABLE where … `.
- Pour afficher des libellés (nom de la salle, prix du type), on fait une **vue `_LIB`** et une classe qui la lit (ex. `PLACE_LIB` → `PlaceLib`).

## 8. Vérifier que ça compile

**Après CHAQUE fichier**, pas à la fin :

```bash
cd /home/balou/S5/MrTahina/cinema
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant compile
```
`BUILD SUCCESSFUL` en 2 secondes = c'est bon. Sinon, l'erreur donne le fichier et la ligne. Pour déployer : `ant` (sans argument).

⚠ Si un seul fichier ne compile pas, **tout** le projet ne peut plus être déployé, y compris les modules qui marchaient. Après un copier-coller depuis un modèle, voir aussi la checklist de [conventions_apj.md](conventions_apj.md) §10.

## 9. Checklist pour une nouvelle table

1. ☐ Table Oracle (`id VARCHAR2` + colonnes en minuscules)
2. ☐ Séquence `SEQ_X` + **fonction** `GETSEQX`
3. ☐ Classe dans le bon package, qui hérite de la bonne classe APJ (§1)
4. ☐ Un attribut par colonne, types simples, même nom
5. ☐ Constructeur avec `setNomTable` (+ liaison mère/fille si besoin)
6. ☐ `construirePK`, `getTuppleID`, `getAttributIDName`
7. ☐ Getters / setters pour chaque attribut
8. ☐ Contrôles dans `createObject`, terminés par `return super.createObject(u, c);`
9. ☐ Ajouter la table au script `database/` et compiler

## 10. Les erreurs fréquentes

| Symptôme | Cause | Solution |
|---|---|---|
| `ORA-00904 "GETSEQX"` | la fonction n'existe pas | créer `SEQ_X` + `GETSEQX` (§2) |
| `ORA-00903` | `CGenUtil.rechercher` à 2 arguments | la version à 4 ou 5 arguments (§5) |
| « Erreur durant la recherche pagine … null » | un attribut `Integer` / `Double` | `int` / `double` |
| `ORA-00904` sur une colonne inconnue | un attribut sans colonne dans la table | ajouter la colonne, ou retirer l'attribut |
| rien n'est enregistré, pas d'erreur | `super.createObject` oublié | `return super.createObject(u, c);` |
| les lignes ne s'enregistrent pas | noms de liaison différents entre mère et fille | vérifier les trois noms (§6) |
