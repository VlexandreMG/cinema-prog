# Exemple — Des INSERT jusqu'à l'écran : `reservation-saisie.jsp` pas à pas

Ce document part d'**un petit jeu de données** et suit la page [reservation-saisie.jsp](../../cinema-war/web/pages/reservation/reservation-saisie.jsp) **état par état** : pour chaque élément affiché, on voit **quelle ligne de la page** le produit et **quel `INSERT`** il vient de la base.

Rappel : la page a deux parties ([creer_une_page.md](creer_une_page.md)) :
- **lignes 18 à 53** : la **préparation** (lire les choix, appeler le service, garder un écran cohérent) ;
- **lignes 54 à 154** : l'**affichage** (le HTML et ses boucles `for`), plus un petit script (lignes 156 à 188).

---

## 1. Le jeu de données de l'exemple

⚠ **Exemple pour comprendre, à ne pas exécuter tel quel.** Les ids sont raccourcis pour être lisibles (`CLI1`, `FLM1`…). Dans la vraie base, ils passent par les séquences (`CLI000002`…) : pour charger de vraies données, utiliser [04_jeu_de_test.sql](../../database/04_jeu_de_test.sql). On suppose qu'aujourd'hui est le **12/11/2026**.

```sql
-- (1) Les types de place : leur prix
INSERT INTO TYPEPLACE (id, libelle, prix) VALUES ('TPL1', 'Standard', 10000);
INSERT INTO TYPEPLACE (id, libelle, prix) VALUES ('TPL2', 'VIP',      20000);

-- (2) Une salle et ses places
INSERT INTO SALLE (id, nom) VALUES ('SAL1', 'Salle 1');
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC1', 'SAL1', 'A1', 'TPL1');
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC2', 'SAL1', 'A2', 'TPL1');
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC3', 'SAL1', 'C1', 'TPL2');

-- (3) Deux films, tous les deux dans la Salle 1
INSERT INTO FILM (id, titre, duree, idsalle) VALUES ('FLM1', 'Dune 3', 166, 'SAL1');
INSERT INTO FILM (id, titre, duree, idsalle) VALUES ('FLM2', 'Coco',   105, 'SAL1');

-- (4) Les séances : deux pour Dune 3, une pour Coco
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA1', 'FLM1', DATE '2026-11-13', '18:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA2', 'FLM1', DATE '2026-11-14', '20:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA3', 'FLM2', DATE '2026-11-13', '14:00');

-- (5) Deux clients
INSERT INTO CLIENT (id, nom, contact) VALUES ('CLI1', 'Rakoto Jean', '034 11 222 33');
INSERT INTO CLIENT (id, nom, contact) VALUES ('CLI2', 'Rasoa Marie', '032 44 555 66');

-- (6) Une réservation DÉJÀ payée : Rasoa a pris la place A2 pour la séance SEA1
INSERT INTO RESERVATION (id, idclient, idseance, daty, montanttotal, etat) VALUES ('RSV1', 'CLI2', 'SEA1', DATE '2026-11-12', 10000, 11);
INSERT INTO RESERVATIONDETAIL (id, idreservation, idplace, prix) VALUES ('RSD1', 'RSV1', 'PLC2', 10000);
```

Chaque bloc (1) à (6) sera retrouvé plus bas, sur l'écran.

## 2. État 1 — Première visite (aucun choix)

**URL :** `module.jsp?but=reservation/reservation-saisie.jsp` : aucun paramètre.

### La préparation (lignes 18 à 53)
| Ligne | Code | Valeur obtenue | Vient de |
|---|---|---|---|
| 24 | `idclient = request.getParameter("idclient")` | `null` | URL : pas de paramètre |
| 25 | `idfilm = request.getParameter("idfilm")` | `null` | |
| 26 | `idseance = request.getParameter("idseance")` | `null` | |
| 27-29 | `coches` / `placesCochees` | `null` / vide | |
| 32 | `clients = listerClients(null)` | `[CLI1 Rakoto Jean, CLI2 Rasoa Marie]` | **INSERT (5)** |
| 33 | `films = listerFilms(null)` | `[FLM2 Coco, FLM1 Dune 3]` (triés par titre) | **INSERT (3)** |
| 34-36 | `salle`, `seances`, `places` | `null`, vide, vide | valeurs par défaut |
| 38 → 47 | `if (idfilm …)` est faux → `else { idseance = null; }` | | |
| 50 | `if (idseance != null)` est faux | `places` reste vide | |

