# Tuto — Créer une page (JSP) dans le cinéma

Ce tuto explique comment une page s'affiche, quels types de pages existent, et comment écrire chacun. Les modèles **liste** et **fiche** ont été testés dans le vrai serveur du cinéma le 11/11/2026 (sur `ReservationLib` et `ReservationDetailLib`). Le modèle **formulaire écrit à la main** est celui des pages de réservation, qui tournent.

Prérequis : tes fonctions de service écrites et testées ([fonctions_metier.md](fonctions_metier.md)), et tes vues `_LIB` ([vues_lib.md](vues_lib.md)). Conventions de nommage : [conventions_apj.md](conventions_apj.md).

---

## 1. Comment une page s'affiche

```
http://localhost:8080/cinema/pages/module.jsp?but=reservation/reservation-saisie.jsp&idfilm=FLM000001
                                   └─ cadre ─┘   └──────── ta page ──────────────┘ └─ paramètres ─┘
```

1. `module.jsp` vérifie qu'on est connecté (`security-login.jsp`), puis affiche l'en-tête et le menu.
2. Il **inclut** la page indiquée par `but`, un chemin relatif à `cinema-war/web/pages/`.
3. Ta page s'affiche au milieu, dans `<div class="content-wrapper">`.

Ta page a donc accès à la **session** :

```java
UserEJB u    = (UserEJB) session.getAttribute("u");     // l'utilisateur connecté
String  lien = (String)  session.getAttribute("lien");  // "module.jsp" : base de tous les liens
String  id   = request.getParameter("id");             // un paramètre de l'URL ou du formulaire
```

**Tous les liens et formulaires pointent vers `module.jsp`**, avec `but=<ta page>` : `lien + "?but=popcorn/…-fiche.jsp&id=…"`. Une page n'est **jamais** appelée directement.

## 2. Où mettre la page, et comment l'appeler

```
cinema-war/web/pages/<module>/
    <module>-liste.jsp      la liste (recherche + tableau)
    <module>-saisie.jsp     le formulaire de création
    <module>-paiement.jsp   une étape de plus, si besoin (récapitulatif, paiement…)
    <module>-fiche.jsp      la fiche d'un enregistrement
    inc/<module>-details.jsp  les lignes affichées sous la fiche (facultatif)
```

Exemple réel : `pages/reservation/` contient `reservation-saisie.jsp`, `reservation-paiement.jsp` et `reservation-fiche.jsp`.

## 3. Quels types de pages, et lesquels marchent dans le cinéma

| Type | Classe APJ | Dans le cinéma |
|---|---|---|
| **Liste** : critères de recherche + tableau + totaux + pagination | `PageRecherche` | ✅ **marche** (testé) |
| **Fiche** : toutes les colonnes d'un enregistrement | `PageConsulte` | ✅ **marche** (testé) |
| **Lignes sous une fiche** : une liste filtrée sur la mère | `PageRecherche` + `setAWhere` | ✅ **marche** (testé) |
| **Saisie APJ** : formulaire généré qui poste vers `apresMultiple.jsp` | `PageInsert`, `PageInsertMultiple` | ❌ **ne marche pas** : `apresMultiple.jsp` et `createObjectMultiple` ne sont pas dans le cinéma ([classes_mere_fille.md](classes_mere_fille.md) §9) |
| **Formulaire écrit à la main** + fonction de service | aucune : HTML + ton service | ✅ c'est ce que font les pages de réservation |

👉 **La règle dans le cinéma :**
- pour **afficher** (une liste ou une fiche), on utilise APJ : `PageRecherche` ou `PageConsulte`, sur la **vue `_LIB`** ;
- pour **saisir** (créer), on écrit le formulaire à la main, et il appelle **ta fonction de service** (§6).

## 4. Le modèle LISTE (`PageRecherche`)

