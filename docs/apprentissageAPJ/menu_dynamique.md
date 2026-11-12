# Tuto — Le menu dynamique d'APJ

Comment le menu de gauche est fabriqué, comment y ajouter une entrée, comment choisir qui la voit, et pourquoi une nouvelle entrée n'apparaît pas toujours tout de suite.

Tout a été lu dans le code d'APJ (`menu.MenuDynamique` dans `apj-core2.jar`, décompilé avec CFR), dans la page `pages/elements/menu/module.jsp`, et dans la base `cinema` (le 12/11/2026). **Rien n'a été modifié** : les requêtes de la partie 7 sont des propositions.

---

## 1. À quoi sert le menu

Le menu n'est qu'un **raccourci** vers des URL. **Il ne protège rien** : une page s'ouvre par son URL (`module.jsp?but=…`) même si elle n'est dans aucun menu, du moment qu'on est connecté. On l'a fait pour tester `popcorn-saisie.jsp` et `caisse-etat.jsp` avant de leur donner une entrée.

Le menu décide seulement **quelles entrées chaque utilisateur voit**.

## 2. Les deux tables

### `MENUDYNAMIQUE` : les entrées
| Colonne | Rôle | Exemple |
|---|---|---|
| `id` | identifiant libre (texte), unique | `MENCINEMARESA` |
| `libelle` | le texte affiché (ou une clé de traduction, voir §5) | `Réserver` |
| `icone` | le nom d'une icône **Material Symbols** | `event_seat` |
| `href` | la page ouverte au clic ; `#` = une rubrique qui ne s'ouvre pas, elle contient d'autres entrées | `module.jsp?but=reservation/reservation-saisie.jsp` |
| `rang` | l'ordre parmi les entrées de même niveau | `1` |
| `niveau` | la profondeur : 1 = rubrique principale, 2 = sous-entrée… | `2` |
| `id_pere` | l'entrée parente (`NULL` au niveau 1) | `MENCINEMA` |

### `USERMENU` : qui voit quoi
| Colonne | Rôle |
|---|---|
| `id` | identifiant libre, unique |
| `idmenu` | l'entrée concernée (→ `MENUDYNAMIQUE.id`) |
| `refuser` | `'*'` = **tout le monde** ; ou l'id d'un utilisateur précis (`990001`) |
| `idrole` | ou un **rôle** (`dsi`, `dg`, `caisse`…) |
| `codeservice`, `codedir` | ou un service / une direction (via `CNAPS_USER`) |
| `interdit` | `0` (ou vide) = **autorise** ; `1` = **retire** l'entrée |

### Ce qu'il y a aujourd'hui dans la base `cinema`
```
MENUDYNAMIQUE
  MENCINEMA      Cinéma    theaters    #                                                  rang 1  niveau 1
  MENCINEMARESA  Réserver  event_seat  module.jsp?but=reservation/reservation-saisie.jsp  rang 1  niveau 2  père MENCINEMA
USERMENU
  USMCINEMA      refuser='*'  → MENCINEMA      interdit 0
  USMCINEMARESA  refuser='*'  → MENCINEMARESA  interdit 0
```
Ces lignes ont été créées par [00_socle.sql](../../database/00_socle.sql) à l'étape 1.

## 3. L'arbre : `niveau`, `id_pere`, `rang`

```
Cinéma                     niveau 1, id_pere NULL,        rang 1
 ├─ Réserver               niveau 2, id_pere MENCINEMA,   rang 1
 ├─ Vendre du popcorn      niveau 2, id_pere MENCINEMA,   rang 2   (proposition)
 └─ État de la caisse      niveau 2, id_pere MENCINEMA,   rang 3   (proposition)
```
- **`id_pere`** dit **sous quelle entrée** on se range ; **`niveau`** doit valoir le niveau du père + 1.
- **`rang`** donne l'**ordre** des frères (les entrées qui ont le même père).
- Une rubrique (`href = '#'`) ne fait qu'ouvrir ses enfants.

## 4. Qui voit quoi : les règles de `USERMENU`

APJ lance deux requêtes pour l'utilisateur connecté (code réel de `getElementMenu`) :
```sql
-- les entrées AUTORISÉES
select MENUDYNAMIQUE.* from MENUDYNAMIQUE inner join usermenu on usermenu.IDMENU = MENUDYNAMIQUE.ID
where (interdit = 0 OR interdit is null)
  and (refuser = '*' or refuser = '<id de l'utilisateur>' OR idrole = '<son rôle>'
       OR CODESERVICE = '<son service>' OR CODEDIR = '<sa direction>')
-- les entrées INTERDITES : la même, avec interdit = 1
```

Puis :
1. **Une entrée autorisée rend visibles ses parents ET ses enfants** (`getParentsAndFils`) :
   - autoriser `MENCINEMA` montre **tout** ce qui est dessous ;
   - autoriser seulement `MENCINEMARESA` montre aussi son père `MENCINEMA`, sinon on ne pourrait pas l'atteindre.
2. **Une entrée interdite est retirée**, même si une autre règle l'autorise : `interdit = 1` gagne.

