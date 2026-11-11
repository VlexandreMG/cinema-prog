# Tuto — Quand faire une vue `_LIB` (et sa classe `Lib`)

Par convention APJ, une table `XXX` peut avoir une **vue `XXX_LIB`** (et une classe `XxxLib` qui la lit) : la même chose que la table, **plus des libellés et des valeurs calculées**, prête à être affichée.

Ce tuto dit **quand en faire une, quand c'est inutile, et comment**. Il s'appuie sur le projet d'origine (akoho : 171 classes `…Lib`, 52 `…Cpl`) et sur le scénario 1.

---

## 1. Le problème qu'elle résout

La table `PLACE` contient des **ids** :

| id | idsalle | numero | idtypeplace |
|---|---|---|---|
| PLC000041 | SAL000001 | E8 | TPL000002 |

L'écran, lui, veut afficher des **libellés** :

| Place | Salle | Type | Prix |
|---|---|---|---|
| E8 | Salle 1 | VIP | 25 000 |

Pour passer de l'un à l'autre, il faut **joindre** `PLACE` avec `SALLE` et `TYPEPLACE`. APJ ne sait lire qu'**une table ou une vue par classe** (`select * from <nomTable> where …`). On met donc la jointure dans une **vue**, et une classe lit cette vue :

```sql
CREATE OR REPLACE VIEW PLACE_LIB AS
SELECT p.id, p.idsalle, s.nom AS salle, p.numero,
       p.idtypeplace, t.libelle AS typeplace, t.prix
FROM PLACE p
JOIN SALLE s     ON s.id = p.idsalle
JOIN TYPEPLACE t ON t.id = p.idtypeplace;
```

Sans vue, il faudrait faire une requête par ligne (charger la salle, puis le type…). Avec 40 places, ça fait 80 requêtes au lieu d'une.

## 2. La règle de décision

> **Écrire → la classe de base (la table). Afficher → la `Lib` (la vue).**

Une `Lib` est **en lecture seule** : on ne fait jamais d'`INSERT` dans une vue.

### Tu as besoin d'une `Lib` quand…

| Situation | Exemple réel |
|---|---|
| une **liste** (`PageRecherche`) doit montrer un libellé au lieu d'un id | akoho `receptionusine-liste.jsp` → `new ReceptionUsineLib()` |
| une **fiche** (`PageConsulte`) affiche le document avec ses libellés | akoho `receptionusine-fiche.jsp` → `new ReceptionUsineLib()` |
| l'onglet des **lignes** d'une fiche affiche les lignes avec leurs libellés | akoho `inc/receptionusine-details.jsp` → `new ReceptionUsineDetailLib()` |
| une **fonction de service** renvoie des objets prêts à afficher | cinéma : `listerPlacesLibres` → `PlaceLib[]` (numéro, type, prix) |
| l'écran montre une **valeur calculée** (somme, compte, différence) | akoho `RECEPTIONUSINE_LIB` : `nbmort`, `nbperdu`, `nbvivant` ; cinéma `RESERVATION_LIB` |
| on veut **chercher ou filtrer par un libellé** (le nom du client) plutôt que par un id | un critère de recherche sur `client` dans une liste |
| un **prix vient d'une autre table** et doit s'afficher à côté de l'élément | cinéma : le `prix` du type dans `PLACE_LIB` |

### Tu n'en as PAS besoin quand…

| Situation | Pourquoi |
|---|---|
| une **saisie** (`PageInsert`, `PageInsertMultiple`) | on écrit dans la table : on utilise la classe de base |
| un **contrôle** dans `createObject` | on vérifie avec les classes de base (`CinemaUtil.parId(new Place(), …)`) |
| une **liste déroulante** (`Liste`) | elle choisit elle-même la colonne affichée : `new Liste("idsalle", new Salle(), "nom", "id")` |
| l'écran n'affiche **que des colonnes de la table** | la liste des clients (nom, contact) : la table `CLIENT` suffit |
| le libellé sert **une seule fois**, pour un seul objet | un `parId` suffit (par exemple, le nom du client dans un récapitulatif) |

### La question à se poser

```
Est-ce que j'ÉCRIS ?                         → classe de base, pas de Lib
Sinon : est-ce que j'affiche autre chose
que les colonnes de la table ?
  (libellé d'une autre table, calcul, prix du type)
        non → classe de base
        oui → plusieurs lignes ou une liste ?   → une vue _LIB
              un seul objet, une seule fois ?   → parId peut suffire
```

## 3. Les deux façons d'écrire la classe

### Façon akoho : la `Lib` **hérite** de la classe de base

```java
public class ReceptionUsineLib extends ReceptionUsine {   // reprend TOUS les attributs de la table
    private String idlotlib, etatlib;                     // + les libellés
    private double qteattendue, nbmort, nbperdu, nbvivant; // + les calculs

    public ReceptionUsineLib() throws Exception {
        super();
        super.setNomTable("RECEPTIONUSINE_LIB");          // mais lit la VUE
    }
    // getters / setters des attributs ajoutés
}
```
- **Avantage** : on écrit seulement ce qui est en plus.
- **Contrainte** : la vue doit contenir **toutes** les colonnes de la table, plus les ajouts.
- **Danger** : la `Lib` hérite aussi de `createObject` et des contrôles. Ne **jamais** l'enregistrer.

### Façon cinéma : la `Lib` est **indépendante**