```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="affichage.PageRecherche, reservation.ReservationLib" %>
<% try {
    ReservationLib base = new ReservationLib();                        // ① la classe de la VUE _LIB
    String listeCrt[]  = {"client", "daty"};                           // ② les critères de recherche
    String listeInt[]  = {"daty"};                                     // ③ ceux qui sont des intervalles
    String libEntete[] = {"id", "client", "film", "daty", "montanttotal"}; // ④ les colonnes du tableau
    PageRecherche pr = new PageRecherche(base, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
    pr.setUtilisateur((user.UserEJB) session.getAttribute("u"));
    pr.setLien((String) session.getAttribute("lien"));
    pr.setApres("reservation/reservation-liste.jsp");                  // ⑤ la page elle-même
    pr.creerObjetPage(libEntete, new String[]{"montanttotal"});        // ⑥ exécute la recherche ; colonnes totalisées

    pr.getFormu().getChamp("client").setLibelle("Client");             // ⑦ libellés des critères
    pr.getFormu().getChamp("daty1").setLibelle("Du");
    pr.getFormu().getChamp("daty2").setLibelle("Au");

    pr.getTableau().setLien(new String[]{pr.getLien() + "?but=reservation/reservation-fiche.jsp"}); // ⑧ lien vers la fiche
    pr.getTableau().setColonneLien(new String[]{"id"});
    pr.getTableau().setAttLien(new String[]{"id"});
    pr.getTableau().setLibelleAffiche(new String[]{"N&deg;", "Client", "Film", "Date", "Montant"}); // ⑨
%>
<div class="content-wrapper">
    <h1>Liste des r&eacute;servations</h1>
    <form action="<%= pr.getLien() %>?but=reservation/reservation-liste.jsp" method="post">
        <% out.println(pr.getFormu().getHtmlEnsemble()); %>   <!-- les critères + bouton -->
    </form>
    <% out.println(pr.getTableauRecap().getHtml()); %>        <!-- nombre de lignes + totaux -->
    <% out.println(pr.getTableau().getHtml()); %>             <!-- le tableau -->
    <% out.println(pr.getBasPage()); %>                       <!-- la pagination -->
</div>
<% } catch (Exception e) { e.printStackTrace(); %>
<script>alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
```

| Repère | Explication |
|---|---|
| ① | **toujours la vue `_LIB`**, pour afficher des libellés au lieu d'ids |
| ② | chaque nom devient un champ de recherche ; **ce sont des attributs de la classe** |
| ③ | un critère d'intervalle devient **deux** champs : `daty1` (du) et `daty2` (au) |
| ④ | les colonnes du tableau, dans l'ordre ; ce sont aussi des attributs de la classe |
| ⑤ | la page vers laquelle revient la pagination |
| ⑥ | lance la requête (`select * from RESERVATION_LIB where … `). Le 2ᵉ argument liste les colonnes à totaliser (`null` = aucune) |
| ⑦ | après `creerObjetPage`, chaque critère est un champ réglable comme dans une saisie |
| ⑧ | rend la colonne `id` cliquable : `…&id=<valeur>` |
| ⑨ | les titres des colonnes ; **autant de libellés que de colonnes dans `libEntete`** |

Testé : un critère texte cherche **« contient »**. `client=Rakoto` trouve « Rakoto Jean ».