### L'affichage (lignes 54 à 154)
| Élément | Lignes | Ce qui s'affiche | Vient de |
|---|---|---|---|
| liste **Client** | 64-72 | « -- Choisir -- », « Rakoto Jean », « Rasoa Marie » ; **aucun** `selected` | `clients` ← **(5)** |
| liste **Film** | 77-85 | « -- Choisir -- », « Coco (105 min) », « Dune 3 (166 min) » | `films` ← **(3)** |
| **Salle** | 90-91 | vide (`salle == null`), en `readonly` | |
| liste **Séance** | 98-107 | seulement « -- Choisir -- », et `disabled` (ligne 99 : `idfilm == null`) | |
| tableau **Places** | 114-140 | **rien** : le `if (idseance != null)` de la ligne 114 est faux | |
| **Total** | 145 | `0` | |

Le HTML réellement produit pour la liste « Client » (lignes 64-72, après exécution) :
```html
<select name="idclient" id="idclient" class="form-control">
    <option value="">-- Choisir --</option>
    <option value="CLI1">Rakoto Jean</option>
    <option value="CLI2">Rasoa Marie</option>
</select>
```
**La boucle `for` de la ligne 66 a écrit une `<option>` par ligne de l'INSERT (5).** `value` = l'id (ce qui sera **envoyé**), le texte = le nom (ce qui est **affiché**).

## 3. État 2 — On choisit Rakoto Jean, puis le film « Dune 3 »

Choisir un **client** ne fait rien de spécial : la liste n'a pas d'`onchange`.
Choisir un **film** déclenche `onchange="changerFilm()"` (ligne 77) :
1. `changerFilm()` (lignes 164-169) vide la séance et décoche les places ;
2. `recharger()` (lignes 158-161) remet `but` sur la saisie et **envoie le formulaire en GET** ;
3. le navigateur redemande la page avec les choix :
```
module.jsp?but=reservation/reservation-saisie.jsp&idclient=CLI1&idfilm=FLM1
```
Il n'y a **pas** de `idseance` dans l'URL : à l'état 1, la liste « Séance » était `disabled` (ligne 99), et **un champ `disabled` n'est pas envoyé**.

La page s'exécute **de nouveau, depuis le début**, avec ces paramètres.

### La préparation
| Ligne | Code | Valeur obtenue | Vient de |
|---|---|---|---|
| 24 | `idclient` | `"CLI1"` | URL |
| 25 | `idfilm` | `"FLM1"` | URL |
| 26 | `idseance` | `null` | absent de l'URL (champ `disabled`) |
| 38 | `if (idfilm != null && !idfilm.isEmpty())` | **vrai** | |
| 39 | `salle = salleDuFilm("FLM1")` | `SAL1 Salle 1` | **(3)** `FILM.idsalle = 'SAL1'` → **(2)** `SALLE` |
| 40 | `seances = listerSeances("FLM1")` | `[SEA1 13/11 18:00, SEA2 14/11 20:00]` | **(4)** : seulement celles de `FLM1` |
| 42-45 | boucle : une séance a-t-elle l'id `null` ? | non → `seanceValide = false` | |
| 46 | `if (!seanceValide) idseance = null;` | `idseance` reste `null` | |

(Si on change de film **alors qu'une séance était déjà choisie**, la liste n'est plus `disabled` : `changerFilm()` la vide d'abord, et l'URL contient `idseance=` (vide). La boucle donne le même résultat : `idseance = null`.)
| 50 | `if (idseance != null)` est faux | `places` reste vide | |

### L'affichage
| Élément | Ce qui s'affiche | Pourquoi |
|---|---|---|
| **Client** | « Rakoto Jean » **sélectionné** | ligne 68 : `c.getId().equals(idclient)` vaut vrai pour `CLI1` → écrit `selected` |
| **Film** | « Dune 3 (166 min) » **sélectionné** | ligne 81, même principe avec `idfilm` |
| **Salle** | **« Salle 1 »**, `readonly` | ligne 91 : `salle.getNom()` ← **(2)** |
| **Séance** | « 13/11/2026 à 18:00 », « 14/11/2026 à 20:00 » ; **plus `disabled`** | lignes 101-106 : une `<option>` par séance ← **(4)** ; `SEA3` (Coco) n'y est pas |
| tableau **Places** | rien | ligne 114 : `idseance` vaut `null` |

