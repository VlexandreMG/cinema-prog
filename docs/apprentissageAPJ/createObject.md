# Tuto — À quoi sert vraiment `createObject`

`createObject` est **la méthode qui enregistre un objet en base** (l'`INSERT`). C'est aussi **le point d'accroche de tes contrôles** : tu la redéfinis pour vérifier et calculer avant que l'objet soit écrit.

Tout ce qui suit a été lu dans le code d'`apj-core.jar` (décompilé avec CFR) et dans le projet. Les exemples viennent du scénario 1.

Prérequis : [creer_une_classe_apj.md](creer_une_classe_apj.md) (§4 et §6) et [creer_une_sequence.md](creer_une_sequence.md).

---

## 1. Qui appelle `createObject` ?

Deux chemins mènent à elle.

### Chemin A — le moteur APJ (formulaire `PageInsert` / `PageInsertMultiple`)

```
xxx-saisie.jsp  ──POST──►  apresMultiple.jsp
                              │
                              ▼
               UserEJBBean.createObject(o)          ← ouvre une connexion, autoCommit=false
                 │  vérifie les droits : ActionRole "insert", rang de l'utilisateur ≥ 1
                 ▼
               CreateObject.createObject(o, c, ...)   ← remplit iduser si l'objet est un ClassEtat
                 ▼
               o.createObject(idUtilisateur, c)     ← TA méthode
                 ▼
               commit    (ou rollback si une exception est lancée)
```

### Chemin B — notre service (`ReservationService.reserver`)

```
reservation-paiement.jsp
   ▼
ReservationService.reserver(..., u, c)    ← ouvre la connexion, autoCommit=false
   ▼
r.createObject(u, c)                      ← TA méthode
   ▼
commit    (ou rollback)
```

**Dans les deux cas, ce n'est pas `createObject` qui ouvre la connexion ni qui fait le `commit`.** Elle reçoit une connexion `c` déjà ouverte, et c'est l'appelant qui valide ou annule le tout.

## 2. Ce que fait `createObject` dans `ClassMAPTable` (une table simple)

Le vrai code, simplifié :

```java
public ClassMAPTable createObject(String u, Connection c) throws Exception {
    this.controler(c);                              // ① contrôle (vide par défaut)
    // (notification, si un message est prévu)
    if (id vide ou "0") this.construirePK(c);       // ② fabrique l'id : SAL000001
    this.insertToTableWithHisto(u, c);              // ③ INSERT + ligne dans HISTORIQUE
    this.fichierUploadInsert(u, c);                 // ④ fichier joint éventuel
    return this;
}
```

| Étape | Ce qui se passe | Table touchée |
|---|---|---|
| ① `controler(c)` | ne fait rien par défaut : c'est une **méthode à redéfinir** pour contrôler | — |
| ② `construirePK(c)` | appelle **ta** `construirePK` → `preparePk` + `makePK` → id `SAL000001`. **Seulement si l'id est vide.** | séquence `SEQ_SALLE` |
| ③ `insertToTableWithHisto(u, c)` | écrit d'abord une ligne d'historique (« Insertion par 990001 »), puis l'`INSERT` de l'objet, avec **un attribut = une colonne** | `HISTORIQUE`, puis ta table |
| ④ `fichierUploadInsert` | enregistre un fichier joint s'il y en a un (sinon, rien) | — |

## 3. Ce que `ClassMere` ajoute : les lignes

```java
public ClassMAPTable createObject(String u, Connection c) throws Exception {
    ClassMAPTable ret = super.createObject(u, c);   // la MÈRE : §2 (id, INSERT, historique)
    if (this.fille == null) return ret;             // pas de lignes : fini
    // pour CHAQUE ligne :
    //   1. met l'id de la mère dans la colonne de liaison (idreservation = RSV000004)
    //   2. f.createObjectBatch(u, st) :
    //        f.controler(c)  →  f.construirePK(c)  →  INSERT + historique (en lot)
    st.executeBatch();                              // envoie toutes les lignes d'un coup
    return ret;
}
```

Ce qu'il faut en retenir :
1. **La mère est insérée d'abord**, puis les lignes. C'est pour ça que la liaison (`idreservation`) est remplie toute seule : l'id de la mère existe déjà.
2. **Les lignes passent par `createObjectBatch`, pas par `createObject`.** ⚠ Si tu redéfinis `createObject` dans une **classe fille**, cette méthode ne sera **jamais appelée** quand la ligne est créée par sa mère.
3. Pour contrôler **une ligne seule**, redéfinis **`controler(Connection c)`** dans la fille : elle, elle est bien appelée pour chaque ligne.
4. Pour contrôler **les lignes ensemble** (pas de doublon, un total…), fais-le dans le `createObject` de la **mère**, avant `super`, avec `this.getFille()`. C'est ce que fait `Reservation`.

## 4. Pourquoi on la redéfinit

Pour faire passer tes **règles métier** juste avant l'`INSERT`, au seul endroit par où passent tous les enregistrements, quel que soit le chemin (§1).

Le modèle :

```java
@Override
public ClassMAPTable createObject(String u, Connection c) throws Exception {
    // 1. CONTRÔLER : refuser si une règle n'est pas respectée
    if (nom == null || nom.trim().isEmpty()) {
        throw new Exception("Le nom de la salle est obligatoire.");
    }

    // 2. CALCULER / COMPLÉTER : ce que l'écran ne doit pas fournir
    //    (date du jour, prix recopié, total, état...)

    // 3. ENREGISTRER : on laisse APJ faire l'id, l'INSERT et l'historique
    return super.createObject(u, c);
}
```

Exemple réel, la structure de `Reservation.createObject` :

| Partie | Ce qu'elle fait |
|---|---|
| **Contrôler** | le client existe ; la séance existe et n'a pas commencé ; au moins une place ; pour chaque ligne : pas de doublon, la place est dans la bonne salle, elle est libre |
| **Calculer / compléter** | pour chaque ligne, le **prix recopié** depuis le type ; puis `daty` = aujourd'hui, `montanttotal` = somme, `etat` = 11 (validée) |
| **Enregistrer** | `return super.createObject(u, c);` → la réservation, puis ses lignes |

### 4.1 Exemple complet n°1 : une table simple (`Film`)

Le cas le plus court : on contrôle les champs, puis on enregistre. Code réel de [film/Film.java](../../cinema-ejb/src/java/film/Film.java) :

```java
@Override
public ClassMAPTable createObject(String u, Connection c) throws Exception {
    // 1. CONTRÔLER les champs saisis
    if (titre == null || titre.trim().isEmpty()) {
        throw new Exception("Le titre du film est obligatoire.");
    }
    if (duree <= 0) {
        throw new Exception("La durée du film doit être supérieure à 0 minute.");
    }
    // 1 bis. CONTRÔLER les liens : la salle doit exister (sinon "Salle introuvable : …")
    CinemaUtil.parId(new Salle(), idsalle, c);

    // 3. ENREGISTRER (pas de calcul ici : rien à compléter)
    return super.createObject(u, c);
}
```

### 4.2 Exemple complet n°2 : une mère avec ses lignes (`Reservation`)

Code réel de [reservation/Reservation.java](../../cinema-ejb/src/java/reservation/Reservation.java), découpé en étapes numérotées. C'est le modèle à suivre pour toute vente ou achat avec des lignes.

```java
@Override
public ClassMAPTable createObject(String u, Connection c) throws Exception {

    // ── ① CHARGER ce dont on a besoin (et vérifier que ça existe) ──────────────
    CinemaUtil.parId(new Client(), idclient, c);                        // le client existe
    Seance seance = (Seance) CinemaUtil.parId(new Seance(), idseance, c);
    // Verrou : deux guichets sur la même séance → le second attend la fin du premier
    CGenUtil.rechercherSimple("select id from SEANCE where id = '"
            + CinemaUtil.echapper(idseance) + "' for update", c);
    Film film = (Film) CinemaUtil.parId(new Film(), seance.getIdfilm(), c);

    // ── ② RÈGLES SUR LE DOCUMENT ──────────────────────────────────────────────
    if (seance.calculerDebut() < System.currentTimeMillis()) {
        throw new Exception("La séance " + seance.getId() + " a déjà commencé : réservation impossible.");
    }

    // ── ③ AU MOINS UNE LIGNE ──────────────────────────────────────────────────
    ReservationDetail[] lignes = (ReservationDetail[]) this.getFille();   // les lignes attachées par setFille
    if (lignes == null || lignes.length == 0) {
        throw new Exception("Choisissez au moins une place.");
    }

    // ── ④ POUR CHAQUE LIGNE : règles + prix recopié ───────────────────────────
    double total = 0;
    Set<String> dejaChoisies = new HashSet<String>();
    for (ReservationDetail ligne : lignes) {
        Place place = (Place) CinemaUtil.parId(new Place(), ligne.getIdplace(), c);

        if (!dejaChoisies.add(place.getId())) {                          // pas deux fois la même
            throw new Exception("La place " + place.getNumero() + " est choisie deux fois.");
        }
        if (!place.getIdsalle().equals(film.getIdsalle())) {             // le bon parent
            throw new Exception("La place " + place.getNumero() + " n'est pas dans la salle du film.");
        }
        if (estReservee(place.getId(), seance.getId(), c)) {             // encore disponible
            throw new Exception("La place " + place.getNumero() + " est déjà réservée pour cette séance.");
        }

        // Le prix vient du TYPE, lu en base (jamais de l'écran), et il est RECOPIÉ dans la ligne
        TypePlace type = (TypePlace) CinemaUtil.parId(new TypePlace(), place.getIdtypeplace(), c);
        ligne.setPrix(type.getPrix());
        total += type.getPrix();
    }

    // ── ⑤ COMPLÉTER LA MÈRE ───────────────────────────────────────────────────
    this.setDaty(Utilitaire.dateDuJourSql());                // date du jour
    this.setEtat(ConstanteEtat.getEtatValider());            // payée → VALIDÉE (sinon etat = 0 = annulée)
    this.setMontanttotal(total);                             // total = somme des lignes

    // ── ⑥ ENREGISTRER : la mère, puis ses lignes, dans la même transaction ─────
    return super.createObject(u, c);
}

/** « Disponible » se déduit des lignes déjà enregistrées : un count sur les ventes non annulées. */
public static boolean estReservee(String idplace, String idseance, Connection c) throws Exception {
    String sql = "select count(*) from RESERVATIONDETAIL d"
            + " join RESERVATION r on r.id = d.idreservation"
            + " where d.idplace = '" + CinemaUtil.echapper(idplace) + "'"
            + " and r.idseance = '" + CinemaUtil.echapper(idseance) + "'"
            + " and r.etat <> 0";
    Object o = CGenUtil.rechercherSimple(sql, c);
    return (o instanceof Number) && ((Number) o).intValue() > 0;
}
```

**Les imports** dont ce `createObject` a besoin : `bean.CGenUtil`, `bean.ClassMAPTable`, `constante.ConstanteEtat`, `utilitaire.Utilitaire`, `utils.CinemaUtil`, `java.sql.Connection`, `java.util.HashSet`, `java.util.Set`, plus les classes chargées (`Client`, `Seance`, `Film`, `Place`, `TypePlace`).

**Comment l'adapter à ton module.** Garde les six étapes, change le contenu :

| Étape | Question à te poser pour ton module |
|---|---|
| ① charger | quels objets ma mère référence-t-elle (client, parent…) ? Faut-il un verrou sur le parent ? |
| ② règles du document | y a-t-il une condition sur le document lui-même (date, parent encore ouvert…) ? Sinon, étape vide. |
| ③ au moins une ligne | identique, change seulement le message |
| ④ chaque ligne | quel est le « bon parent » d'un élément ? Comment savoir s'il est déjà pris (quelle table, quelle condition) ? Où est son prix ? |
| ⑤ compléter | date, état, total : les mêmes trois lignes |
| ⑥ enregistrer | identique |

Et `estReservee` devient « est-ce que CET élément est déjà dans une vente non annulée ? ». Si l'élément est pris pour toujours (pas de notion de séance), la condition sur la séance disparaît.

## 5. Avant ou après `super.createObject` ?

| Je veux… | Où | Pourquoi |
|---|---|---|
| refuser l'enregistrement | **avant** | après, l'`INSERT` est déjà fait (même s'il sera annulé par le rollback) |
| remplir une colonne calculée (date, total, état, prix) | **avant** | l'`INSERT` écrit les attributs tels qu'ils sont à ce moment-là |
| utiliser l'**id** du nouvel objet (le mettre dans une autre table…) | **après** | l'id n'existe qu'après `construirePK`, qui est appelé dans `super` |

Dans la grande majorité des cas, **tout se fait avant**, et la méthode se termine par `return super.createObject(u, c);`.

## 6. La transaction : une exception annule tout

- `throw new Exception("message")` → l'appelant fait `rollback` : **rien** n'est enregistré, ni la mère, ni les lignes, ni l'historique. Le message s'affiche en alerte.
- **Toujours utiliser la connexion `c` reçue**, pour les lectures comme pour les écritures. Avec une nouvelle connexion, on sortirait de la transaction : on ne verrait pas ce qui vient d'être écrit, et ce qu'on écrirait ne serait pas annulé en cas d'erreur.
- **Jamais de `commit` dans `createObject`** : c'est le rôle de l'appelant.

## 7. Les pièges (tous rencontrés dans ce projet)

| Symptôme | Cause | Solution |
|---|---|---|
| Rien n'est enregistré, et aucune erreur | `super.createObject(u, c)` oublié | terminer par `return super.createObject(u, c);` |
| Un contrôle mis dans la **fille** ne s'exécute jamais | `createObject` redéfini dans la fille ; la mère passe par `createObjectBatch` (§3) | mettre le contrôle dans `controler(Connection c)` de la fille, ou dans le `createObject` de la mère |
| L'objet est enregistré avec `etat = 0` (= annulé) | la classe déclare **son propre** `private int etat`, qui vaut 0 par défaut. Celui de `ClassEtat` (qui vaut 1) est un **autre** attribut, et APJ insère celui de ta classe. | fixer l'état dans `createObject` : `this.setEtat(ConstanteEtat.getEtatValider());` (bug réel corrigé dans `Reservation`) |
| `Erreur insertion dans la table historique ORA-01722` | `u` n'est pas un id utilisateur numérique (la colonne `HISTORIQUE.IDUTILISATEUR` est un `NUMBER`) | passer `u.getUser().getTuppleID()`, l'id de l'utilisateur connecté |
| L'id choisi à la main est gardé, puis `ORA-00001` (doublon) | `construirePK` n'est appelé que si l'id est **vide** | laisser l'id vide à la création |
| Les données lues dans le contrôle ne voient pas ce qui vient d'être écrit | lecture faite avec une autre connexion (`null` ou nouvelle) | passer `c` à `CGenUtil.rechercher(..., c, ...)` |

## 8. Ne pas confondre

| Méthode | Rôle | La redéfinir ? |
|---|---|---|
| `createObject(u, c)` | enregistrer : contrôle → id → INSERT + historique (+ lignes pour une mère) | **oui**, pour les règles de création |
| `controler(c)` | contrôle appelé au début de `createObject` / `createObjectBatch` | oui, surtout dans une **fille** |
| `construirePK(c)` | fabriquer l'id | **toujours** (préfixe + fonction) |
| `insertToTable(c)` | l'`INSERT` seul, sans contrôle ni historique | non, et ne pas l'appeler à la place de `createObject` |
| `createObjectBatch(u, st)` | la version « en lot », utilisée pour les lignes d'une mère | non |
| `updateObject` / `validerObject` | modifier / valider (état → 11) : d'autres moments, avec leurs propres méthodes de contrôle | voir le tableau du §4 de [creer_une_classe_apj.md](creer_une_classe_apj.md) |

## 9. Checklist pour ton `createObject`

1. ☐ Les contrôles **lancent une `Exception`** avec un message clair.
2. ☐ Les colonnes calculées (date, prix recopié, total, état) sont remplies **avant** `super`.
3. ☐ Les lectures utilisent **la connexion `c`**.
4. ☐ Pas de `commit`, pas de nouvelle connexion.
5. ☐ La méthode se termine par `return super.createObject(u, c);`.
6. ☐ Mère / fille : les contrôles des lignes sont dans le `createObject` de la **mère**, ou dans `controler` de la **fille**.
7. ☐ Si la classe a un `etat`, il est fixé explicitement.