| Je veux… | Ligne `USERMENU` |
|---|---|
| que tout le monde voie l'entrée | `refuser = '*'`, `interdit = 0` |
| qu'un seul rôle la voie | `refuser = NULL`, `idrole = 'dsi'`, `interdit = 0` (et **pas** de ligne `'*'`) |
| qu'un utilisateur précis la voie | `refuser = '990001'`, `interdit = 0` |
| la cacher à un rôle alors que tout le monde la voit | une 2ᵉ ligne : `idrole = 'caisse'`, `interdit = 1` |

⚠ **Une entrée sans aucune ligne `USERMENU` ne s'affiche pour personne.** C'est l'oubli le plus fréquent.

## 5. Comment le menu est construit, à chaque page

```
module.jsp
  └─ inclut pages/elements/menu/module.jsp
        ├─ session "MENU" existe déjà ?  ──oui──► on réutilise l'arbre de la session
        │                                 non
        ▼
        MenuDynamique.getElementMenu(request, utilisateur, cnapsUser)
          ├─ tabMenu = TOUTES les entrées
          │     ├─ déjà en mémoire de l'APPLICATION (ServletContext "tabMenu") ? → on la réutilise
          │     └─ sinon : select * from MENUDYNAMIQUE order by niveau, rang  → gardée en mémoire
          ├─ les 2 requêtes du §4 (autorisées / interdites)
          └─ construit l'arbre par niveau
        session "MENU" = l'arbre
        ▼
        MenuDynamique.renderMenuJson(arbre) → du JSON (id, libelle, icone, href, niveau, fils)
        ▼
        le JavaScript de la page dessine le menu à partir de ce JSON
```

Deux détails utiles :
- **`currentMenu`** : APJ ajoute tout seul `&currentMenu=<id>` au `href` de chaque entrée (ex. `module.jsp?but=reservation/reservation-saisie.jsp&currentMenu=MENCINEMARESA`). La page le garde en session pour **surligner** l'entrée en cours. Tu n'as pas à l'écrire dans `href`.
- **le libellé peut être traduit** : si `libelle` est une clé du fichier `text.properties`, c'est la traduction qui s'affiche ; sinon, le texte tel quel.

## 6. ⚠ Pourquoi une nouvelle entrée n'apparaît pas tout de suite : DEUX mémoires

| Mémoire | Contient | Vidée quand… |
|---|---|---|
| **application** (`ServletContext`, attribut `tabMenu`) | **toutes** les entrées de `MENUDYNAMIQUE` | l'application est **redéployée** (`ant`) ou WildFly redémarre |
| **session** (attribut `MENU`) | l'arbre déjà filtré pour l'utilisateur | on se **déconnecte** |

Conséquences :
- une **nouvelle entrée** (`INSERT` dans `MENUDYNAMIQUE`) n'apparaît qu'après un **redéploiement ET une reconnexion**. Se reconnecter seulement ne suffit pas : `tabMenu`, gardée en mémoire de l'application, ne la connaît pas encore ;
- un **changement de droits seulement** (`INSERT` dans `USERMENU`, pour une entrée déjà connue) : une **reconnexion** suffit, car les requêtes du §4 sont relancées à chaque construction du menu.

> Correction : [creer_une_page.md](creer_une_page.md) §7 disait seulement « se déconnecter puis se reconnecter ». C'est vrai pour un changement de droits, mais pas pour une **nouvelle** entrée, qui demande aussi un redéploiement.

**Procédure complète pour une nouvelle entrée :**
1. `INSERT` dans `MENUDYNAMIQUE` **et** dans `USERMENU`, puis `COMMIT` ;
2. redéployer : `JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant` (ou redémarrer WildFly) ;
3. se déconnecter, puis se reconnecter.

## 7. Proposition pour le cinéma (à exécuter toi-même)

Les pages qui méritent une entrée sont **les points de départ**. Les pages qu'on atteint par un bouton (`…-paiement.jsp`, `…-fiche.jsp`) n'ont **pas** d'entrée : ouvertes sans leurs paramètres, elles afficheraient une erreur.

| Entrée | Page | Existe ? |
|---|---|---|
| Réserver | `reservation/reservation-saisie.jsp` | ✅ déjà dans le menu |
| Vendre du popcorn | `popcorn/popcorn-saisie.jsp` | ✅ page faite |
| État de la caisse | `caisse/caisse-etat.jsp` | 🔨 en construction |
| (Factures) | `facture/facture-liste.jsp` | ❌ pas encore de page : pas d'entrée |