Pour filtrer en plus par le code (et non par l'utilisateur) : `pr.setAWhere(" and etat >= 11");`, **avant** `creerObjetPage`. ⚠ Pas de `order by` dans `setAWhere` s'il y a des colonnes totalisées.

## 5. Le modèle FICHE (`PageConsulte`), avec ses lignes

```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="affichage.PageConsulte, affichage.PageRecherche, user.UserEJB" %>
<%@ page import="reservation.ReservationLib, reservation.ReservationDetailLib" %>
<% try {
    UserEJB u = (UserEJB) session.getAttribute("u");
    String lien = (String) session.getAttribute("lien");

    // ── La fiche : lit le paramètre "id" de l'URL et charge l'enregistrement de la VUE ──
    PageConsulte pc = new PageConsulte(new ReservationLib(), request, u);
    pc.setTitre("R&eacute;servation");
    String id = pc.getBase().getTuppleID();

    pc.getChampByName("client").setLibelle("Client");     // sans libellé : le nom de l'attribut
    pc.getChampByName("montanttotal").setLibelle("Total");
    pc.getChampByName("etat").setVisible(false);          // cacher ce qui n'intéresse pas l'écran
    pc.getChampByName("idclient").setVisible(false);

    // ── Les lignes : une liste filtrée sur la mère ──
    String libEntete[] = {"numero", "typeplace", "prix"};
    PageRecherche lignes = new PageRecherche(new ReservationDetailLib(), request,
            new String[]{}, new String[]{}, 3, libEntete, libEntete.length);
    lignes.setUtilisateur(u);
    lignes.setLien(lien);
    lignes.setAWhere(" and idreservation = '" + id + "'");   // AVANT creerObjetPage
    lignes.creerObjetPage(libEntete, new String[]{"prix"});
    lignes.getTableau().setLibelleAffiche(new String[]{"Place", "Type", "Prix pay&eacute;"});
%>
<div class="content-wrapper">
    <h1><a href="<%= lien %>?but=reservation/reservation-liste.jsp">&lsaquo;</a> <%= pc.getTitre() %> <%= id %></h1>
    <% out.println(pc.getHtml()); %>
    <h3>Lignes</h3>
    <% out.println(lignes.getTableauRecap().getHtml()); %>
    <% out.println(lignes.getTableau().getHtml()); %>
</div>
<% } catch (Exception e) { e.printStackTrace(); %>
<script>alert('<%= e.getMessage() %>'); history.back();</script>
<% } %>
```

Testé avec `id=RSV000004` : la fiche affiche toutes les colonnes de `RESERVATION_LIB`, et les lignes A1 (15 000) et E8 (25 000), avec 2 lignes et 40 000 au total.

D'autres réglages de la fiche : `pc.setOrdre(new String[]{"id","client",…})` pour l'ordre des champs, et `pc.getChampByName("idfilm").setLien(lien + "?but=…-fiche.jsp", "id=")` pour rendre un champ cliquable.

## 6. Le modèle FORMULAIRE écrit à la main (saisie + service)

C'est le modèle des pages de réservation ([04_pages_reservation.md](../conception/04_pages_reservation.md)). Listes déroulantes, lecture seule et champs cachés, en détail : [dropdown_readonly.md](dropdown_readonly.md). Il a trois pages :

```
-saisie.jsp  ── GET (se recharge à chaque choix) ──► -paiement.jsp ── POST acte=payer ──► service ──► -fiche.jsp
```

### 6.1 Le squelette commun à toutes les pages écrites à la main

```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="monmodule.MonService, utils.CinemaUtil" %>
<%
try {
    String lien = (String) session.getAttribute("lien");
    if (lien == null) lien = "module.jsp";

    // 1. LIRE ce qui a déjà été choisi
    String idParent = request.getParameter("idparent");

    // 2. APPELER le service (avec null : il ouvre et ferme sa connexion)
    Parent[] parents = MonService.listerParents(null);
%>
<div class="content-wrapper">
    <!-- 3. AFFICHER, en protégeant chaque texte venu de la base -->
    <%= CinemaUtil.html(parents[0].getNom()) %>
</div>
<%
} catch (Exception e) {
    e.printStackTrace();
    String msg = e.getMessage() == null ? "Erreur" : e.getMessage().replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ");
%>
<script>alert('<%= msg %>'); history.back();</script>
<% } %>
```
Le `catch` affiche le message de ton `throw new Exception("…")` en alerte, puis revient en arrière. C'est le comportement des pages d'akoho.

### 6.2 La page de choix : des listes qui dépendent les unes des autres

La technique, sans AJAX : **le formulaire se renvoie à lui-même en `GET`** à chaque choix, avec ce qui est déjà choisi. La page relit ces paramètres et remplit la liste suivante.

```jsp
<form id="f" action="<%= lien %>" method="get">
  <input type="hidden" name="but" id="but" value="monmodule/monmodule-saisie.jsp">

  <select name="idparent" onchange="document.getElementById('f').submit()">
    <option value="">-- Choisir --</option>
    <% for (Parent p : parents) { %>
      <option value="<%= CinemaUtil.html(p.getId()) %>" <%= p.getId().equals(idParent) ? "selected" : "" %>>
        <%= CinemaUtil.html(p.getNom()) %></option>
    <% } %>
  </select>

  <%-- une case par élément disponible : name identique → tableau de valeurs --%>
  <% for (ElementLib e : elements) { %>
    <input type="checkbox" name="idelement" value="<%= CinemaUtil.html(e.getId()) %>"
           data-prix="<%= e.getPrix() %>" onchange="majTotal()">
    <%= CinemaUtil.html(e.getLib()) %> — <%= CinemaUtil.montant(e.getPrix()) %>
  <% } %>
</form>
```
- `selected` remet la valeur déjà choisie après le rechargement.
- Plusieurs cases avec **le même `name`** s'envoient comme un tableau, que la page suivante lit avec `request.getParameterValues("idelement")` (un `String[]`).
- `data-prix` permet de calculer le total en JavaScript **pour l'affichage** ; le serveur le recalcule toujours.
- Le bouton « Continuer » change `but` vers la page suivante, puis envoie le formulaire. Voir `continuer()` dans [reservation-saisie.jsp](../../cinema-war/web/pages/reservation/reservation-saisie.jsp).

### 6.3 La page d'action : enregistrer, puis rediriger

```jsp
<%
if ("payer".equals(request.getParameter("acte")) && "POST".equalsIgnoreCase(request.getMethod())) {
    UserEJB u = (UserEJB) session.getAttribute("u");
    String[] ids = request.getParameterValues("idelement");
    MaMere m = MonService.enregistrer(request.getParameter("idparent"), ids,
                                      u.getUser().getTuppleID(), null);   // id utilisateur NUMÉRIQUE
%>
<script>document.location.replace("<%= lien %>?but=monmodule/monmodule-fiche.jsp&id=<%= m.getId() %>");</script>
<%
    return;
}
%>
```
- **Une écriture se fait en `POST`**, jamais en `GET` : un `GET` peut être rejoué par un rafraîchissement ou un lien.
- **`document.location.replace`** redirige vers la fiche et retire la page d'action de l'historique : le bouton « Retour » ne rejoue pas l'enregistrement.
- **Le formulaire de récapitulatif** renvoie les choix en champs cachés (`<input type="hidden" name="idelement" value="…">`, un par élément).

## 7. Ajouter la page au menu

```sql
INSERT INTO MENUDYNAMIQUE (id, libelle, icone, href, rang, niveau, id_pere)
VALUES ('MENCINEMAXXX', UNISTR('Mon \00E9cran'), 'list',
        'module.jsp?but=monmodule/monmodule-liste.jsp', 2, 2, 'MENCINEMA');
INSERT INTO USERMENU (id, refuser, idmenu, idrole, codeservice, codedir, interdit)
VALUES ('USMCINEMAXXX', '*', 'MENCINEMAXXX', NULL, NULL, NULL, 0);
COMMIT;
```
- `id_pere = 'MENCINEMA'` : sous la rubrique « Cinéma » ; `niveau = 2` ; `rang` = position dans la rubrique.
- `USERMENU` avec `refuser = '*'` : visible par tout le monde. **Sans cette ligne, l'entrée n'apparaît pas.**
- `icone` : un nom d'icône Material (`list`, `add`, `event_seat`, `local_movies`…).
- `UNISTR('\00E9')` pour les accents, sinon ils s'abîment selon l'encodage du script.
- **Se déconnecter puis se reconnecter** : le menu est gardé en session (`MENU`).

## 8. Voir sa page : déployer

| J'ai modifié… | Je fais… |
|---|---|
| une **JSP seulement** | `ant` (ou copier la JSP dans `…/deployments/cinema.war/pages/…` : elle est recompilée au prochain affichage) |
| du **Java** (classe, service) | `ant`, puis attendre que `cinema.war.deployed` réapparaisse |
| la **base** (table, vue, menu) | rien ; pour le menu, se reconnecter |

Une **page blanche** ou une alerte vide : regarde `…/wildfly-10.1.0.Final/standalone/log/server.log`. Cherche `Exception` ou `ORA-` à l'heure du test ; avec `apj.debug=true`, la requête SQL exécutée est écrite juste au-dessus (`Requete select rechercher : …`).

## 9. Les pièges

| Symptôme | Cause | Solution |
|---|---|---|
| `getChamp("x")` renvoie `null` (NullPointerException) | `x` n'est pas un attribut de la classe, ou réglage fait **avant** `creerObjetPage` | vérifier le nom ; régler les champs après `creerObjetPage` |
| Les titres des colonnes sont décalés, ou erreur | `setLibelleAffiche` n'a pas autant de libellés que `libEntete` | un libellé par colonne |
| La liste affiche des ids au lieu de noms | elle lit la table au lieu de la vue `_LIB` | `new XxxLib()` dans `PageRecherche` / `PageConsulte` |
| La fiche est vide | pas de paramètre `id` dans l'URL | le lien doit finir par `&id=<valeur>` |
| La page s'appelle elle-même en boucle, ou le menu disparaît | lien écrit sans `module.jsp?but=` | toujours `lien + "?but=…"` |
| Les choix sont perdus au rechargement | `selected` / `checked` oubliés, ou paramètre non relu | relire chaque paramètre et remettre `selected` |
| Un seul élément reçu alors que plusieurs étaient cochés | `getParameter` au lieu de `getParameterValues` | `request.getParameterValues("…")` |
| `ORA-01722` en enregistrant | `u` passé au service n'est pas l'id numérique de l'utilisateur | `u.getUser().getTuppleID()` |
| Accents abîmés dans la page | page sans `pageEncoding="UTF-8"` | la 1re ligne de chaque JSP (§4) |
| L'entrée de menu n'apparaît pas | pas de ligne `USERMENU`, ou pas de reconnexion | §7 |

## 10. Checklist pour un module complet

1. ☐ Le service est écrit **et testé** ([fonctions_metier.md](fonctions_metier.md) §8) avant toute page.
2. ☐ Les vues `_LIB` existent pour ce que les pages affichent.
3. ☐ `-saisie.jsp` : listes dépendantes en `GET`, cases avec le même `name`, total en JavaScript.
4. ☐ La page d'action est en `POST`, appelle le service, puis `document.location.replace` vers la fiche.
5. ☐ `-fiche.jsp` : `PageConsulte` sur la vue `_LIB`, plus les lignes (`PageRecherche` + `setAWhere`).
6. ☐ `-liste.jsp` : `PageRecherche` sur la vue `_LIB`, lien vers la fiche.
7. ☐ Chaque texte de la base passe par `CinemaUtil.html` dans les pages écrites à la main.
8. ☐ Les entrées de menu (liste, saisie) sont ajoutées, et on s'est reconnecté.
9. ☐ `ant`, puis le parcours complet est testé dans le navigateur.
