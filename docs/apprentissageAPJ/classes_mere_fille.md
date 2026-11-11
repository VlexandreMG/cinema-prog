# Tuto — Les classes mère et fille (`ClassMere` / `ClassFille`)

Une **mère** est un document, une **fille** est une de ses lignes. Exemple du scénario 1 : une **réservation** (la mère) contient plusieurs **places réservées** (les filles).

Tout ce qui suit a été lu dans le code d'`apj-core.jar` (décompilé avec CFR) et vérifié dans le projet.

Prérequis : [creer_une_classe_apj.md](creer_une_classe_apj.md) (§6) et [createObject.md](createObject.md) (§3).

---

## 1. Quand utiliser une mère et des filles ?

Plusieurs tables ont une clé étrangère vers une autre, mais toutes ne sont pas des mères et des filles :

| Couple | Lien | Mère / fille ? | Pourquoi |
|---|---|---|---|
| `Salle` → `Place` | `Place.idsalle` | **non**, deux `ClassMAPTable` | les places sont créées une par une, à des moments différents ; la salle n'est pas un « document » qu'on enregistre avec elles |
| `Film` → `Seance` | `Seance.idfilm` | **non** | même raison |
| `Reservation` → `ReservationDetail` | `ReservationDetail.idreservation` | **oui** | la réservation et ses places sont **créées ensemble, en une fois**, et forment un tout : pas de réservation sans place, et un total calculé sur les lignes |

Utilise une mère et des filles quand **les trois** conditions sont vraies :
1. les lignes sont **enregistrées en même temps** que le document ;
2. une règle porte sur **l'ensemble** des lignes (au moins une ligne, pas de doublon, un total…) ;
3. le document a un **état** (créé, validé, annulé).

## 2. La hiérarchie des classes

```
ClassMAPTable          une table : id, INSERT, UPDATE, recherche
   └─ ClassUser        (infos de saisie : utilisateur, dates)
        └─ ClassEtat   + un état (1 = créé, 11 = validé, 0 = annulé) et validerObject
             ├─ ClassMere    + un tableau de lignes (fille), le nom de leur classe, la colonne de liaison
             └─ ClassFille   + le nom de la classe mère, la colonne de liaison, la mère elle-même
```

Ce que chacune garde (attributs lus dans le jar) :

| `ClassMere` | `ClassFille` |
|---|---|
| `ClassFille[] fille` : les lignes **en mémoire** | `ClassMere mere` : la mère de cette ligne |
| `String nomClasseFille` : `"reservation.ReservationDetail"` | `String nomClasseMere` : `"reservation.Reservation"` |
| `String liaisonFille` : `"idreservation"` | `String liaisonMere` : `"idreservation"` |

## 3. Le lien entre les deux : trois noms qui doivent correspondre

```
 Table RESERVATION                 Table RESERVATIONDETAIL
 ┌──────────────┐                  ┌───────────────────────┐
 │ id  RSV000004│◄─────────────────│ idreservation RSV00004│   ← la colonne de liaison
 │ ...          │     1 ──── *     │ idplace, prix         │
 └──────────────┘                  └───────────────────────┘
```

| Dans la mère (`Reservation`) | Dans la fille (`ReservationDetail`) | Doit être |
|---|---|---|
| `setNomClasseFille("reservation.ReservationDetail")` | — | le nom **complet** (package + classe) de la fille |
| — | `setNomClasseMere("reservation.Reservation")` + `getNomClasseMere()` | le nom complet de la mère |
| `setLiaisonFille("idreservation")` | `setLiaisonMere("idreservation")` + `getLiaisonMere()` | **le même nom de colonne**, qui existe dans la table de la **fille** et comme attribut de la classe fille |

La colonne de liaison est **dans la table de la fille** et contient l'id de la mère. La mère, elle, n'a aucune colonne qui pointe vers ses lignes.

## 4. Les squelettes

### La mère

```java
public class Reservation extends ClassMere {
    private String id;
    private String idclient;
    private String idseance;
    private java.sql.Date daty;
    private double montanttotal;
    private int etat;                      // ⚠ voir le piège du §9

    public Reservation() throws Exception {
        super.setNomTable("RESERVATION");
        this.setNomClasseFille("reservation.ReservationDetail");
        this.setLiaisonFille("idreservation");
    }

    @Override public void construirePK(Connection c) throws Exception {
        this.preparePk("RSV", "GETSEQRESERVATION");
        this.setId(makePK(c));
    }
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }

    // createObject : contrôles des lignes + calculs, puis super  (§6)
    // getters / setters de chaque attribut
}
```

### La fille

