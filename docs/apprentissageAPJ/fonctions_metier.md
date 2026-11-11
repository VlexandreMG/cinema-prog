# Tuto — Écrire les fonctions métier : le mindset et la stratégie

Ce tuto explique **comment penser et écrire les fonctions d'un écran** : lister, charger par id, lister ce qui dépend d'un choix, lister ce qui est encore disponible, calculer un montant, et enregistrer un document avec ses lignes.

Les exemples réels viennent de [ReservationService.java](../../cinema-ejb/src/java/reservation/ReservationService.java) (scénario 1). Les modèles à copier utilisent des noms neutres : `Conteneur` (un objet qui contient des éléments), `Element`, `ElementLib`, `TypeElement`, `Achat` (la mère) et `AchatDetail` (la fille). Remplace-les par tes propres classes.

> ⚠ **Ces noms neutres n'existent pas dans le projet.** `Conteneur`, `Element`, `Achat`, `MonService`, et les fonctions `chargerElements`, `listerDisponibles`, `acheter`… sont des **modèles à écrire toi-même**. Chacun est calqué sur une vraie fonction du scénario 1, indiquée à côté. Si tu cherches un nom dans le code et que tu ne le trouves pas, c'est normal : cherche sa fonction modèle.

| Nom neutre (à écrire) | Calqué sur (existe dans `ReservationService`) |
|---|---|
| `listerConteneurs` | `listerFilms`, `listerClients` |
| `listerDisponibles(idConteneur)` | `listerPlacesLibres(idSeance)` |
| `chargerElements(idElements)` | `chargerPlaces(idPlaces)` (voir §6.2) |
| `calculerMontant(idElements)` | `calculerMontant(idPlaces)` |
| `acheter(...)` | `reserver(...)` |

Prérequis : [creer_une_classe_apj.md](creer_une_classe_apj.md), [createObject.md](createObject.md), [classes_mere_fille.md](classes_mere_fille.md).

---

## 1. Le mindset

### 1.1 Partir de l'écran, pas de la base
Une fonction métier répond à **une question posée par l'écran**. On ne se demande pas « quelles fonctions sur ma table ? », mais « de quoi a besoin **chaque champ** de mon écran ? ». Au scénario 1 :

```
Client  [▼]   ← « qui sont les clients ? »                    → listerClients()
Film    [▼]   ← « quels films ? »                             → listerFilms()
Salle   [  ]  ← « dans quelle salle passe CE film ? »          → salleDuFilm(idFilm)
Séance  [▼]   ← « quelles séances à venir pour CE film ? »     → listerSeances(idFilm)
☐ places      ← « quelles places encore libres à CETTE séance ? » → listerPlacesLibres(idSeance)
Total   [  ]  ← « combien coûtent CES places ? »               → calculerMontant(idPlaces)
[Réserver]    ← « enregistre tout ça »                         → reserver(...)
```

👉 **Une fonction par champ.** Le nom de la fonction, c'est la question écrite en verbe.

### 1.2 Deux familles de fonctions
| Famille | Ce qu'elle fait | Transaction | Exemples |
|---|---|---|---|
| **Lecture** | répond à une question, ne modifie rien | pas de `commit` | `lister…`, `charger…`, `calculer…` |
| **Écriture** | enregistre | `commit` / `rollback` | `reserver` |

### 1.3 Le service orchestre, la classe métier contrôle
- **Le service** rassemble les données et appelle `createObject`. Il ne contient **aucune règle métier**.
- **La classe métier** (`createObject`) contient **toutes les règles** : contrôles, prix recopié, total, état.

Pourquoi ? Parce que `createObject` est le seul passage obligé de tout enregistrement. Une règle qui serait seulement dans le service pourrait être contournée.

Exemple : `calculerMontant` (service) sert à **l'affichage**. Le vrai total est **recalculé** dans `Reservation.createObject`. On ne fait jamais confiance à un montant venu de l'écran.

### 1.4 Une fonction = entrées simples → sortie simple
- **Entrées** : des ids (`String`, ou `String[]` pour un choix multiple), plus la connexion `c`.
- **Sortie** : un objet, un tableau d'objets, ou un nombre.
- Pas d'objet `request`, pas de HTML : la fonction ne sait pas qu'une page existe. On peut donc la tester seule (§8).

