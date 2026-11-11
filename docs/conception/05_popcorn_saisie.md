# Cinéma — Popcorn : la page de saisie (`popcorn-saisie.jsp`)

La première page de la vente de jouets de popcorn : on choisit le **client**, le **paquet de popcorn**, puis on coche les **jouets** à acheter. Elle mène à la page de paiement (`popcorn-paiement.jsp`, pas encore écrite).

Page : [cinema-war/web/pages/popcorn/popcorn-saisie.jsp](../../cinema-war/web/pages/popcorn/popcorn-saisie.jsp)
Modèle suivi : la page de réservation ([04_pages_reservation.md](04_pages_reservation.md)) et [creer_une_page.md](../apprentissageAPJ/creer_une_page.md) §6.

---

## 1. Ce que voit l'utilisateur

```
Vendre des jouets de popcorn
┌───────────────────┐  ┌──────────────────────┐
│ Client       [ ▼ ]│  │ Paquet de popcorn [▼]│  ← le changer recharge la page
└───────────────────┘  └──────────────────────┘
Jouets disponibles
┌───┬───────────────┬───────────┬──────────┐
│ ☐ │ Figurine Dune │ Collector │    5 000 │
│ ☑ │ Mini Groot    │ Collector │    5 000 │
│ ☑ │ Toupie        │ Classique │    2 000 │
│ ☐ │ Yoyo          │ Classique │    2 000 │
└───┴───────────────┴───────────┴──────────┘
Total (Ar) [ 7 000 ] (lecture seule)        [ Continuer vers le paiement ]
```

- Seuls les jouets **du paquet choisi** et **encore à vendre** sont proposés.
- « Tous les jouets de ce paquet sont déjà vendus » s'affiche si le paquet est vide.
- Le bouton « Continuer » est **désactivé** tant qu'aucun jouet n'est proposé.

## 2. Accès

```
http://localhost:8080/cinema/pages/module.jsp?but=popcorn/popcorn-saisie.jsp
```
Il faut d'abord être connecté (`cinema` / `cinema`). Pas encore d'entrée de menu : on tape l'URL.

## 3. Les paramètres

Le formulaire est envoyé en **POST**. La page relit ces paramètres à chaque affichage :

| Paramètre | Vient de | Rôle |
|---|---|---|
| `idclient` | liste « Client » | le client choisi ; reste sélectionné après rechargement |
| `idpopcorn` | liste « Paquet de popcorn » | le paquet choisi ; détermine les jouets affichés |
| `idjouet` (plusieurs) | cases cochées | les jouets choisis ; restent cochés après rechargement |

La page **suivante** (`popcorn-paiement.jsp`) reçoit les mêmes paramètres : `request.getParameter("idclient")`, `request.getParameter("idpopcorn")`, `request.getParameterValues("idjouet")`.

## 4. Comment la page fonctionne

```
1. LIRE        idclient, idpopcorn, idjouet[]  (request)
2. APPELER     ReservationService.listerClients(null)
               ToyService.listerPopcorn(null)
               ToyService.listerJouetsDisponibles(idpopcorn, null)   ← seulement si un paquet est choisi
3. AFFICHER    les deux listes (selected), le tableau des jouets (checked), le total
```

### Deux destinations pour un seul formulaire, sans JavaScript

```html
<form method="post" action="module.jsp?but=popcorn/popcorn-saisie.jsp">     ← par défaut : CETTE page
    <select name="idpopcorn" onchange="this.form.submit()"> … </select>     ← changer de paquet = recharger
    …
    <button type="submit" formaction="module.jsp?but=popcorn/popcorn-paiement.jsp">   ← ce bouton : la page suivante
</form>
```

| Technique | Ce qu'elle remplace | Pourquoi |
|---|---|---|
| `method="post"` + `action="…?but=…"` | le champ caché `but` de la réservation | en `GET`, le navigateur **efface** le `?but=…` de l'`action` ; en `POST`, il le garde |
| `onchange="this.form.submit()"` | la fonction `recharger()` de la réservation | une ligne, pas de fonction |
| `formaction` sur le bouton | la fonction `continuer()` | attribut HTML5 : le bouton envoie le formulaire vers une **autre** adresse |
| `required` sur les deux listes | les `alert(...)` de `continuer()` | le navigateur refuse « Continuer » si le client ou le paquet manquent. `this.form.submit()` ne vérifie pas `required` : changer de paquet marche même sans client |

**Changer de paquet efface les anciens choix tout seul** : la page n'affiche que les jouets du nouveau paquet, donc les anciennes cases n'existent plus et ne sont plus envoyées. (La réservation avait besoin de `changerFilm()` pour ça.)

