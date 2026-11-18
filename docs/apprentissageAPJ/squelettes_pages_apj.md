# Les squelettes des pages APJ

Le modèle de **chaque type de page** du projet, à recopier puis à adapter. Chaque squelette est réduit à l'essentiel, avec la signification de chaque ligne.

| Type de page | Classe APJ | Sert à | Exemple dans le cinéma |
|---|---|---|---|
| **Saisie** mère + lignes | `PageInsertMultiple` | **créer** un objet et ses lignes | `reservation/reservation-saisie.jsp` |
| **Saisie** simple | `PageInsert` | **créer** un objet sans lignes | — |
| **Après** (traitement) | aucune page visible | **enregistrer** / **viser**, puis rediriger | `apresMultiple.jsp` |
| **Fiche** | `PageConsulte` | afficher **un seul** objet | `reservation/reservation-fiche.jsp` |
| **Tableau de lignes** (dans une fiche) | `PageRecherche` | afficher **plusieurs** lignes liées à l'objet | les places, dans la fiche |
| **Liste** | `PageRecherche` | chercher et lister **plusieurs** objets | `reservation/reservation-liste.jsp` (à faire) |

**Pour choisir :** une seule ligne → `PageConsulte` ; plusieurs lignes → `PageRecherche` ; on écrit → `PageInsert` / `PageInsertMultiple` puis une page « après ».

Détails pas à pas de la saisie : [page_saisie_apj.md](page_saisie_apj.md).

---

## 0. Le squelette commun à toutes les pages

```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="user.UserEJB" %>
<%-- + les imports des classes APJ et des classes métier utilisées --%>
<%
try {
    String lien = (String) session.getAttribute("lien");       // "module.jsp" : base de tous les liens
    if (lien == null) lien = "module.jsp";
    UserEJB u = (UserEJB) session.getValue("u");                // l'utilisateur connecté

    // ── PRÉPARATION : lire les paramètres, construire la page APJ, la régler ──

%>
<div class="content-wrapper">
    <h1>Titre</h1>

    <%-- ── AFFICHAGE : seulement des <%= ... %>, aucun calcul ── --%>

</div>
<%
} catch (Exception e) {
    e.printStackTrace();                                         // → server.log (la ligne exacte)
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>        <%-- → l'utilisateur voit le message --%>
<% } %>
```

| Partie | Rôle |
|---|---|
| `try { … } catch` | toute erreur à l'exécution devient une **alerte** + retour à la page précédente |
| `lien` | toutes les pages passent par `module.jsp?but=<la page>` (menu + contrôle de connexion) |
| `u` | l'utilisateur : l'APJ en a besoin pour lire la base et vérifier les droits |
| PRÉPARATION / AFFICHAGE | on prépare **tout**, puis on affiche. Jamais l'inverse |
| `msg.replace(...)` | protège l'alerte JavaScript des `'`, `\` et retours à la ligne du message |

> Une **page vide** sans alerte = erreur de **compilation** de la JSP (import manquant, faute de frappe) : le `try` ne s'exécute jamais.

---

## 1. Saisie mère + lignes — `PageInsertMultiple`

```java
// ── PRÉPARATION ──
Reservation mere = new Reservation();                     // modèles VIDES : l'APJ lit leurs attributs
ReservationDetail fille = new ReservationDetail();
int nbLigne = 5;                                          // nombre de lignes du tableau

PageInsertMultiple p = new PageInsertMultiple(mere, fille, request, nbLigne, u);
p.setLien(lien);

// ── RÉGLAGES DE L'EN-TÊTE : p.getFormu() ──
p.getFormu().getChamp("daty").setVisible(false);          // ce que le programme calcule
Liste[] listes = new Liste[1];
listes[0] = new Liste("idclient", new Client(), "nom", "id");
p.getFormu().changerEnChamp(listes);                      // texte → liste déroulante
p.getFormu().getChamp("idclient").setLibelle("Client");   // APRÈS changerEnChamp

// ── RÉGLAGES DES LIGNES : p.getFormufle() ──
Champ.setVisible(p.getFormufle().getChampFille("id"), false);           // toutes les lignes
Champ.setVisible(p.getFormufle().getChampFille("idreservation"), false);
p.getFormufle().getChamp("idplace_0").setLibelle("Place");              // titre de colonne (_0)