```java
public class PlaceLib extends ClassMAPTable {   // seulement ce que l'écran affiche
    private String id, idsalle, salle, numero, idtypeplace, typeplace;
    private double prix;
    public PlaceLib() { this.setNomTable("PLACE_LIB"); }
    @Override public String getTuppleID()       { return id; }
    @Override public String getAttributIDName() { return "id"; }
    // getters / setters
}
```
- **Avantage** : aucun risque de l'enregistrer par erreur, et la vue ne contient que l'utile.
- **Contrainte** : on réécrit tous les attributs.

**Laquelle choisir ?** La façon akoho quand la `Lib` est « la table, en plus lisible », pour une liste ou une fiche APJ. La façon indépendante quand c'est un **mélange de plusieurs tables** pour un écran précis (`PlaceLib`, `ReservationLib`). Les deux marchent : choisis-en une et reste cohérent.

## 4. Les conventions

| Quoi | Convention | Exemples |
|---|---|---|
| nom de la vue | `<TABLE>_LIB` | `PLACE_LIB`, `RESERVATION_LIB`, `RECEPTIONUSINE_LIB` |
| nom de la classe | `<Classe>Lib`, dans le même package | `salle.PlaceLib`, `reservation.ReservationLib` |
| colonne `id` | **obligatoire**, c'est l'id de la table de base | `p.id` |
| colonnes de la table | gardées avec le **même nom** | `idsalle`, `numero` |
| libellé d'une clé étrangère | akoho : `<colonne>lib` ; cinéma : un nom court | `idlotlib`, `etatlib` / `salle`, `typeplace` |
| vue « encore plus complète » | `…_CPL` (complet), classe `…Cpl` | akoho : `VENTE_DETAILS_CPL` |
| pour les lignes d'une mère | `<TABLEFILLE>_LIB`, avec la colonne de liaison | `RESERVATIONDETAIL_LIB` (avec `idreservation`) |

## 5. Comment en faire une, pas à pas

1. **Écris ce que l'écran affiche**, colonne par colonne : « numéro, salle, type, prix ».
2. **Pour chaque colonne, trouve sa table** : `numero` est dans PLACE, `salle` dans SALLE, `type` et `prix` dans TYPEPLACE.
3. **Écris la vue** : `FROM` la table de base, `JOIN` une fois par table de libellé ; garde `id` et les ids utiles pour filtrer (`idsalle`).
4. **Teste la vue seule** dans SQL*Plus : `SELECT * FROM PLACE_LIB WHERE idsalle = 'SAL000001';`. Vérifie le **nombre de lignes**, qui doit être le même que dans la table de base.
5. **Écris la classe** : un attribut par colonne de la vue, avec le même nom, et des types simples.
6. **Ajoute la vue au script SQL**, après les tables qu'elle utilise.

## 6. Les pièges

| Symptôme | Cause | Solution |
|---|---|---|
| Des lignes **disparaissent** de la liste | `JOIN` alors que la clé étrangère peut être vide : la ligne n'a pas de partenaire | `LEFT JOIN` pour les colonnes facultatives |
| Des lignes **en double** | jointure vers une table « plusieurs » (une mère jointe à ses lignes) | joindre seulement vers le côté « un », ou regrouper (`GROUP BY` / sous-requête) pour un total |
| La liste plante après l'ajout d'une colonne à la table | façon akoho : la `Lib` hérite du nouvel attribut, mais la vue ne l'a pas | ajouter la colonne **aussi dans la vue** |
| `ORA-00942` à l'affichage | la vue n'a pas été créée (script pas relancé) | créer la vue |
| Une erreur en enregistrant | on a fait `createObject` sur une `Lib` : `INSERT` dans une vue | enregistrer avec la classe de base, afficher avec la `Lib` |
| La fiche affiche un **prix différent** de celui payé | la vue des lignes lit le prix **du type** (actuel) au lieu du prix **recopié** dans la ligne | dans la vue des lignes, prendre `d.prix` (comme `RESERVATIONDETAIL_LIB`) |
| La recherche par id ne trouve rien | la vue n'a pas de colonne `id`, ou elle contient un autre id | `id` = l'id de la table de base |

## 7. Les `Lib` du scénario 1

| Vue | Classe | Utilisée par | Ce qu'elle ajoute |
|---|---|---|---|
| `PLACE_LIB` | `salle.PlaceLib` | `listerPlacesLibres`, `chargerPlaces`, `calculerMontant` | nom de la salle, libellé et **prix actuel** du type |
| `RESERVATION_LIB` | `reservation.ReservationLib` | `chargerReservation` (fiche) | nom du client, titre du film, salle, date et heure de la séance |
| `RESERVATIONDETAIL_LIB` | `reservation.ReservationDetailLib` | `listerLignes` (fiche) | numéro et type de la place, **prix payé** |

Et ce qui n'a **pas** de `Lib` : `CLIENT`, `FILM`, `SEANCE` (les listes n'affichent que leurs propres colonnes), et tout ce qui est enregistré (`Reservation`, `ReservationDetail`).

## 8. Checklist

1. ☐ Je n'utilise la `Lib` que pour **afficher** ; j'enregistre avec la classe de base.
2. ☐ La vue s'appelle `<TABLE>_LIB`, la classe `<Classe>Lib`.
3. ☐ La vue a une colonne `id` (celle de la table de base) et les ids utiles pour filtrer.
4. ☐ `LEFT JOIN` pour les clés étrangères facultatives.
5. ☐ Même nombre de lignes que la table de base (pas de doublons, pas de disparus).
6. ☐ Pour les lignes d'un document : le **prix payé** de la ligne, pas le prix actuel.
7. ☐ Façon akoho : la vue contient **toutes** les colonnes de la table.
8. ☐ La vue est dans le script SQL, après ses tables.