```sql
-- Les entrées, sous la rubrique « Cinéma » (MENCINEMA), après « Réserver » (rang 1)
INSERT INTO MENUDYNAMIQUE (id, libelle, icone, href, rang, niveau, id_pere)
VALUES ('MENCINEMAPOP', 'Vendre du popcorn', 'fastfood',
        'module.jsp?but=popcorn/popcorn-saisie.jsp', 2, 2, 'MENCINEMA');
INSERT INTO MENUDYNAMIQUE (id, libelle, icone, href, rang, niveau, id_pere)
VALUES ('MENCINEMACAISSE', UNISTR('\00C9tat de la caisse'), 'point_of_sale',
        'module.jsp?but=caisse/caisse-etat.jsp', 3, 2, 'MENCINEMA');

-- Qui les voit : tout le monde
INSERT INTO USERMENU (id, refuser, idmenu, idrole, codeservice, codedir, interdit)
VALUES ('USMCINEMAPOP', '*', 'MENCINEMAPOP', NULL, NULL, NULL, 0);
INSERT INTO USERMENU (id, refuser, idmenu, idrole, codeservice, codedir, interdit)
VALUES ('USMCINEMACAISSE', '*', 'MENCINEMACAISSE', NULL, NULL, NULL, 0);
COMMIT;
```
Puis **redéployer et se reconnecter** (§6).

- `UNISTR('\00C9tat…')` écrit le « É » sans dépendre de l'encodage du terminal (`\00C9` = É, `\00E9` = é).
- Les icônes viennent de **Material Symbols** (le nom en minuscules, avec des `_`) : `fastfood`, `point_of_sale`, `receipt_long` (facture), `event_seat`, `theaters`, `local_movies`, `shopping_cart`.
- Les ids suivent la convention du projet : `MENCINEMA…` pour les entrées, `USMCINEMA…` pour les droits.

**Variante : la caisse visible seulement par le gestionnaire.** On remplace la ligne `'*'` de la caisse par une ligne sur le rôle :
```sql
INSERT INTO USERMENU (id, refuser, idmenu, idrole, codeservice, codedir, interdit)
VALUES ('USMCINEMACAISSE', NULL, 'MENCINEMACAISSE', 'dsi', NULL, NULL, 0);
```
⚠ Ça **cache** l'entrée, mais **ne protège pas** la page : un autre utilisateur qui tape l'URL l'ouvre quand même (§1). Pour vraiment protéger une page, il faudrait vérifier le rôle **dans la page** :
```java
UserEJB u = (UserEJB) session.getAttribute("u");
if (!"dsi".equals(u.getUser().getIdrole())) throw new Exception("Accès réservé au gestionnaire.");
```

**Dans quel script ?** Le menu du cinéma est déjà dans `00_socle.sql` (§6 et §7 de ce script). Pour rester au même endroit, on ajouterait ces `INSERT` à la suite. Ou bien dans un nouveau script `03_menu.sql`, si tu préfères séparer le menu.

## 8. Vérifier

```sql
-- l'arbre complet, dans l'ordre
SELECT LPAD(' ', (niveau - 1) * 3) || libelle AS menu, id, href, rang
FROM menudynamique ORDER BY niveau, rang;

-- les entrées SANS aucun droit (invisibles pour tout le monde)
SELECT m.id, m.libelle FROM menudynamique m
WHERE NOT EXISTS (SELECT 1 FROM usermenu u WHERE u.idmenu = m.id);

-- ce que voit le compte cinema (refuser 990001, rôle dsi) : les entrées autorisées
SELECT m.id, m.libelle FROM menudynamique m JOIN usermenu u ON u.idmenu = m.id
WHERE (u.interdit = 0 OR u.interdit IS NULL)
  AND (u.refuser = '*' OR u.refuser = '990001' OR u.idrole = 'dsi');
```

## 9. Les pièges

| Symptôme | Cause | Solution |
|---|---|---|
| la nouvelle entrée n'apparaît pas, même après reconnexion | `tabMenu` est en mémoire de l'**application** | **redéployer**, puis se reconnecter (§6) |
| l'entrée n'apparaît pour personne | aucune ligne `USERMENU` | ajouter une ligne (`refuser = '*'`) |
| l'entrée apparaît au mauvais endroit, ou pas du tout sous sa rubrique | `id_pere` faux, ou `niveau` ≠ niveau du père + 1 | corriger `id_pere` / `niveau` |
| les entrées ne sont pas dans le bon ordre | `rang` | renuméroter les frères |
| un carré ou un mot à la place de l'icône | nom d'icône inconnu de Material Symbols | un nom de la liste du §7 |
| accents abîmés dans le libellé | encodage du script SQL | `UNISTR('\00E9…')` |
| le clic ouvre une page en erreur | entrée vers une page qui attend des paramètres (`…-fiche.jsp`) | ne mettre au menu que des pages de départ |
| une page « réservée » s'ouvre quand même par l'URL | le menu cache, il ne protège pas | contrôler le rôle dans la page (§7) |

## 10. Checklist pour une nouvelle entrée

1. ☐ La page existe et s'ouvre **sans paramètre** (c'est une page de départ).
2. ☐ `MENUDYNAMIQUE` : `id` unique, `libelle`, `icone` (Material Symbols), `href` = `module.jsp?but=…`, `niveau` = niveau du père + 1, `id_pere`, `rang`.
3. ☐ `USERMENU` : au moins une ligne (`refuser = '*'`, ou un rôle), `interdit = 0`.
4. ☐ `COMMIT`.
5. ☐ **Redéployer**, puis **se reconnecter**.
6. ☐ Si l'accès doit être réservé : contrôle du rôle **dans la page**.