### Le seul JavaScript : le total

```js
function majTotal() { … somme des data-prix des cases cochées … }
majTotal();   // au chargement, pour les cases déjà cochées après un rechargement
```
Le total change **à chaque clic** sur une case : impossible sans JavaScript, sauf à recharger la page à chaque fois. Il sert **seulement à l'affichage** : le vrai total est recalculé par le serveur dans `Toy.createObject`.

### Ce que la page ne vérifie PAS (et pourquoi)

« Au moins un jouet », « jouet du bon paquet », « jouet pas déjà vendu » : la page ne vérifie rien de tout ça. **C'est `Toy.createObject` qui le fait**, au moment de la vente ([createObject.md](../apprentissageAPJ/createObject.md) §4.2). Une règle dans la page pourrait être contournée, alors que `createObject` est un passage obligé.

## 5. Ce dont la page dépend

| Élément | Fichier | Rôle pour la page |
|---|---|---|
| `ReservationService.listerClients` | [ReservationService.java](../../cinema-ejb/src/java/reservation/ReservationService.java) | la liste des clients (commune au cinéma) |
| `ToyService.listerPopcorn` | [ToyService.java](../../cinema-ejb/src/java/toy/ToyService.java) | la liste des paquets |
| `ToyService.listerJouetsDisponibles(idPopcorn)` | idem | les jouets du paquet **pas encore vendus**, avec type et prix |
| vue `JOUET_LIB` + classe `JouetLib` | [01_tables_metier.sql](../../database/01_tables_metier.sql), [JouetLib.java](../../cinema-ejb/src/java/jouet/JouetLib.java) | jouet + `idpopcorn` (pour filtrer) + `typejouet` et `prix` (pour afficher) |
| `CinemaUtil.html`, `CinemaUtil.montant` | [CinemaUtil.java](../../cinema-ejb/src/java/utils/CinemaUtil.java) | protéger les textes, écrire « 5 000 » |

`listerJouetsDisponibles` applique la règle « disponible = pas dans une vente non annulée » :
```sql
select * from JOUET_LIB
where idpopcorn = :paquet
  and id not in (select d.idjouet from TOYDETAIL d join TOY t on t.id = d.idtoy where t.etat <> 0)
order by lib asc
```
Pas de condition de séance : contrairement à une place, **un jouet vendu l'est pour toujours**.

## 6. Ce qui a été ajouté ou corrigé pour cette page

| Fichier | Changement |
|---|---|
| `popcorn-saisie.jsp` | la page complète |
| vue `JOUET_LIB` (script + base) | ajout de `idpopcorn`, `idtypejouet` et `typejouet` (libellé du type) |
| `JouetLib.java` | les attributs correspondants (`idpopcorn`, `idtypejouet`, `typejouet`) |
| `ToyService.listerJouetsDisponibles` | **nouvelle** fonction (modèle : `listerPlacesLibres`, sans séance) |
| `ToyService.creerToy` | **bug corrigé** : `d.setId(idJouets[i])` → `d.setIdjouet(idJouets[i])`. L'id du jouet était mis comme id **de la ligne**, et `idjouet` restait vide → la vente aurait échoué avec « Identifiant manquant pour Jouet » |
| `02_donnees_test.sql` (script + base) | jeu d'essai popcorn : 2 paquets, 2 types, 6 jouets |

## 7. Les données de test

Insérées par la fin de [02_donnees_test.sql](../../database/02_donnees_test.sql) :

| Paquet | Jouet | Type | Prix |
|---|---|---|---|
| Grand caramel | Mini Groot | Collector | 5 000 |
| Grand caramel | Figurine Dune | Collector | 5 000 |
| Grand caramel | Toupie | Classique | 2 000 |
| Grand caramel | Yoyo | Classique | 2 000 |
| Petit sale | Porte-cle Coco | Collector | 5 000 |
| Petit sale | Sifflet | Classique | 2 000 |

Les ids réels (`POP000008`, `JOT000013`…) dépendent de l'état des séquences : retrouve-les avec
`SELECT id, lib, nom, typejouet, prix FROM jouet_lib ORDER BY id;`.

⚠ Ce bloc s'exécute **une seule fois** : le relancer crée des doublons (nouveaux ids, mêmes noms).

## 8. Les tests

### 8.1 Dans le navigateur

