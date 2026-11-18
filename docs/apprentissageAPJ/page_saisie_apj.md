# Construire une page de saisie avec l'APJ — l'exemple de la réservation

Comment on a reconstruit `cinema-war/web/pages/reservation/reservation-saisie.jsp` **morceau par morceau** avec `PageInsertMultiple` : chaque bout de code, ce qu'il fait, et les erreurs rencontrées en chemin.

Le résultat : un formulaire **Client → Film → Séance** en en-tête, et un tableau de **places** dont les listes se remplissent avec les places libres de la séance choisie.

Voir aussi : [dropdown_readonly.md](dropdown_readonly.md) (listes, readonly), [vues_lib.md](vues_lib.md) (vues `_LIB`), [creer_une_page.md](creer_une_page.md).

---

## 0. Les fondations

**Une page = deux zones, toujours dans cet ordre :**
```
PRÉPARATION (Java, en haut)   →   AFFICHAGE (HTML, en bas)
```
On prépare tout d'abord, on affiche ensuite. Pas de calcul dans la zone AFFICHAGE.

**L'APJ fabrique les champs à partir de la classe.** Un attribut Java = un champ du formulaire. On n'écrit pas les `<input>` à la main : on **règle** ceux que l'APJ a créés.

**Deux formulaires dans une saisie mère/filles :**

| Code | Formulaire | Classe |
|---|---|---|
| `p.getFormu()` | l'**en-tête** (la mère) | `Reservation` |
| `p.getFormufle()` | le **tableau des lignes** (les filles) | `ReservationDetail` |

---

## 1. Le squelette : faire apparaître l'en-tête brut

```java
UserEJB u = (UserEJB) session.getValue("u");                              // ①

Reservation r = new Reservation();                                         // ②
ReservationDetail rd = new ReservationDetail();
int nbLigne = 5;                                                           // ③

PageInsertMultiple p = new PageInsertMultiple(r, rd, request, nbLigne, u); // ④
p.setLien(lien);                                                           // ⑤

// ... ici viendront TOUS les réglages ...

p.preparerDataFormu();                                                     // ⑥
p.getFormu().makeHtmlInsertTabIndex();                                     // ⑦
```
```jsp
<%= p.getFormu().getHtmlInsert() %>                                        <%-- ⑧ --%>
```

| # | Signification |
|---|---|
| ① | l'utilisateur connecté (rangé en session au login) : l'APJ en a besoin pour les listes et les droits |
| ② | deux objets **vides** qui servent de **modèles** : l'APJ lit leurs attributs pour fabriquer les champs |
| ③ | le nombre de lignes du tableau des places : 1 ligne = 1 place, donc 5 places au maximum |
| ④ | le **chef d'orchestre** : il construit l'en-tête (`getFormu`) et les lignes (`getFormufle`) |
| ⑤ | le début des liens que l'APJ fabrique lui-même (`module.jsp`) |
| ⑥ | « va chercher en base ce qu'il faut pour remplir le formulaire » (les listes déroulantes) — **toujours APRÈS les réglages** |
| ⑦ | **écrit** le HTML de l'en-tête et le **garde** dans `p` (ne l'affiche pas) |
| ⑧ | **met** ce HTML dans la page |

Fabriquer ≠ afficher : sans ⑧, ⑦ a bien travaillé mais l'écran reste vide.

**Résultat :** des zones de texte brutes `idclient`, `idseance`, `daty`, `montanttotal`, `etat`, avec les noms techniques comme libellés.

---

## 2. Cacher ce que le programme calcule

```java
// ── RÉGLAGES DE L'EN-TÊTE ──
p.getFormu().getChamp("daty").setVisible(false);
p.getFormu().getChamp("montanttotal").setVisible(false);
p.getFormu().getChamp("etat").setVisible(false);
```

| Champ | Qui le remplit ? |
|---|---|
| `daty` | `Reservation.createObject` : la date du jour |
| `montanttotal` | `createObject` : la somme des prix (promo de 20 h comprise) |
| `etat` | `createObject` : 11 (validée) |

- `getChamp("daty")` : le champ qui correspond à l'attribut `daty`. Le nom doit être **exactement** celui de l'attribut.
- `setVisible(false)` : ne pas le dessiner à l'écran.

Le guichetier ne saisit que ce qu'il **choisit**, jamais ce qui est **calculé**.

> ⚠ **Pas de `getChamp("id")` dans l'en-tête.** `PageInsertMultiple` ne crée **jamais** de champ `id` pour la mère (il sera donné par la séquence). `getChamp("id")` renvoie `null`, et `null.setVisible(...)` lève une **NullPointerException**.