### 1.5 Si l'écran a besoin d'un libellé, fais une vue `_LIB`
L'écran veut afficher « E8 — VIP — 25 000 », pas `PLC000041`. Plutôt que de faire une requête par ligne, on crée une **vue** qui joint les tables, et une classe qui la lit (`PLACE_LIB` → `PlaceLib`). La fonction renvoie alors directement des objets prêts à afficher. Quand en faire une (et quand c'est inutile) : [vues_lib.md](vues_lib.md).

## 2. La stratégie, étape par étape

1. **Dessine l'écran** (comme ton croquis) et écris la question de chaque champ.
2. **Donne un nom à chaque fonction** : `lister…`, `…Du…`, `charger…`, `calculer…`, un verbe pour l'écriture.
3. **Pour chacune, écris sa signature** avant le code : entrées → sortie.
4. **Choisis l'outil** (§3).
5. **Écris les lectures**, et teste-les (§8).
6. **Écris le `createObject` de la mère** : les règles (voir [createObject.md](createObject.md)).
7. **Écris la fonction d'écriture**, et teste-la dans une transaction annulée (§8).
8. **Seulement ensuite**, fais les pages.

## 3. Choisir l'outil

| La question | L'outil | Exemple réel |
|---|---|---|
| tous les X | `CGenUtil.rechercher(new X(), null, null, c, " order by …")` | `listerClients` |
| le X qui a CET id | `CinemaUtil.parId(new X(), id, c)` (lance une exception s'il n'existe pas) | `salleDuFilm` |
| les X qui appartiennent à CE Y | `rechercher(…, " and idy = '…'")` | `listerSeances(idFilm)` |
| les X qui ne sont pas encore utilisés | `rechercher(…, " and id not in (select … )")` | `listerPlacesLibres` |
| un nombre (somme, compte) | `CGenUtil.rechercherSimple("select …", c)` | `estReservee` (un `count`) |
| X avec des libellés d'autres tables | une vue `X_LIB` + une classe `XLib` | `PlaceLib`, `ReservationLib` |
| plusieurs X à partir d'une liste d'ids | `rechercher(…, " and id in ('A','B')")` | `chargerPlaces` |

Rappels (voir [creer_une_classe_apj.md](creer_une_classe_apj.md) §5) :
- le filtre commence toujours par `" and "` et peut finir par `" order by …"` ;
- **jamais** la version à 2 arguments de `rechercher` ;
- toute valeur collée dans du SQL passe par `CinemaUtil.echapper(...)` ;
- le cast `(X[]) res` est sûr : APJ crée un tableau du bon type.

## 4. Le modèle commun : le paramètre `Connection c`

Toutes les fonctions du service suivent la même forme :

```java
public static Xxx maFonction(..., Connection c) throws Exception {
    boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }   // j'ouvre si on ne m'a rien donné
        // ... le travail, en passant TOUJOURS c ...
    } finally {
        if (ouvert && c != null) c.close();                            // je ferme seulement ce que j'ai ouvert
    }
}
```

- Depuis une **JSP**, on appelle avec `null` : la fonction ouvre et ferme sa connexion.
- Depuis **une autre fonction**, ou dans un test, on passe sa propre `c` : on reste dans **la même transaction**.

## 5. Les modèles de lecture

### 5.1 Lister tout
```java
public static Conteneur[] listerConteneurs(Connection c) throws Exception {
    boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }
        Object[] res = CGenUtil.rechercher(new Conteneur(), null, null, c, " order by nom asc");
        return (Conteneur[]) res;
    } finally {
        if (ouvert && c != null) c.close();
    }
}
```

### 5.2 Charger par id
```java
Conteneur x = (Conteneur) CinemaUtil.parId(new Conteneur(), idConteneur, c);
```
Pas besoin d'une fonction dans le service : `parId` suffit, et il lance « Conteneur introuvable » si l'id n'existe pas. Fais une fonction seulement si la question est plus riche, comme `salleDuFilm(idFilm)`, qui charge le film puis sa salle.

### 5.3 Lister ce qui appartient à un choix (liste dépendante)
```java
// « les éléments de CE conteneur »
Object[] res = CGenUtil.rechercher(new Element(), null, null, c,
        " and idconteneur = '" + CinemaUtil.echapper(idConteneur) + "' order by numero asc");
```

### 5.4 Lister ce qui est encore disponible ⭐
C'est la question clé d'une réservation. La disponibilité **n'est pas une colonne** : elle **se déduit** des lignes déjà enregistrées.