```java
public class ReservationDetail extends ClassFille {
    private String id;
    private String idreservation;          // la colonne de liaison
    private String idplace;
    private double prix;

    public ReservationDetail() throws Exception {
        super.setNomTable("RESERVATIONDETAIL");
        this.setNomClasseMere("reservation.Reservation");
        this.setLiaisonMere("idreservation");
    }

    @Override public void construirePK(Connection c) throws Exception {
        this.preparePk("RSD", "GETSEQRESERVATIONDETAIL");
        this.setId(makePK(c));
    }
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }
    @Override public String getNomClasseMere()  { return "reservation.Reservation"; }
    @Override public String getLiaisonMere()    { return "idreservation"; }

    // getters / setters de chaque attribut
}
```

### Les tables

```sql
CREATE TABLE RESERVATION (
  id VARCHAR2(100) PRIMARY KEY, ...,
  etat NUMBER DEFAULT 1                    -- la MÈRE a une colonne etat
);
CREATE TABLE RESERVATIONDETAIL (
  id            VARCHAR2(100) PRIMARY KEY,
  idreservation VARCHAR2(100) NOT NULL REFERENCES RESERVATION(id),   -- la liaison
  ...                                      -- pas besoin de colonne etat pour la fille
);
```

Chacune a **sa propre séquence et sa fonction** : voir [creer_une_sequence.md](creer_une_sequence.md).

**La fille n'a pas besoin de colonne `etat`.** APJ insère les attributs **déclarés dans ta classe**. Si la fille ne déclare pas d'attribut `etat`, il n'y a rien à insérer pour lui.

## 5. Les lignes en mémoire, et les lignes en base

C'est le point qui surprend le plus :

| Méthode | Ce qu'elle renvoie |
|---|---|
| `getFille()` (sans argument) | les lignes **en mémoire**, attachées avec `setFille(...)`. **`null`** si on n'en a pas attaché. **Elle ne lit pas la base.** |
| `getFille(nomTable, c, filtre)` | **recharge les lignes depuis la base** : les filles dont la colonne de liaison vaut l'id de la mère (`nomTable` peut être `null` ou une vue `_LIB` ; `filtre` peut être `""`) |
| `setFille(ClassFille[])` | attache des lignes à la mère, et donne à chaque ligne sa mère (`f.setMere(this)`) |

Donc :
- **à la création**, dans `createObject` de la mère, `this.getFille()` renvoie les lignes que **tu** as attachées : c'est ce qu'on veut contrôler ;
- **après coup**, sur une mère rechargée depuis la base (`CinemaUtil.parId(new Reservation(), id, c)`), `getFille()` vaut `null`. Pour avoir ses lignes : `getFille(null, c, "")`, ou une recherche directe comme `ReservationService.listerLignes`.

**Comment `getFille(nomTable, c, filtre)` filtre-t-il ?** Il crée une fille vide, met l'id de la mère dans la colonne de liaison, puis la passe à `CGenUtil.rechercher`. APJ ajoute au `where` **chaque attribut non vide** de l'objet passé en modèle. Ici, cela donne `idreservation = 'RSV000004'`.

**Le cast `(ReservationDetail[]) this.getFille()` est sûr.** `setFille` fabrique un tableau du type de la première ligne (`Array.newInstance`).

## 6. Créer une mère avec ses lignes

```java
// 1. La mère : seulement ce que l'écran fournit (ni id, ni total, ni état)
Reservation r = new Reservation();
r.setIdclient(idClient);
r.setIdseance(idSeance);

// 2. Les lignes : ni id, ni liaison (APJ les remplit), ni prix (calculé dans createObject)
ClassFille[] lignes = new ClassFille[idPlaces.length];
for (int i = 0; i < idPlaces.length; i++) {
    ReservationDetail d = new ReservationDetail();
    d.setIdplace(idPlaces[i]);
    lignes[i] = d;
}

// 3. Attacher, puis enregistrer
r.setFille(lignes);
r.createObject(u, c);       // contrôles → id de la mère → INSERT mère → pour chaque ligne :
                            //   liaison = id de la mère → controler() → id → INSERT
```

C'est exactement `ReservationService.reserver` ([03_fonctions_metier.md](../conception/03_fonctions_metier.md)). Le détail de ce que fait `createObject` pour une mère est dans [createObject.md](createObject.md) §3.

## 7. Où mettre les contrôles

| Je veux contrôler… | Où | Exemple |
|---|---|---|
| le document seul (client choisi, séance à venir) | `createObject` de la **mère**, avant `super` | `Reservation.createObject` |
| les lignes **ensemble** (au moins une, pas de doublon, total) | `createObject` de la **mère**, avec `this.getFille()`, avant `super` | « Choisissez au moins une place », « choisie deux fois » |
| chaque ligne, **avec des infos de la mère** (la place est dans la salle du film) | `createObject` de la **mère**, dans la boucle sur les lignes | c'est ce que fait `Reservation` |
| une ligne **seule**, sans besoin de la mère | `controler(Connection c)` de la **fille** | une quantité > 0 |
| ❌ | `createObject` de la **fille** | **jamais appelé** quand la ligne est créée par sa mère (elle passe par `createObjectBatch` → `controler`) |