---

## 3. Le client en liste déroulante

```java
Liste[] listes = new Liste[1];
listes[0] = new Liste("idclient", new Client(), "nom", "id");
p.getFormu().changerEnChamp(listes);
```

Les 4 paramètres de `new Liste(...)` :
```
new Liste( "idclient",    new Client(),     "nom",               "id" )
           le champ       la table où       ce que le guichetier ce qui part
           à remplacer    on lit            VOIT                 au serveur
```
Le HTML produit :
```html
<select name="idclient">
    <option value="CLI000001">Rakoto</option>
    <option value="CLI000002">Rasoa</option>
</select>
```

- `changerEnChamp` prend un **tableau** : une case = un champ transformé. La taille du tableau = **exactement** le nombre de listes remplies (une case vide = `null` = NPE).
- Il cherche dans le formulaire le champ **du même nom** et met la liste à sa place.

> ⚠ **Le 1ᵉʳ paramètre = le nom de l'attribut du FORMULAIRE, à la lettre près, en minuscules.** `"idClient"` est trouvé (l'APJ compare sans les majuscules) mais le HTML devient `name="idClient"`, et à l'enregistrement Java cherche `idclient` (avec les majuscules) : le client arrive vide.

---

## 4. La séance : il faut une colonne lisible → une vue

La table SEANCE n'a que `idfilm`, `daty`, `heure` : une liste qui affiche `SEA000012` n'aide personne. On fabrique le libellé dans une **vue** :

```sql
-- Une séance avec un libellé lisible, pour les listes déroulantes (classe film.SeanceLib)
CREATE OR REPLACE VIEW SEANCE_LIB AS
SELECT se.id, se.idfilm, se.daty, se.heure,
       f.titre || ' - ' || TO_CHAR(se.daty, 'DD/MM/YYYY') || ' à ' || se.heure AS libelle
FROM SEANCE se
JOIN FILM f ON f.id = se.idfilm;
```

| Morceau | Sens |
|---|---|
| `JOIN FILM` | aller chercher le **titre** du film de la séance |
| `\|\|` | coller des textes bout à bout (le `+` des chaînes en Java) |
| `TO_CHAR(se.daty, 'DD/MM/YYYY')` | la date en texte : `20/11/2026` |
| `AS libelle` | le nom de la nouvelle colonne : c'est elle que la liste affiche |

Et sa classe (lecture seule : pas de `construirePK`, pas de `createObject`) :
```java
public class SeanceLib extends ClassMAPTable {
    private String id, idfilm, heure, libelle;
    private Date daty;
    public SeanceLib() { this.setNomTable("SEANCE_LIB"); }
    // getTuppleID, getAttributIDName, getters / setters
}
```
**Pourquoi une classe ?** L'APJ ne lit pas du SQL : il lit les **attributs d'une classe** et fait `select * from <nomTable>`. Sans attribut `libelle`, pas d'affichage. Chaque attribut a besoin de son getter/setter (`libelle` → `getLibelle` / `setLibelle`).

```java
listes[1] = new Liste("idseance", new SeanceLib(), "libelle", "id", " and daty >= trunc(sysdate)");
```
Le **5ᵉ paramètre** est un filtre ajouté au `where` :
- il commence par un **espace** (sinon : `where 1<2and daty...`) ;
- `trunc(sysdate)` = aujourd'hui à 00:00, pour garder les séances de ce soir ;
- **jamais d'`order by`** : l'APJ ajoute déjà le sien (`order by libelle ASC`). Deux `order by` = `ORA-00933`.

> ⚠ Le 1ᵉʳ paramètre est `"idseance"` (le champ de `Reservation`), **pas** `"id"` (la colonne de la vue). Avec `"id"`, l'APJ ne trouve aucun champ à remplacer et **ne dit rien** : la séance reste une zone de texte.

---

## 5. De vrais libellés

```java
p.getFormu().getChamp("idclient").setLibelle("Client");
p.getFormu().getChamp("idseance").setLibelle("S&eacute;ance");
```
- Le libellé ne change que le **texte affiché** : `name="idclient"` ne bouge pas.
- `&eacute;` = « é » écrit de façon sûre dans le HTML.
- **Après** `changerEnChamp` : sinon le libellé est posé sur l'ancien champ, qui est jeté.

---

## 6. Le tableau des places