// ── PRÉPARER, PUIS FABRIQUER LE HTML ──
p.preparerDataFormu();                                    // remplit les listes (APRÈS les réglages)
p.getFormu().makeHtmlInsertTabIndex();                    // en-tête
p.getFormufle().makeHtmlInsertTableauIndex();             // lignes
```
```jsp
<%-- ── AFFICHAGE ── --%>
<form action="<%= lien %>?but=apresMultiple.jsp" method="post">
    <%= p.getFormu().getHtmlInsert() %>
    <%= p.getFormufle().getHtmlTableauInsert() %>

    <input type="hidden" name="acte"        value="insert">
    <input type="hidden" name="bute"        value="reservation/reservation-fiche.jsp">
    <input type="hidden" name="classe"      value="reservation.Reservation">
    <input type="hidden" name="classefille" value="reservation.ReservationDetail">
    <input type="hidden" name="nomtable"    value="RESERVATIONDETAIL">
    <input type="hidden" name="nombreLigne" value="<%= nbLigne %>">
    <input type="hidden" name="colonneMere" value="idreservation">
</form>
```

| Champ caché | Ce qu'il dit à `apresMultiple.jsp` |
|---|---|
| `acte` | quoi faire : `insert` |
| `bute` | où aller après (la fiche reçoit `&id=…`) |
| `classe` / `classefille` | les classes Java (nom complet) de la mère et des lignes |
| `nomtable` | la table des lignes |
| `nombreLigne` | combien de lignes lire |
| `colonneMere` | la colonne des lignes qui pointe vers la mère |

**À retenir :**
- en-tête = `getFormu()`, lignes = `getFormufle()` ;
- en-tête : **pas** de champ `id` ; lignes : `id_0`, `id_1`… **existent** (à cacher) ;
- l'APJ affiche le bouton **Enregistrer**, mais **pas** le `<form>` : c'est à nous de l'écrire ;
- seules les lignes **cochées** sont enregistrées.

---

## 2. Saisie simple — `PageInsert`

Même principe, sans lignes :
```java
Client c = new Client();
PageInsert p = new PageInsert(c, request, u);
p.setLien(lien);
// réglages : p.getFormu().getChamp("x")...
p.preparerDataFormu();
p.getFormu().makeHtmlInsertTabIndex();
```
```jsp
<form action="<%= lien %>?but=apresMultiple.jsp" method="post">   <%-- ou une page "après" simple --%>
    <%= p.getFormu().getHtmlInsert() %>
    <input type="hidden" name="acte"   value="insert">
    <input type="hidden" name="bute"   value="client/client-fiche.jsp">
    <input type="hidden" name="classe" value="client.Client">
</form>
```
⚠ Notre `apresMultiple.jsp` ne gère pour l'instant que l'insertion **mère + lignes**. Pour une saisie simple, il faudra lui ajouter le cas « sans lignes » (`u.createObject(objet)`).

---

## 3. La page « après » — `apresMultiple.jsp`

Une page **sans affichage** : elle reçoit le formulaire, fait le travail, puis **redirige**. Elle est **générique** : la même sert à toutes les saisies, grâce aux champs cachés.

```java
// ① les instructions (les champs cachés)
String acte   = request.getParameter("acte");
String bute   = request.getParameter("bute");
String classe = request.getParameter("classe");
// ... classefille, nomtable, colonneMere, nombreLigne, ids (les lignes cochées)

// ② créer les objets à partir de leur NOM (réflexion)
ClassMAPTable mere  = (ClassMAPTable) Class.forName(classe).newInstance();
ClassMAPTable fille = (ClassMAPTable) Class.forName(classefille).newInstance();

// ③ les remplir avec ce que le formulaire a envoyé
PageInsertMultiple p = new PageInsertMultiple(mere, fille, request, nbLigne, cochees);
ClassMAPTable   cmere  = p.getObjectAvecValeur();
ClassMAPTable[] cfille = p.getObjectFilleAvecValeur();       // "Vous devez cocher" si rien n'est coché