| # | Action | Résultat attendu |
|---|---|---|
| 1 | Ouvrir l'URL (§2) | 2 listes ; pas de tableau ; « Continuer » grisé |
| 2 | Choisir « Grand caramel » | la page se recharge ; 4 jouets (Figurine Dune, Mini Groot, Toupie, Yoyo) avec type et prix |
| 3 | Cocher Mini Groot et Toupie | Total = **7 000** |
| 4 | Changer de client | rien ne se recharge (seul le paquet recharge la page) |
| 5 | Changer pour « Petit sale » | 2 jouets (Porte-cle Coco, Sifflet), aucun coché ; Total = 0 |
| 6 | Revenir sur « Grand caramel », sans client, cliquer « Continuer » | le navigateur refuse : « Veuillez sélectionner un élément » sur Client |
| 7 | Client choisi + jouets cochés, « Continuer » | envoie vers `popcorn-paiement.jsp` (**pas encore écrite** : erreur attendue tant qu'elle n'existe pas) |
| 8 | Après une vente réelle de Mini Groot | Mini Groot n'apparaît plus dans « Grand caramel » |

### 8.2 Sans navigateur (`curl`)

```bash
B=http://localhost:8080/cinema; J=/tmp/ck.txt; M="$B/pages/module.jsp?but=popcorn/popcorn-saisie.jsp"
# connexion (garde la session dans /tmp/ck.txt)
curl -s -c $J -b $J $B/ -o /dev/null
curl -s -c $J -b $J -X POST $B/pages/testLogin.jsp --data "identifiant=cinema&passe=cinema" -o /dev/null
# page vide : 3 clients, 2 paquets
curl -s -b $J "$M" | grep -c 'value="CLI'
# un paquet choisi (remplace POP000008 par l'id réel) : liste des jouets
curl -s -b $J -X POST "$M" --data "idclient=CLI000002&idpopcorn=POP000008" | grep -o '<td>[^<]*</td>'
# cases gardées après rechargement : "checked" doit apparaître 2 fois
curl -s -b $J -X POST "$M" --data "idclient=CLI000002&idpopcorn=POP000008&idjouet=JOT000013&idjouet=JOT000014" | grep -c ' checked'
```

### 8.3 Le service seul (transaction annulée)

Le modèle de [fonctions_metier.md](../apprentissageAPJ/fonctions_metier.md) §8, avec `ToyService`. Résultats obtenus le 12/11/2026 :

```
disponibles avant = 4
montant JOT13+JOT14 = 7000.0
vente TOY000005 total=7000.0 etat=11        ← creerToy corrigé
disponibles apres = Figurine Dune Yoyo       ← les jouets vendus ont disparu
```
Puis `rollback` : rien n'est resté en base.

### 8.4 Résultats des tests du 12/11/2026 (dans WildFly)

| Test | Résultat |
|---|---|
| page vide | 200 ; 3 clients ; 2 paquets ; bouton désactivé ; `formaction` → `popcorn-paiement.jsp` |
| Grand caramel | 4 jouets, types et prix corrects, client et paquet `selected` |
| rechargement avec 2 cases | Mini Groot et Toupie `checked` |
| passage à Petit sale avec un ancien choix | 2 jouets, aucun coché |

## 9. Si ça ne marche pas

| Symptôme | Où regarder |
|---|---|
| Page blanche | `…/wildfly-10.1.0.Final/standalone/log/server.log` : `Exception` ou `ORA-` (la requête SQL est juste au-dessus) |
| Alerte « … introuvable » | un id passé en paramètre n'existe pas (mauvais `idpopcorn` dans l'URL) |
| Aucun jouet alors que le paquet en a | ils sont tous dans des ventes non annulées : `SELECT * FROM toy WHERE etat <> 0;` |
| `ORA-00904` sur `JOUET_LIB` | la vue en base n'a pas les nouvelles colonnes : relancer le `CREATE OR REPLACE VIEW JOUET_LIB` du script |
| Les modifications de la JSP ne s'affichent pas | `ant`, ou copier la JSP dans `…/deployments/cinema.war/pages/popcorn/` |

## 10. La suite : `popcorn-paiement.jsp`

Sur le modèle de `reservation-paiement.jsp` ([04_pages_reservation.md](04_pages_reservation.md), page 2) :
1. relire `idclient`, `idpopcorn`, `idjouet[]` ;
2. récapitulatif : `ToyService.chargerElements(idJouets)` + `ToyService.calculerMontant(idJouets)` ;
3. montant reçu → monnaie à rendre ;
4. « Payer » (POST, `acte=payer`) → `ToyService.creerToy(idclient, idpopcorn, idJouets, u.getUser().getTuppleID(), null)` → redirection vers la fiche.