```java
p.getFormufle().makeHtmlInsertTableauIndex();       // dans la PRÉPARATION, après l'en-tête
```
```jsp
<h3>Places</h3>
<%= p.getFormufle().getHtmlTableauInsert() %>
```
C'est le même couple « fabriquer / afficher » que pour l'en-tête :
```
En-tête :  makeHtmlInsertTabIndex()        →  getHtmlInsert()
Lignes  :  makeHtmlInsertTableauIndex()    →  getHtmlTableauInsert()
```
Chaque ligne a ses champs **numérotés** : `idplace_0`, `idplace_1`, … `idplace_4`. La **case à cocher** du début de ligne : seules les lignes cochées sont enregistrées.

---

## 7. Régler les lignes

```java
// ── RÉGLAGES DES LIGNES ──
Champ.setVisible(p.getFormufle().getChampFille("idreservation"), false);
Champ.setVisible(p.getFormufle().getChampFille("prix"), false);
Champ.setVisible(p.getFormufle().getChampFille("id"), false);
```

| Champ | Pourquoi caché |
|---|---|
| `idreservation` | l'APJ y met l'id de la mère au moment d'enregistrer |
| `prix` | calculé par `Reservation.createObject` à partir du type de la place |
| `id` | l'id de la ligne : utile seulement en **modification** ; en création, c'est la séquence |

Deux façons de viser les lignes :
```
getChamp("prix_0")       → UNE ligne précise (la 1ʳᵉ)
getChampFille("prix")    → TOUTES les lignes, dans un tableau
```
`Champ.setVisible(tableau, false)` cache tous les champs du tableau d'un coup.

> ⚠ Contrairement à l'en-tête, **les lignes ont bien un champ `id`** (`id_0`, `id_1`…).

---

## 8. Les places libres de la séance : une liste dépendante

### 8a. La vue « places libres par séance »

Une liste dépendante filtre **une colonne** de la table qu'elle lit. Il faut donc une table où chaque place porte l'`idseance` :

```sql
-- Les places LIBRES de chaque séance, avec un libellé lisible (classe salle.PlaceSeanceLib)
CREATE OR REPLACE VIEW PLACE_SEANCE_LIB AS
SELECT p.id, se.id AS idseance, p.numero,
       p.numero || ' - ' || t.libelle || ' (' || t.prix || ' Ar)' AS libelle
FROM SEANCE se
JOIN FILM f      ON f.id = se.idfilm
JOIN PLACE p     ON p.idsalle = f.idsalle
JOIN TYPEPLACE t ON t.id = p.idtypeplace
WHERE NOT EXISTS (
    SELECT 1 FROM RESERVATIONDETAIL d
    JOIN RESERVATION r ON r.id = d.idreservation
    WHERE d.idplace = p.id AND r.idseance = se.id AND r.etat <> 0
);
```
En une phrase : *les couples (séance, place de la salle de son film) pour lesquels il n'existe pas de ligne de réservation sur cette place, pour cette séance, dans une réservation non annulée.*