// ④ enregistrer (UNE transaction → Reservation.createObject)
ClassMAPTable o = (ClassMAPTable) u.createObjectMultiple(cmere, colonneMere, cfille);
```
```jsp
<%-- ⑤ rediriger vers la fiche --%>
<script>document.location.replace("<%= lien %>?but=<%= bute %>&id=<%= o.getTuppleID() %>");</script>
```

| Action (`acte`) | Appel | Ce qui est exécuté dans ta classe |
|---|---|---|
| `insert` | `u.createObjectMultiple(mere, colonneMere, filles)` | `createObject` (contrôles, calculs) puis INSERT mère + lignes |
| `valider` (le **visa**) | `u.validerObject(objetAvecSonId)` | `validerObject` : état → 11 (+ facture et caisse pour la réservation) |

**À retenir :**
- `document.location.replace` : le « retour » du navigateur ne renverra pas le formulaire une 2ᵉ fois ;
- pas de `<%! … %>` : des variables partagées entre tous les utilisateurs mélangeraient les requêtes ;
- une erreur métier (`throw new Exception(...)`) → `rollback` → alerte → retour au formulaire, sans rien perdre.

---

## 4. Fiche — `PageConsulte`

```java
// ── PRÉPARATION ──
ReservationLib r = new ReservationLib();                  // la VUE _LIB : des noms, pas des id
PageConsulte pc = new PageConsulte(r, request, u);        // lit &id=… dans l'URL, charge l'objet
r = (ReservationLib) pc.getBase();                        // l'objet rempli, pour nos propres tests

// ── RÉGLAGES ──
pc.getChampByName("idclient").setVisible(false);          // getChampByName (et pas getChamp)
pc.getChampByName("client").setLibelle("Client");
pc.getChampByName("etat").setLibelle("&Eacute;tat");
```
```jsp
<%-- ── AFFICHAGE ── --%>
<h1>R&eacute;servation <%= r.getId() %></h1>
<%= pc.getHtml() %>

<% if (r.getEtat() < 11) { %>
    <a class="btn btn-primary" href="<%= lien %>?but=apresMultiple.jsp&acte=valider&id=<%= r.getId() %>&classe=reservation.Reservation&bute=reservation/reservation-fiche.jsp">Viser</a>
<% } %>
```

**À retenir :**
- **`id` obligatoire** dans l'URL, sinon « Pas d identifiant » ;
- on lit la **vue `_LIB`** (affichage), pas la table ;
- pas de `preparerDataFormu` ni de `makeHtml` : on règle, puis `getHtml()` ;
- si la classe hérite de **`ClassEtat`**, l'APJ affiche l'état **en clair** tout seul (CRÉÉ(E), TRAITÉ(E), ANNULÉ(E)) ;
- les **boutons d'action** (Viser, Modifier, Annuler) sont des liens vers la page « après », affichés **selon l'état**.

---

## 5. Tableau de lignes dans une fiche — `PageRecherche`

Sous la fiche, les lignes de l'objet (les places d'une réservation) :
```java
String[] colonnes = {"numero", "typeplace", "prix"};          // attributs de la classe lue
PageRecherche pr = new PageRecherche(new ReservationDetailLib(), request,
                                     new String[]{}, new String[]{}, 3,    // aucun critère de recherche
                                     colonnes, colonnes.length);
pr.setUtilisateur(u);
pr.setLien(lien);
pr.setAWhere(" and idreservation = '" + r.getId() + "'");     // seulement les lignes de CET objet
pr.creerObjetPage(colonnes, new String[]{"prix"});            // fait la requête ; somme de "prix"
pr.getTableau().setLibelleAffiche(new String[]{"Place", "Type", "Prix (Ar)"});
```
```jsp
<h3>Places</h3>
<%= pr.getTableau().getHtml() %>
```

| Paramètre | Sens |
|---|---|
| `new String[]{}`, `new String[]{}` | aucun critère, aucun intervalle : pas de formulaire de filtre |
| `colonnes` | les colonnes du tableau, dans l'ordre |
| `setAWhere(" and …")` | le filtre : un espace au début, des `and`, **pas d'`order by`** |
| `creerObjetPage(colonnes, {"prix"})` | exécute la requête ; 2ᵉ paramètre = colonnes à additionner (`null` si aucune) |
| `setLibelleAffiche(...)` | les titres des colonnes, même ordre que `colonnes` |

---

## 6. Liste avec recherche — `PageRecherche`

La page qui liste **tous** les objets, avec un formulaire de filtres au-dessus et un lien vers la fiche :
```java
// ── PRÉPARATION ──
ReservationLib r = new ReservationLib();
String[] criteres  = {"id", "client", "film", "daty"};        // les champs du formulaire de filtre
String[] intervals = {"daty"};                                // filtrés par intervalle : daty1 … daty2
String[] colonnes  = {"id", "client", "film", "dateseance", "heure", "montanttotal", "etat"};