Raisonnement en 3 temps :
1. **Tous les candidats** : les éléments de ce conteneur.
2. **Les déjà pris** : les éléments présents dans une ligne d'un achat **non annulé** (`etat <> 0`).
3. **Disponibles** = candidats **sauf** déjà pris → `not in (sous-requête)`.

```java
String filtre = " and idconteneur = '" + CinemaUtil.echapper(idConteneur) + "'"
        + " and id not in ("
        + "   select d.idelement from ACHATDETAIL d"
        + "   join ACHAT a on a.id = d.idachat"
        + "   where a.etat <> 0)"                       // un achat annulé libère ses éléments
        + " order by numero asc";
Object[] res = CGenUtil.rechercher(new ElementLib(), null, null, c, filtre);
```

Au scénario 1, la sous-requête a **une condition de plus**, `r.idseance = '…'`, parce qu'une place n'est prise que **pour une séance**. Demande-toi : **« pris » pour toujours, ou pris pour un moment précis ?** La réponse dit s'il faut cette condition.

⚠ Avec `not in`, si la sous-requête peut renvoyer un `NULL`, Oracle ne renvoie plus **aucune** ligne. Mets la colonne en `NOT NULL` dans la table des lignes (c'est le cas de `idplace`).

### 5.5 Lister avec une condition de temps
```java
// SQL : à partir d'aujourd'hui ; Java : on retire ce qui a déjà commencé aujourd'hui
" and daty >= trunc(sysdate) order by daty asc, heure asc"
```
Voir `listerSeances` (scénario 1). Inutile si ton sujet n'a pas de notion de date.

## 6. Le modèle de calcul : le montant

### 6.1 Côté service : pour l'affichage
```java
public static double calculerMontant(String[] idElements, Connection c) throws Exception {
    double total = 0;
    for (ElementLib e : chargerElements(idElements, c)) {   // chaque élément avec le prix de son type
        total += e.getPrix();
    }
    return total;
}
```
`calculerMontant` ne lit pas la base lui-même : il **réutilise** `chargerElements`, qui charge les éléments choisis avec leur prix. On écrit une seule fois « charger les éléments choisis », et le récapitulatif de la page de paiement s'en sert aussi (il affiche chaque élément, puis le total).

### 6.2 `chargerElements` : d'où ça vient, et comment l'écrire

**Elle n'existe pas encore : c'est à toi de l'écrire, dans ton service.** Son modèle est `chargerPlaces` dans [ReservationService.java](../../cinema-ejb/src/java/reservation/ReservationService.java).

**Sa question :** « donne-moi les éléments que l'utilisateur a cochés, avec leur type et leur prix, dans l'ordre où il les a choisis ».

**Pourquoi une fonction à part ?** Deux autres en ont besoin :
- `calculerMontant` (§6.1), pour additionner les prix ;
- la page de paiement, pour afficher le récapitulatif ligne par ligne.

```java
/**
 * Les éléments choisis, avec leur type et leur prix (vue ELEMENT_LIB), dans l'ordre du choix.
 * @throws Exception si un id n'existe pas
 */
public static ElementLib[] chargerElements(String[] idElements, Connection c) throws Exception {
    if (idElements == null || idElements.length == 0) return new ElementLib[0];   // ①
    boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); ouvert = true; }

        // ② UNE seule requête pour tous les ids : ... where id in ('ELT000003','ELT000007')
        Object[] res = CGenUtil.rechercher(new ElementLib(), null, null, c,
                " and id in (" + listeSql(idElements) + ")");

        // ③ Ranger le résultat par id, pour le retrouver vite
        Map<String, ElementLib> parId = new HashMap<String, ElementLib>();
        for (Object o : res) {
            ElementLib e = (ElementLib) o;
            parId.put(e.getId(), e);
        }

        // ④ Remettre dans l'ORDRE DU CHOIX, et refuser un id inconnu
        ElementLib[] elements = new ElementLib[idElements.length];
        for (int i = 0; i < idElements.length; i++) {
            elements[i] = parId.get(idElements[i]);
            if (elements[i] == null) throw new Exception("Élément introuvable : " + idElements[i]);
        }
        return elements;
    } finally {
        if (ouvert && c != null) c.close();
    }
}
```

| Étape | Pourquoi |
|---|---|
| ① liste vide → tableau vide | rien de coché = total 0, sans requête inutile |
| ② `id in (...)` | **une** requête au lieu d'une par élément ; on lit la vue `_LIB` pour avoir le prix du type ([vues_lib.md](vues_lib.md)) |
| ③ `HashMap` par id | Oracle renvoie les lignes **dans l'ordre qu'il veut**, pas dans celui des ids demandés |
| ④ boucle sur `idElements` | on reconstruit l'ordre du choix ; un id absent du résultat veut dire « n'existe pas » → exception, plutôt qu'un prix oublié en silence |

Imports nécessaires : `java.util.Map`, `java.util.HashMap`, `bean.CGenUtil`, `utilitaire.UtilDB`, `utils.CinemaUtil`.

#### ⚠ `listeSql` est `private` dans `ReservationService`

`chargerPlaces` appelle `listeSql(...)`, qui transforme `{"A","B"}` en `'A','B'`. Mais cette méthode est **`private`** dans `ReservationService` : **ton service ne peut pas l'appeler**. Copie-la dans ta classe de service :

```java
/** {"A","B"} -> 'A','B' (valeurs échappées), pour un "in (...)". */
private static String listeSql(String[] valeurs) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < valeurs.length; i++) {
        if (i > 0) sb.append(",");
        sb.append("'").append(CinemaUtil.echapper(valeurs[i])).append("'");
    }
    return sb.toString();
}
```

Chaque valeur passe par `CinemaUtil.echapper` : un id contenant une apostrophe ne peut pas casser la requête.

### 6.3 Côté classe mère : le vrai calcul
Dans `createObject` de la mère, **avant `super`** :
```java
double total = 0;
for (AchatDetail ligne : (AchatDetail[]) this.getFille()) {
    Element el = (Element) CinemaUtil.parId(new Element(), ligne.getIdelement(), c);
    TypeElement type = (TypeElement) CinemaUtil.parId(new TypeElement(), el.getIdtypeelement(), c);
    ligne.setPrix(type.getPrix());     // le PRIX RECOPIÉ dans la ligne : figé pour toujours
    total += type.getPrix();
}
this.setMontanttotal(total);
```
- Le prix vient **du type**, lu en base, jamais de l'écran.
- Il est **recopié dans la ligne**, pour que le passé ne change pas si le prix du type change.
- Le total de la mère est **la somme des lignes**.

## 7. Le modèle d'écriture : la même structure qu'une réservation

### 7.1 La fonction du service
```java
public static Achat acheter(String idClient, String idConteneur, String[] idElements,
                            String u, Connection c) throws Exception {
    boolean ouvert = false;
    try {
        if (c == null) { c = new UtilDB().GetConn(); c.setAutoCommit(false); ouvert = true; }
        if (idElements == null || idElements.length == 0) throw new Exception("Choisissez au moins un élément.");

        Achat a = new Achat();                         // 1. la mère : seulement les choix de l'écran
        a.setIdclient(idClient);
        a.setIdconteneur(idConteneur);

        ClassFille[] lignes = new ClassFille[idElements.length];
        for (int i = 0; i < idElements.length; i++) {  // 2. une ligne par élément choisi
            AchatDetail d = new AchatDetail();         //    ni id, ni liaison, ni prix
            d.setIdelement(idElements[i]);
            lignes[i] = d;
        }
        a.setFille(lignes);                            // 3. attacher

        a.createObject(u, c);                          // 4. TOUTES les règles + INSERT mère puis lignes

        if (ouvert) c.commit();
        return a;
    } catch (Exception e) {
        if (ouvert && c != null) c.rollback();
        throw e;
    } finally {
        if (ouvert && c != null) c.close();
    }
}
```
`u` est l'id de l'utilisateur connecté (`u.getUser().getTuppleID()` dans la JSP). Il doit être **numérique**, car il est écrit dans `HISTORIQUE`.

### 7.2 Les règles, dans `createObject` de la mère
Fais la liste des règles de ton sujet, puis traduis chacune en un `throw` ou un calcul. La structure de `Reservation.createObject` :

```
1. charger ce dont on a besoin    (client, conteneur… avec parId → « introuvable » sinon)
2. règles sur le document         (existe ? encore ouvert ?)
3. au moins une ligne             (getFille() vide → refus)
4. pour chaque ligne :
     - pas deux fois la même      (un HashSet des ids)
     - appartient au bon parent   (élément.idconteneur == idConteneur de la mère)
     - encore disponible          (un count sur les lignes déjà enregistrées, non annulées)
     - prix recopié depuis le type, ajouté au total
5. compléter la mère              (date du jour, total, ÉTAT = validé)
6. return super.createObject(u, c);
```

⚠ **Fixe l'état explicitement** (`this.setEtat(ConstanteEtat.getEtatValider())`), sinon il vaut 0, c'est-à-dire « annulé », et tes éléments paraîtront toujours disponibles. C'est le bug réel du scénario 1 : voir [createObject.md](createObject.md) §7.

**Deux ventes en même temps ?** Au scénario 1, `Reservation.createObject` verrouille la séance (`select … for update`), pour que deux guichets ne vendent pas la même place au même moment. Si ton sujet a un parent commun aux éléments (le conteneur), tu peux verrouiller sa ligne de la même façon.

### 7.3 Les fonctions pour la fiche (après l'enregistrement)
- `chargerAchat(id, c)` → une vue `ACHAT_LIB` (la mère avec ses libellés) ;
- `listerLignes(idAchat, c)` → une vue `ACHATDETAIL_LIB` (les lignes avec leurs libellés et le **prix payé**).

Modèle : `chargerReservation` et `listerLignes` dans `ReservationService`.

## 8. Tester une fonction sans page

Plus rapide qu'un déploiement : un petit programme Java qui appelle tes fonctions, et dont l'écriture se fait dans une transaction **annulée**.

```java
// Test.java (hors du projet, par exemple dans /tmp)
import java.sql.Connection;
public class Test { public static void main(String[] a) throws Exception {
    System.out.println("conteneurs = " + MonService.listerConteneurs(null).length);
    // ... une ligne par fonction de lecture ...

    Connection c = new utilitaire.UtilDB().GetConn(); c.setAutoCommit(false);
    try {
        // l'id utilisateur doit être numérique (HISTORIQUE) : 990001 = le compte "cinema"
        Object achat = MonService.acheter("CLI000001", "…", new String[]{"…"}, "990001", c);
        System.out.println("disponibles après = " + MonService.listerDisponibles("…", c).length);
        try { MonService.acheter("CLI000002", "…", new String[]{"…"}, "990001", c); System.out.println("ERREUR : accepté deux fois"); }
        catch (Exception e) { System.out.println("refus attendu : " + e.getMessage()); }
    } finally { c.rollback(); c.close(); }   // rien n'est gardé en base
}}
```

```bash
cd /home/balou/S5/MrTahina/cinema
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant compile           # met à jour build-file/cinema_jar
CP="build-file/cinema_jar:build-file/lib/*"
/usr/lib/jvm/java-8-openjdk-amd64/bin/javac -cp "$CP" -d /tmp/test /tmp/Test.java
/usr/lib/jvm/java-8-openjdk-amd64/bin/java  -cp "/tmp/test:$CP" Test
```
`build-file/cinema_jar` contient `apj.properties` : la connexion à la base `cinema` marche toute seule. Avec `apj.debug=true`, chaque requête s'affiche (`Requete select rechercher : …`), ce qui aide beaucoup quand un filtre ne renvoie rien.

À vérifier, dans l'ordre :
1. chaque liste renvoie le bon nombre ;
2. une liste dépendante change quand on change de parent ;
3. le montant est juste ;
4. après un enregistrement, les disponibles **diminuent** ;
5. enregistrer deux fois le même élément est **refusé** ;
6. après le `rollback`, tout est revenu comme avant.

## 9. Checklist

1. ☐ Une fonction par champ de l'écran, nommée par sa question.
2. ☐ Signatures : des ids en entrée, la connexion `c` en dernier, des objets ou un nombre en sortie.
3. ☐ Le modèle `c == null` → ouvrir / fermer ; `commit` / `rollback` seulement pour l'écriture.
4. ☐ Des vues `_LIB` pour ce que l'écran affiche.
5. ☐ « Disponible » se déduit des lignes non annulées (`not in`), ce n'est pas une colonne.
6. ☐ Le montant du service sert à l'affichage ; le vrai est recalculé dans `createObject`.
7. ☐ Aucune règle dans le service : elles sont toutes dans `createObject` de la mère.
8. ☐ L'état de la mère est fixé explicitement.
9. ☐ Chaque fonction est testée seule, l'écriture dans une transaction annulée.
