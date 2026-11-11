# Tuto — Listes déroulantes et champs en lecture seule

Comment faire une **liste déroulante** (`<select>`) et un **champ non modifiable** (lecture seule, ou caché), de deux façons :
- **A. Dans une page écrite à la main.** C'est le cas de ta page de saisie dans le cinéma (comme `reservation-saisie.jsp`).
- **B. Dans un formulaire généré par APJ** (`PageInsert`, ou les critères d'une `PageRecherche`).

Tout ce qui concerne APJ a été **testé dans le serveur du cinéma** le 11/11/2026 : liste depuis une table, valeurs fixes, lecture seule, champ caché, et la servlet des listes dépendantes.

Prérequis : [creer_une_page.md](creer_une_page.md).

--- 

## Laquelle choisir ?

| Ta page | Façon |
|---|---|
| page de saisie écrite à la main + ta fonction de service (le cas du cinéma) | **A** |
| formulaire APJ (`PageInsert`), ou critères de recherche d'une liste APJ | **B** |

Ne mélange pas les deux dans la même page : une `Liste` APJ utilisée **seule**, hors formulaire APJ, s'affiche **vide** (testé, voir B7).

---

# A. Dans une page écrite à la main

## A1. Une liste remplie depuis la base

```jsp
<%
    String idclient = request.getParameter("idclient");          // ce qui est déjà choisi
    Client[] clients = ReservationService.listerClients(null);   // ta fonction de service
%>
<label for="idclient">Client</label>
<select name="idclient" id="idclient" class="form-control">
    <option value="">-- Choisir --</option>
    <% for (Client c : clients) { %>
    <option value="<%= CinemaUtil.html(c.getId()) %>"
            <%= c.getId().equals(idclient) ? "selected" : "" %>>
        <%= CinemaUtil.html(c.getNom()) %>
    </option>
    <% } %>
</select>
```

| Morceau | Rôle |
|---|---|
| `name="idclient"` | le nom du paramètre envoyé : la page suivante le lit avec `request.getParameter("idclient")` |
| `value="…id…"` | ce qui est **envoyé** (l'id) |
| le texte entre `<option>` et `</option>` | ce qui est **affiché** (le nom) |
| `<option value="">-- Choisir --</option>` | une première ligne vide, pour obliger à choisir |
| `selected` | remet le choix précédent quand la page se recharge |
| `CinemaUtil.html(...)` | protège les textes venus de la base |
| `class="form-control"` | le style Bootstrap du socle, comme les autres champs |

Exemple réel : le client, le film et la séance dans [reservation-saisie.jsp](../../cinema-war/web/pages/reservation/reservation-saisie.jsp).

## A2. Une liste de valeurs fixes

```html
<select name="mode" class="form-control">
    <option value="ESP">Espèces</option>
    <option value="MOB">Mobile money</option>
</select>
```

## A3. Une liste qui dépend d'une autre

La technique du cinéma, sans AJAX : **la page se renvoie à elle-même** quand on change le premier choix, puis remplit le second avec ce choix.

```jsp
<form id="f" action="<%= lien %>" method="get">
    <input type="hidden" name="but" value="monmodule/monmodule-saisie.jsp">
    <select name="idparent" onchange="document.getElementById('f').submit()"> … </select>
    <% if (idParent != null && !idParent.isEmpty()) {
           Enfant[] enfants = MonService.listerEnfants(idParent, null); %>
    <select name="idenfant"> … une option par enfant … </select>
    <% } %>
</form>
```

Le détail, y compris comment effacer le second choix quand on change le premier : [creer_une_page.md](creer_une_page.md) §6.2, et `changerFilm()` dans `reservation-saisie.jsp`.

## A4. Un champ en lecture seule

```html
<label for="salle">Salle</label>
<input type="text" id="salle" class="form-control" readonly
       value="<%= salle == null ? "" : CinemaUtil.html(salle.getNom()) %>">
```

La valeur vient du **serveur** (ici, la salle du film choisi). L'utilisateur la voit mais ne peut pas la changer. Exemples réels : « Salle », « Total » et « Monnaie à rendre » dans les pages de réservation.

### `readonly` ou `disabled` ? Une différence importante

| Attribut | Modifiable ? | **Envoyé** avec le formulaire ? | À utiliser pour… |
|---|---|---|---|
| `readonly` | non | **oui** | une valeur à montrer **et** à envoyer |
| `disabled` | non (grisé) | **non** | une valeur seulement à montrer, ou une liste pas encore utilisable |
| `type="hidden"` | invisible | **oui** | une valeur à envoyer sans la montrer (un id) |

⚠ **`readonly` ne marche pas sur un `<select>`** : l'utilisateur peut quand même changer la valeur. Pour une liste bloquée :
- soit la remplacer par un `<input readonly>` qui montre le libellé, plus un `<input type="hidden">` qui porte l'id ;
- soit la mettre en `disabled`, en sachant qu'elle ne sera **pas envoyée**. Exemple réel : la séance est `disabled` tant qu'aucun film n'est choisi.

### Lecture seule ne veut pas dire « sûr »

Un champ `readonly` ou `hidden` peut être modifié par quelqu'un qui bricole la page. **Le serveur ne fait jamais confiance à une valeur affichée** : c'est pour ça que `createObject` recalcule le prix et le total ([createObject.md](createObject.md)). Un champ en lecture seule sert à **informer**, pas à protéger.

## A5. Un champ caché

```jsp
<input type="hidden" name="idseance" value="<%= CinemaUtil.html(idseance) %>">
```

Il sert à faire passer un choix d'une page à la suivante. Exemple réel : le formulaire de paiement renvoie `idclient`, `idseance` et chaque `idplace` en champs cachés.

---

# B. Dans un formulaire généré par APJ

Ici, APJ fabrique les champs à partir des **attributs de la classe** ([conventions_apj.md](conventions_apj.md) §1). On ne fait que les **régler**.

## B1. Le cadre : une `PageInsert`

```java
PageInsert pi = new PageInsert(new Reservation(), request, u);   // un champ par attribut
pi.setLien((String) session.getAttribute("lien"));

// … les réglages : listes (B2 à B5), lecture seule (B6) …

pi.preparerDataFormu();                    // APRÈS les réglages : charge les données des listes
pi.getFormu().makeHtmlInsertTabIndex();
out.println(pi.getFormu().getHtmlInsert());
```

⚠ **L'ordre compte** : `changerEnChamp` et les réglages d'abord, puis `preparerDataFormu()`, puis l'affichage.

## B2. Une liste remplie depuis une table

```java
Liste[] listes = new Liste[1];
//                 nom du champ   source         colonne AFFICHÉE   colonne ENVOYÉE
listes[0] = new Liste("idclient", new Client(), "nom",             "id");
pi.getFormu().changerEnChamp(listes);                 // remplace l'input "idclient" par la liste
pi.getFormu().getChamp("idclient").setLibelle("Client");
```

HTML produit (**testé**) :
```html
<select name=idclient class=form-control id=idclient>
  <option value='CLI000002'>Rakoto Jean
  <option value='CLI000004'>Randria Paul
  <option value='CLI000003'>Rasoa Marie
</select>
```
- Le **1er argument** doit être **un attribut de la classe** du formulaire (ici `Reservation.idclient`).
- Les colonnes affichée et envoyée doivent **exister** dans la table source, sinon la page est blanche (`ORA-00904`).
- Pour une table de nomenclature `ID, VAL, DESCE` : `new Liste("champ", new TypeObjet("NOMTABLE"), "val", "id")`.

## B3. Filtrer, présélectionner, ajouter une ligne vide

```java
listes[0].setApresW(" and nom like 'R%'");                  // filtre SQL : commence par " and "
listes[0].setDefaultSelected("CLI000003");                  // valeur choisie au départ
listes[0].ajouterValeur(new String[]{""}, new String[]{"-"}); // (valeurs, libellés) : un choix vide
```

## B4. Une liste de valeurs fixes

```java
Liste etat = new Liste("etat");
etat.makeListeString(new String[]{"Créée", "Validée"},     // ce qu'on VOIT
                     new String[]{"1",     "11"});         // ce qu'on ENVOIE
etat.setDefaultSelected("11");
pi.getFormu().changerEnChamp(new Liste[]{ etat });
```
Testé : `<option value='11' selected>Validée`.

## B5. Une liste qui dépend d'une autre (AJAX)

```java
Liste film   = new Liste("idfilm",   new Film(),   "titre", "id");
Liste seance = new Liste("idseance", new Seance(), "heure", "id");
pi.getFormu().changerEnChamp(new Liste[]{ film, seance });

// Sur la liste PARENTE : quand elle change, recharger "seance" en filtrant SEANCE.idfilm
film.setDeroulanteDependante(seance, "idfilm", "onchange");
```

Comment ça marche : `film` reçoit un `onchange="dependante(…)"`. La fonction JavaScript `dependante` (dans `pages/elements/js.jsp`) appelle la servlet **`/Deroulante`** d'`apj-core2.jar`, qui renvoie les séances du film en JSON. **Testé** : `/Deroulante` répond bien dans le cinéma (`{"valeure":[{"id":"SEA000003","valeur":"18:00"},…]}`).

Conditions :
- les **deux** champs doivent être des attributs de la classe du formulaire ;
- le 2ᵉ argument est la colonne **de la table enfant** qui contient l'id du parent (`SEANCE.idfilm`).

## B6. Lecture seule, valeur par défaut, caché, type

```java
Champ total = pi.getFormu().getChamp("montanttotal");
total.setDefaut("40000");             // valeur au départ
total.setAutre("readonly");           // ← lecture seule

pi.getFormu().getChamp("idseance").setVisible(false);   // caché (input hidden, mais ENVOYÉ)
pi.getFormu().getChamp("daty").setType("date");         // date, time, number, textarea…
```

HTML produit (**testé**) : `<input name=montanttotal … value='40000' … readonly>` et `<input name='idseance' type='hidden' …>`.

`setAutre("…")` **colle le texte tel quel dans la balise** : `readonly`, `required`, `style='width:80px'`, `onchange='maFonction()'`…

Pour **toutes les lignes** d'un tableau de lignes (formulaire mère + filles), en une fois :
```java
affichage.Champ.setAutre(pi.getFormufle().getChampFille("prix"), "readonly");
affichage.Champ.setVisible(pi.getFormufle().getChampFille("idmere"), false);
```

## B7. Les limites dans le cinéma (testées)

| Ce qu'on essaie | Résultat |
|---|---|
| afficher un formulaire `PageInsert` avec listes et lecture seule | ✅ marche |
| `/Deroulante` pour une liste dépendante | ✅ marche |
| une `Liste` **seule**, hors formulaire (`new Liste(...)` + `makeHtmlInsert()`) | ❌ `<select>` **vide** : elle ne charge ses données que dans un formulaire (`preparerDataFormu`) |
| **enregistrer** un formulaire `PageInsert` en postant vers `apresMultiple.jsp` | ❌ la page n'existe pas dans le cinéma ([classes_mere_fille.md](classes_mere_fille.md) §9) |

👉 Dans le cinéma : pour une **saisie**, utilise la façon **A** et ta fonction de service. La façon **B** sert aux **critères des listes APJ** ([creer_une_page.md](creer_une_page.md) §4), où `getChamp(...)` se règle de la même façon.

---

## Les pièges

| Symptôme | Cause | Solution |
|---|---|---|
| La page suivante reçoit le **libellé** au lieu de l'id | `value` oublié sur l'`<option>` (A) ; colonnes inversées dans `new Liste(...)` (B) | `value` = l'id ; `new Liste(champ, source, AFFICHÉE, ENVOYÉE)` |
| Le choix est perdu au rechargement | `selected` oublié | `selected` quand l'id = le paramètre reçu |
| Une valeur `disabled` n'arrive pas à la page suivante | `disabled` n'est pas envoyé | `readonly` (pour un `input`), ou un `hidden` en plus |
| Une liste « en lecture seule » se change quand même | `readonly` ne marche pas sur `<select>` | `input readonly` + `hidden`, ou `disabled` |
| Page blanche, `ORA-00904` | colonne de `Liste` ou de `setApresW` absente de la table | vérifier les colonnes |
| `NullPointerException` sur `getChamp("x")` | `x` n'est pas un attribut de la classe | même nom que l'attribut |
| La `Liste` APJ est vide | utilisée hors formulaire, ou réglée **après** `preparerDataFormu()` | dans un formulaire APJ, et réglages **avant** `preparerDataFormu()` |
| Un total « lecture seule » modifié à la main est enregistré | on a fait confiance à l'écran | le serveur recalcule (`createObject`) |