| Ligne | Morceau de la phrase |
|---|---|
| `FROM SEANCE … JOIN FILM … JOIN PLACE` | chaque séance × les places de la salle de son film |
| `WHERE NOT EXISTS (` | « pour lesquels il n'existe pas… » |
| `FROM RESERVATIONDETAIL d JOIN RESERVATION r` | « …de ligne de réservation » (le JOIN apporte la séance et l'état, qui sont dans la mère) |
| `d.idplace = p.id` | « sur cette place » |
| `r.idseance = se.id` | « pour cette séance » |
| `r.etat <> 0` | « dans une réservation **non annulée** » (0 = annulée) |

**L'ordre d'exécution du SQL** n'est pas l'ordre d'écriture :
```
1. FROM / JOIN  → fabrique toutes les lignes possibles
2. WHERE        → enlève les lignes qui ne conviennent pas (la sous-requête est relancée pour CHAQUE ligne)
3. SELECT       → fabrique les colonnes des lignes restantes (dont libelle)
```

Sa classe `salle.PlaceSeanceLib` : `id` (l'id de la **place**), `idseance`, `numero`, `libelle`.

### 8b. La liste des places, vide au départ

```java
Liste[] listesFille = new Liste[1];
listesFille[0] = new Liste("idplace", new PlaceSeanceLib(), "libelle", "id", " and 1 = 2");
p.getFormufle().changerEnChamp(listesFille);

p.getFormufle().getChamp("idplace_0").setLibelle("Place");     // APRÈS changerEnChamp
```
- **`"idplace"` sans `_0`** : pour les lignes, l'APJ remplace tous les champs qui **commencent par** `idplace_`. Avec `"idplace_0"`, il cherche `idplace_0_…` et ne trouve rien.
- `" and 1 = 2"` : une condition toujours fausse, donc **aucune** place tant qu'aucune séance n'est choisie.
- `"idplace"` est un champ de **`ReservationDetail`** (le formulaire) ; `"id"` (4ᵉ paramètre) est une colonne de **`PlaceSeanceLib`** (la source). L'`id` de la place devient `idplace` dans la ligne : c'est une clé étrangère.

```
<select name="idplace_0">                         ← SON NOM   : vient du formulaire (ReservationDetail)
    <option value="PLA000007">E7 - Standard</option>  ← SES CHOIX : viennent de PlaceSeanceLib
```

### 8c. Le lien séance → les 5 lignes de places

```java
String js = "";
for (int i = 0; i < nbLigne; i++) {
    js += "dependante(this.value, 'idplace_" + i + "', 'PLACE_SEANCE_LIB', 'salle.PlaceSeanceLib', 'idseance', 'id', 'libelle');";
}
p.getFormu().getChamp("idseance").setAutre("onchange=\"" + js + "\"");
```
**Concrètement :** la boucle fabrique 5 fois la même instruction (une par ligne) et les colle dans **un seul** `onchange` sur la liste des séances. Quand la séance change, **chacune des 5 lignes** se remplit avec **toutes** les places libres de cette séance.

Deux moments, deux machines :
```
MOMENT 1 — SERVEUR (Java)          : fabrique le TEXTE "dependante(...)" ×5 et le colle dans <select onchange="...">
MOMENT 2 — NAVIGATEUR (JavaScript) : le guichetier change la séance
                                     → dependante(...) vide la liste et appelle /Deroulante (AJAX, sans recharger)
                                     → la servlet APJ fait  select * from PLACE_SEANCE_LIB where idseance = '...'
                                     → renvoie du JSON → la liste est remplie
```
Les paramètres de `dependante` :
```
dependante( this.value,   'idplace_0',   'PLACE_SEANCE_LIB', 'salle.PlaceSeanceLib', 'idseance',  'id',        'libelle' )
            la séance     la liste à     la vue à lire       sa classe               colonne      ce qui part  ce qu'on
            choisie       remplir                                                    filtrée      au serveur   voit
```
Une erreur ici apparaît dans la **console du navigateur** (F12), pas dans `server.log`.

**Pourquoi pas `setDeroulanteDependante` ?** Cette méthode APJ écrit exactement ce `onchange`, mais pour **une seule** cible. L'appeler 5 fois donnerait 5 attributs `onchange` sur le même `<select>`, et le navigateur ne garde que le premier.

---

## 9. Film → séance : un champ qui n'est pas dans la classe

La liste des séances était trop longue : on choisit d'abord le **film**.

```java
// Un champ "film" qui n'est PAS dans Reservation : il sert seulement à filtrer les séances
p.getFormu().ajouterChamp(new String[]{"idfilm"});

Liste[] listes = new Liste[3];
listes[0] = new Liste("idclient", new Client(), "nom", "id");
listes[1] = new Liste("idseance", new SeanceLib(), "libelle", "id", " and daty >= trunc(sysdate)");
listes[2] = new Liste("idfilm", new Film(), "titre", "id");
listes[2].ajouterVide();                                              // "(Vide)" en tête
listes[2].setDeroulanteDependante(listes[1], "idfilm", "onchange");   // film → séances
p.getFormu().changerEnChamp(listes);

p.getFormu().getChamp("idfilm").setLibelle("Film");
p.getFormu().setOrdre(new String[]{"idclient", "idfilm", "idseance"});
```

| Code | Sens |
|---|---|
| `ajouterChamp(new String[]{"idfilm"})` | ajoute au formulaire un champ **absent de la classe**. À l'enregistrement, l'APJ ne lit que les attributs de `Reservation` : `idfilm` est envoyé mais **ignoré**. |
| `ajouterVide()` | **ajoute** une option `(Vide)` en première position (n'enlève rien) : le guichetier doit **changer** le film, ce qui déclenche le `onchange` |
| `setDeroulanteDependante(listes[1], "idfilm", "onchange")` | la méthode APJ, ici avec **une seule** cible : « quand le film change, remplis `idseance` avec les lignes de `SeanceLib` dont `idfilm` = le film choisi » |
| `setOrdre(...)` | `ajouterChamp` met le nouveau champ vers la fin ; on remet l'ordre logique |

La chaîne complète :
```
Film choisi ──(setDeroulanteDependante)──► Séances du film ──(onchange ×5)──► 5 listes de places libres
```

> ⚠ La servlet `/Deroulante` ne filtre que sur **une** colonne (`idfilm`) : le filtre `daty >= trunc(sysdate)` n'est **pas** appliqué au rechargement. Les séances passées réapparaissent ; le serveur les refuse quand même à l'enregistrement (« la séance a déjà commencé »).

### Les méthodes APJ de listes dépendantes

| Méthode | Lien |
|---|---|
| `liste.setDeroulanteDependante(Liste autre, colonneFiltre, event)` | **un** champ → **un** autre (film → séance) |
| `liste.setDeroulanteDependante(Formulaire formu, "nomAutre", colonneFiltre, event)` | pareil, avec le **nom** de l'autre champ |
| `formufle.getChampMulitple("x").setDeroulanteDependante("y", colonneFiltre, event)` | **dans chaque ligne** : `x_0` → `y_0`, `x_1` → `y_1`… |
| `Champ.setAutoCompleteDependante(...)` | pas une liste : une zone de recherche (autocomplete) |

Aucune ne fait **en-tête → toutes les lignes** : d'où notre boucle du §8c.

---

## 10. Les règles à retenir

1. **PRÉPARATION puis AFFICHAGE**, jamais l'inverse.
2. **La classe décide des champs** : on règle, on n'écrit pas les `<input>`.
3. **L'ordre de la préparation est fixe** :
   ```
   modèles vides → new PageInsertMultiple → setLien → RÉGLAGES → preparerDataFormu → makeHtml...
   ```
   Un réglage après `preparerDataFormu` ne sert à rien.
4. **`getFormu()` = en-tête, `getFormufle()` = lignes.**
5. **Nom du champ = nom de l'attribut Java, à la lettre près**, minuscules comprises.
6. **En-tête : pas de champ `id`. Lignes : `id_0`, `id_1`… existent** (à cacher).
7. **On cache ce que le programme calcule.**
8. **Fabriquer (`makeHtml…`) ≠ afficher (`<%= getHtml… %>`).**
9. **`new Liste(champDuFormulaire, sourceALire, colonneVue, colonneEnvoyee [, filtre])`** : le 1ᵉʳ parle du formulaire, les autres de la source.
10. **Filtre d'une `Liste`** : commence par un espace, des `and ...`, jamais d'`order by`.
11. **`setLibelle` après `changerEnChamp`.**
12. **L'écran aide, le serveur décide** : les listes filtrent pour le confort, `Reservation.createObject` contrôle tout (séance passée, place prise, place en double).

---

## 11. Les erreurs rencontrées

| Symptôme | Cause | Correction |
|---|---|---|
| `NullPointerException` | `getChamp("id")` sur l'en-tête : ce champ n'existe pas | ne jamais viser `id` dans l'en-tête |
| la séance reste une zone de texte, sans erreur | `new Liste("id", ...)` au lieu de `"idseance"` | 1ᵉʳ paramètre = champ du formulaire |
| `ORA-00933 la commande SQL ne se termine pas correctement` | `order by` dans le filtre + celui de l'APJ | pas d'`order by` dans le filtre |
| **page vide**, pas d'alerte | import manquant (`salle.PlaceSeanceLib`) : erreur de **compilation** de la JSP, le `try/catch` ne s'exécute jamais | ajouter l'import |
| les places restent des zones de texte | `new Liste("idplace_0", ...)` | `"idplace"` sans numéro |
| le libellé « Place » disparaît | `setLibelle` avant `changerEnChamp` | `setLibelle` après |
| la même place sur deux lignes | toutes les lignes proposent les mêmes choix | refusé par le serveur (« choisie deux fois ») ; filtrage à l'écran possible plus tard (JS) |

**Où chercher :** une alerte donne le **type** d'erreur ; `server.log` donne la **ligne** ; une page vide = erreur de **compilation** ; un problème de liste qui se remplit = **console du navigateur** (F12).

---

## 12. La suite

- Le **bouton Enregistrer** et les champs cachés (`acte`, `bute`, `classe`, `classefille`, `nomtable`, `nombreLigne`, `colonneMere`).
- **`apresMultiple.jsp`** (la partie « insert ») et **`createObjectMultiple`** dans `UserEJB`.
- La facture et la caisse déplacées dans **`Reservation.createObject`**, pour rester dans la même transaction.
- La **liste** des réservations (`PageRecherche`) et la **fiche** (`PageConsulte`).