**Les `selected` (lignes 68 et 81) sont ce qui fait « garder » les choix après le rechargement.** Sans eux, la page rechargée remettrait « -- Choisir -- » partout.

## 4. État 3 — On choisit la séance du 13/11 à 18:00

`onchange="recharger()"` (ligne 98) envoie de nouveau le formulaire :
```
module.jsp?but=reservation/reservation-saisie.jsp&idclient=CLI1&idfilm=FLM1&idseance=SEA1
```

### La préparation
| Ligne | Code | Valeur obtenue | Vient de |
|---|---|---|---|
| 26 | `idseance` | `"SEA1"` | URL |
| 39-40 | `salle`, `seances` | comme à l'état 2 | |
| 42-45 | boucle : `SEA1` est-elle dans `seances` ? | **oui** → `seanceValide = true` | |
| 46 | `idseance` reste `"SEA1"` | | |
| 51 | `places = listerPlacesLibres("SEA1")` | `[PLC1 A1 Standard 10000, PLC3 C1 VIP 20000]` | **(2)** + **(1)**, **moins (6)** |

Ce que fait `listerPlacesLibres("SEA1")` (dans le service, **pas** dans la page) :
```sql
select * from PLACE_LIB
where idsalle = 'SAL1'                                       -- la salle du film de SEA1 : (3)
  and id not in (select d.idplace from RESERVATIONDETAIL d
                 join RESERVATION r on r.id = d.idreservation
                 where r.idseance = 'SEA1' and r.etat <> 0)  -- les places déjà prises : (6) → PLC2
order by numero asc
```
| Place de la salle (INSERT 2) | Déjà réservée pour SEA1 (INSERT 6) ? | Proposée ? |
|---|---|---|
| PLC1 A1 | non | ✅ |
| PLC2 A2 | **oui** (Rasoa, RSV1) | ❌ |
| PLC3 C1 | non | ✅ |

### L'affichage
| Élément | Lignes | Ce qui s'affiche | Vient de |
|---|---|---|---|
| **Séance** | 103 | « 13/11/2026 à 18:00 » **sélectionnée** | `idseance` |
| titre « Places libres » | 114-115 | affiché : `idseance != null` | |
| tableau | 124-136 | **2 lignes** : A1 / Standard / 10 000 et C1 / VIP / 20 000. **A2 n'apparaît pas** | `places` ← **(2) + (1) − (6)** |

Le HTML produit pour la ligne de A1 (lignes 125-135) :
```html
<tr>
    <td><input type="checkbox" name="idplace" class="case-place"
               value="PLC1" data-prix="10000.0" onchange="majTotal()"></td>
    <td>A1</td>
    <td>Standard</td>
    <td class="text-right">10 000</td>
</tr>
```
| Morceau | Rôle | Vient de |
|---|---|---|
| `name="idplace"` | toutes les cases ont **le même nom** → envoyées comme un tableau (`getParameterValues`, ligne 27) | |
| `value="PLC1"` | ce qui sera envoyé si la case est cochée | `PLACE.id` ← **(2)** |
| `data-prix="10000.0"` | le prix, gardé dans la page pour le total JavaScript | `TYPEPLACE.prix` ← **(1)**, via la vue `PLACE_LIB` |
| `A1`, `Standard`, `10 000` | l'affichage | `numero` ← **(2)**, `libelle` et `prix` ← **(1)** |

## 5. État 4 — On coche A1 et C1 (sans rechargement)

Cocher une case déclenche `onchange="majTotal()"` (ligne 130). **Rien ne part au serveur** : c'est le JavaScript du navigateur (lignes 172-177) :
```
cases cochées : A1 (data-prix 10000) + C1 (data-prix 20000)
total = 0 + 10000 + 20000 = 30000  →  champ Total (ligne 145) : « 30 000 »
```
Le Total est `readonly` et n'a **pas de `name`** : il n'est **jamais envoyé**. Le vrai total sera **recalculé par le serveur** au paiement, à partir des prix en base (règle de `Reservation.createObject`).

## 6. État 5 — On clique sur « Continuer vers le paiement »