PageRecherche pr = new PageRecherche(r, request, criteres, intervals, 3, colonnes, colonnes.length);
pr.setTitre("Liste des r&eacute;servations");
pr.setUtilisateur(u);
pr.setLien(lien);
pr.setApres("reservation/reservation-liste.jsp");              // la page se rappelle elle-même pour filtrer

// réglages du formulaire de filtre : pr.getFormu().getChamp("x")...
pr.getFormu().getChamp("daty1").setLibelle("Du");
pr.getFormu().getChamp("daty2").setLibelle("Au");

pr.creerObjetPage(colonnes, new String[]{"montanttotal"});     // la requête (avec les filtres saisis)

// un clic sur l'id ouvre la fiche
pr.getTableau().setLien(new String[]{lien + "?but=reservation/reservation-fiche.jsp"});
pr.getTableau().setColonneLien(new String[]{"id"});
pr.getTableau().setLibelleAffiche(new String[]{"R&eacute;f.", "Client", "Film", "S&eacute;ance", "Heure", "Montant", "&Eacute;tat"});
```
```jsp
<%-- ── AFFICHAGE ── --%>
<h1><%= pr.getTitre() %></h1>
<form action="<%= lien %>?but=<%= pr.getApres() %>" method="post">
    <%= pr.getFormu().getHtmlEnsemble() %>              <%-- le formulaire de filtres --%>
</form>
<%= pr.getTableauRecap().getHtml() %>                   <%-- le récapitulatif (nombre, sommes) --%>
<%= pr.getTableau().getHtml() %>                        <%-- le tableau --%>
<%= pr.getBasPage() %>                                  <%-- la pagination --%>
```

| Élément | Sens |
|---|---|
| `criteres` | un champ de filtre par attribut. Le formulaire renvoie à la même page, qui relit les filtres dans la requête |
| `intervals` | ces attributs ont deux champs, `x1` (min) et `x2` (max) |
| `setApres(...)` | la page de destination du formulaire de filtre : elle-même |
| `setLien` / `setColonneLien` | la colonne `id` devient un lien vers la fiche, avec `&id=` + la valeur |
| `getBasPage()` | les numéros de pages quand il y a beaucoup de lignes |

*(À valider quand on construira la page liste.)*

---

## 7. Récapitulatif : qui fait quoi

```
            LIRE                                              ÉCRIRE
  ┌──────────────────────────┐                  ┌──────────────────────────────────┐
  │ Liste   (PageRecherche)  │ ── clic id ───►  │                                  │
  │ Fiche   (PageConsulte)   │ ── [Viser] ────► │ apresMultiple.jsp (acte=valider) │
  │  └ lignes (PageRecherche)│                  │                                  │
  └──────────────────────────┘                  │ apresMultiple.jsp (acte=insert)  │
            ▲                                   └──────────────────────────────────┘
            │                                        ▲                 │
            │     redirection vers la fiche          │ POST            │
            └────────────────────────────────────────┼─────────────────┘
                                                     │
                                   Saisie (PageInsertMultiple)
```

| Règle | Saisie | Fiche | Liste / tableau |
|---|---|---|---|
| modèle lu | la **table** (`Reservation`) | la **vue** (`ReservationLib`) | la **vue** |
| viser un champ | `getFormu().getChamp("x")` | `getChampByName("x")` | `getFormu().getChamp("x")` (filtres) |
| avant d'afficher | `preparerDataFormu` + `makeHtml…` | rien | `creerObjetPage` |
| afficher | `getHtmlInsert` / `getHtmlTableauInsert` | `getHtml` | `getTableau().getHtml` |
| `id` dans l'URL | **non** (sinon modification) | **obligatoire** | non |
| filtre SQL | `new Liste(..., " and …")` | — | `setAWhere(" and …")` |