Un calcul sur les lignes (le **prix recopié** dans chaque ligne, le **total** de la mère) se fait aussi dans le `createObject` de la mère, **avant** `super`.

## 8. Valider une mère

```java
// ClassMere
public Object validerObject(String u, Connection c) throws Exception {
    this.validerObjectFille(u, c);       // pour chaque ligne EN MÉMOIRE : f.validerObject(u, c)
    return super.validerObject(u, c);    // ClassEtat : etat = 11, puis UPDATE de la mère
}
```

- `ClassFille.validerObject` **ne fait rien** par défaut (il renvoie `null`). Valider une mère passe donc **la mère seule** à l'état 11, sauf si tu redéfinis `validerObject` dans la fille.
- Seules les lignes **en mémoire** sont parcourues (§5). Une mère rechargée par son id n'en a aucune.

Dans le scénario 1, on ne passe pas par la validation : la réservation est créée **directement validée** (`etat = 11`), parce qu'elle est payée tout de suite.

## 9. Dans le projet cinéma : créer par un service, pas par `apresMultiple.jsp`

Dans akoho, une mère et ses lignes se créent avec un formulaire `PageInsertMultiple`, qui poste vers `apresMultiple.jsp` → `UserEJB.createObjectMultiple(mere, colonneMere, filles)`.

**Cette voie n'existe pas dans le projet cinéma :**
- `apresMultiple.jsp` n'a pas été copiée à l'étape 1 (seulement la connexion et `module.jsp`) ;
- `createObjectMultiple` a été retirée de `UserEJB` / `UserEJBBean` en les allégeant ([étape 1](../etape1/00_vue_ensemble.md), sous-étape 4).

**Dans le cinéma, on crée une mère et ses lignes comme au §6**, depuis une fonction de service appelée par une page écrite à la main. C'est le modèle de `ReservationService.reserver` et des pages de [04_pages_reservation.md](../conception/04_pages_reservation.md).

## 10. Les pièges

| Symptôme | Cause | Solution |
|---|---|---|
| La mère est enregistrée, mais **aucune ligne**, sans erreur | `setFille(...)` oublié : `getFille()` vaut `null`, et `createObject` s'arrête après la mère | attacher les lignes avant `createObject` |
| `ORA-00904` sur le nom de la liaison | `setLiaisonFille` / `setLiaisonMere` ne correspondent pas à une colonne de la table **fille** | même nom partout (§3), et un attribut du même nom dans la fille |
| `ClassNotFoundException` | `setNomClasseFille` / `setNomClasseMere` sans le package, ou avec une faute | nom complet : `"reservation.ReservationDetail"` |
| Un contrôle mis dans la fille ne s'exécute jamais | il est dans `createObject` de la fille | le mettre dans `controler` de la fille, ou dans la mère (§7) |
| La mère est enregistrée avec `etat = 0` (= annulée) | elle déclare son propre `private int etat`, qui vaut 0 par défaut ; celui de `ClassEtat` (qui vaut 1) est un autre attribut | fixer l'état dans `createObject` (bug réel du scénario 1, voir [createObject.md](createObject.md) §7) |
| `getFille()` vaut `null` sur une mère chargée par son id | `getFille()` ne lit pas la base (§5) | `getFille(null, c, "")` ou une recherche sur la table des lignes |
| `ClassCastException` sur `(MaFille[]) getFille()` | des lignes de classes différentes attachées à la même mère | n'attacher que des objets de la classe fille |
| Valider la mère ne touche pas les lignes | `ClassFille.validerObject` ne fait rien (§8) | normal ; le redéfinir dans la fille si les lignes ont un état |

## 11. Checklist

1. ☐ Deux tables : la fille a la **colonne de liaison** vers l'id de la mère ; la mère a une colonne **`etat`**.
2. ☐ Deux séquences et deux fonctions `GETSEQ…`, deux préfixes différents.
3. ☐ Mère : `extends ClassMere`, `setNomClasseFille` (nom complet) + `setLiaisonFille`.
4. ☐ Fille : `extends ClassFille`, `setNomClasseMere` + `setLiaisonMere`, et `getNomClasseMere()` / `getLiaisonMere()` redéfinis.
5. ☐ Le nom de liaison est le même dans les deux classes, dans la table fille, et comme attribut de la fille.
6. ☐ Les contrôles des lignes et les calculs (prix recopié, total, état) sont dans le `createObject` de la **mère**, avant `super`.
7. ☐ Création par un service : mère + lignes **sans id ni liaison** → `setFille` → `createObject(u, c)`.