`continuer()` (lignes 180-186) :
1. vérifie qu'il y a un client, une séance et au moins une case cochée (sinon une alerte) ;
2. change `but` vers **la page de paiement** (ligne 184) ;
3. envoie le formulaire :
```
module.jsp?but=reservation/reservation-paiement.jsp&idclient=CLI1&idfilm=FLM1&idseance=SEA1&idplace=PLC1&idplace=PLC3
```
`idplace` apparaît **deux fois** : une par case cochée. La page de paiement les relira avec `getParameterValues("idplace")` → `{"PLC1", "PLC3"}`.

Ce qui est envoyé, et ce qui ne l'est pas :
| Champ | `name` ? | Envoyé ? |
|---|---|---|
| Client, Film, Séance | oui | ✅ `idclient`, `idfilm`, `idseance` |
| cases cochées | oui (`idplace`) | ✅ seulement celles **cochées** |
| `but` (caché) | oui | ✅ dit à `module.jsp` quelle page afficher |
| Salle | **non** (seulement `id`) | ❌ le serveur la retrouve à partir du film |
| Total | **non** | ❌ le serveur le recalcule |

## 7. Le cas « on change de film alors qu'une séance était choisie »

À l'état 3, on choisit maintenant « Coco ». `changerFilm()` vide la séance avant d'envoyer, mais imaginons qu'elle arrive quand même (lien copié, bouton « Précédent ») :
```
…&idfilm=FLM2&idseance=SEA1
```
| Ligne | Ce qui se passe |
|---|---|
| 40 | `seances = listerSeances("FLM2")` → `[SEA3 13/11 14:00]` ← **(4)** |
| 42-45 | `SEA1` est-elle dans `[SEA3]` ? **non** → `seanceValide = false` |
| 46 | `idseance = null` : on **oublie** la séance de Dune 3 |
| 50 | pas de places affichées |

**C'est le rôle de la boucle `seanceValide` (lignes 42-46)** : empêcher l'écran d'afficher les places d'une séance qui **n'appartient pas** au film choisi. C'est de la logique **d'affichage**. La vraie garantie métier reste dans `Reservation.createObject`, qui refuse au paiement une place hors de la salle du film.

## 8. Le récapitulatif : d'où vient chaque élément de l'écran

| Élément de l'écran | Lignes (affichage) | Variable (préparation) | Fonction du service | INSERT d'origine |
|---|---|---|---|---|
| options du **Client** | 64-72 | `clients` (l. 32) | `listerClients` | (5) `CLIENT` |
| client **sélectionné** | 68 | `idclient` (l. 24) | — (URL) | — |
| options du **Film** | 77-85 | `films` (l. 33) | `listerFilms` | (3) `FILM` |
| **Salle** (`readonly`) | 90-91 | `salle` (l. 39) | `salleDuFilm` | (3) `FILM.idsalle` → (2) `SALLE.nom` |
| options de la **Séance** | 98-107 | `seances` (l. 40) | `listerSeances` | (4) `SEANCE` du film |
| Séance **désactivée** | 99 | `idfilm` (l. 25) | — | — |
| « Aucune séance à venir » | 108-110 | `seances.length == 0` | — | (4) : aucune pour ce film |
| lignes du tableau **Places** | 124-136 | `places` (l. 51) | `listerPlacesLibres` | (2) `PLACE` + (1) `TYPEPLACE`, **moins** (6) `RESERVATIONDETAIL` |
| « Cette séance est complète » | 116-117 | `places.length == 0` | — | (6) a pris toutes les places |
| cases **cochées** | 129 | `placesCochees` (l. 27-29) | — | — (URL) |
| **Total** | 145 + JS 172-177 | — | — | (1) `TYPEPLACE.prix`, via `data-prix` |

## 9. À retenir

1. **La page s'exécute en entier à chaque rechargement**, du haut vers le bas, avec les paramètres de l'URL.
2. **La préparation décide, l'affichage montre** : toutes les décisions (quoi charger, quoi oublier) sont en haut ; le HTML en bas ne fait que des boucles et des `if` sur des variables déjà prêtes.
3. **Chaque liste vient d'une fonction du service**, et chaque fonction lit **une ou plusieurs tables** remplies par des `INSERT`.
4. **`selected` et `checked` gardent les choix** d'un rechargement à l'autre.
5. **Seuls les champs qui ont un `name` sont envoyés.** Salle et Total n'en ont pas : ce sont des affichages.
6. **Les places libres = les places de la salle, moins celles déjà réservées pour CETTE séance.** La page ne le calcule pas : elle le **demande** au service.
