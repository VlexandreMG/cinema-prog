# Cinéma — Popcorn : la fiche d'une vente (`popcorn-fiche.jsp`)

La dernière page du parcours : elle montre une vente **déjà enregistrée**, avec son client, son paquet, ses jouets et le **prix payé** pour chacun. Juste après un paiement, elle affiche aussi la **monnaie à rendre**.

Ce document suit le même plan que [06_popcorn_paiement_workflow.md](06_popcorn_paiement_workflow.md) : ce que le navigateur demande, quel code s'exécute, quelles requêtes partent vers Oracle, et ce qui s'affiche. Toutes les traces viennent de **tests réels dans WildFly le 12/11/2026** (requêtes lues dans `server.log`).

Page : [cinema-war/web/pages/popcorn/popcorn-fiche.jsp](../../cinema-war/web/pages/popcorn/popcorn-fiche.jsp)

---

## 0. Comment on arrive sur la fiche

| Chemin | URL | `recu` ? |
|---|---|---|
| **juste après « Payer »** : la redirection de `popcorn-paiement.jsp` ([06](06_popcorn_paiement_workflow.md), étape D) | `module.jsp?but=popcorn/popcorn-fiche.jsp&id=TOY000006&recu=10000.0` | oui → bandeau « monnaie à rendre » |
| **plus tard** : un lien ou l'URL tapée à la main | `module.jsp?but=popcorn/popcorn-fiche.jsp&id=TOY000006` | non → pas de bandeau |

La fiche **ne modifie rien** : elle ne fait que lire. On peut l'ouvrir, la rafraîchir ou y revenir autant de fois qu'on veut.

## 1. Ce que voit l'utilisateur (réel)

**Juste après le paiement** (avec `recu=10000.0`) :
```
Vente TOY000006
┌─────────────────────────────────────────────────────────────────┐
│ Paiement enregistré. Reçu : 10 000 Ar — monnaie à rendre : 3 000 Ar. │   ← seulement avec recu
└─────────────────────────────────────────────────────────────────┘
Client             Rakoto Jean
Paquet de popcorn  Grand caramel

Jouets (2)
  Jouet        Type        Prix payé (Ar)
  Mini Groot   Collector            5 000
  Yoyo         Classique            2 000
  Total payé                        7 000
[Nouvelle vente]
```

**Plus tard** (sans `recu`) : la même chose, **sans** le bandeau vert.

## 2. Les paramètres

| Paramètre | Obligatoire | Rôle |
|---|---|---|
| `id` | **oui** | l'id de la vente (`TOY…`) |
| `recu` | non | le montant donné par le client ; sert **uniquement** à afficher la monnaie |

## 3. Le trajet complet

```
 NAVIGATEUR                                SERVEUR (WildFly)                                   BASE (Oracle)
 ──────────                                ─────────────────                                   ─────────────
 ① GET module.jsp?but=popcorn/popcorn-fiche.jsp&id=TOY000006&recu=10000.0
                              ─────────►  ② module.jsp : session, en-tête, menu ─────────────► select * from utilisateur …
                                          ③ inclut popcorn-fiche.jsp, qui s'exécute :
                                             id = "TOY000006"
                                             ToyService.chargerToy(id) ───────────────────────► ④ select * from TOY_LIB
                                                                                                  where 1<2 and id = 'TOY000006'
                                             ◄────────────────── 1 objet ToyLib (client, paquet, total)
                                             ToyService.listerLignes(id) ─────────────────────► ⑤ select * from TOYDETAIL_LIB
                                                                                                  where 1<2 and idtoy = 'TOY000006'
                                                                                                  order by lib asc
                                             ◄────────────────── 2 objets ToyDetailLib (jouet, type, prix payé)
                                             recu = 10000.0  →  monnaie = 10000 − 7000 = 3000
                                          ⑥ écrit le HTML : bandeau, client, paquet, une <tr> par ligne, total
 ⑦ affiche la fiche  ◄──────────────────
```

**Les requêtes SQL réelles**, copiées de `server.log` :
```sql
select * from utilisateur where 1<2                                              -- module.jsp (en-tête)
select * from TOY_LIB where 1<2  and id = 'TOY000006'                            -- chargerToy
select * from TOYDETAIL_LIB where 1<2  and idtoy = 'TOY000006' order by lib asc  -- listerLignes
```
**Deux requêtes** suffisent pour toute la fiche, grâce aux deux vues `_LIB` (§4). **Aucune écriture.**

### Le code, étape par étape

```java
String id = request.getParameter("id");                     // "TOY000006"
ToyLib vente = ToyService.chargerToy(id, null);             // ④ la vente + noms du client et du paquet
ToyDetailLib[] lignes = ToyService.listerLignes(id, null);  // ⑤ les jouets vendus + prix payé

Double recu = null;
try { recu = Double.valueOf(request.getParameter("recu")); } catch (Exception ignore) { }  // absent ou invalide → null
```

| Ligne de la page | Ce qu'elle affiche | D'où vient la valeur |
|---|---|---|
| `<h1>Vente <%= vente.getId() %>` | « Vente TOY000006 » | `TOY_LIB.id` |
| `<% if (recu != null) { %>` … `recu - vente.getMontanttotal()` | le bandeau et la monnaie | le paramètre `recu` − `TOY_LIB.montanttotal` |
| `vente.getClient()` | « Rakoto Jean » | `TOY_LIB.client` (= `CLIENT.nom`) |
| `vente.getPopcorn()` | « Grand caramel » | `TOY_LIB.popcorn` (= `POPCORN.nom`) |
| `for (ToyDetailLib l : lignes)` → `l.getLib()`, `l.getTypejouet()`, `l.getPrix()` | une ligne par jouet | `TOYDETAIL_LIB` |
| `vente.getMontanttotal()` | « Total payé 7 000 » | `TOY_LIB.montanttotal` (= `TOY.montanttotal`, calculé au paiement) |

Chaque texte passe par `CinemaUtil.html(...)`, chaque montant par `CinemaUtil.montant(...)` (« 7 000 »).

## 4. Les deux vues de la fiche

### `TOY_LIB` : la vente, avec les noms
```sql
CREATE OR REPLACE VIEW TOY_LIB AS
SELECT t.id, t.idclient, c.nom AS client, t.idpopcorn, p.nom AS popcorn, t.montanttotal, t.etat
FROM TOY t
JOIN CLIENT c  ON c.id = t.idclient
JOIN POPCORN p ON p.id = t.idpopcorn;
```
| Colonne | Vient de |
|---|---|
| `id`, `idclient`, `idpopcorn`, `montanttotal`, `etat` | `TOY` (la vente elle-même) |
| `client` | `CLIENT.nom`, par la clé étrangère `TOY.idclient` |
| `popcorn` | `POPCORN.nom`, par la clé étrangère `TOY.idpopcorn` |

Ligne réelle : `TOY000006 | CLI000002 | Rakoto Jean | POP000008 | Grand caramel | 7000 | 11`

### `TOYDETAIL_LIB` : les jouets vendus, avec le prix PAYÉ
```sql
CREATE OR REPLACE VIEW TOYDETAIL_LIB AS
SELECT d.id, d.idtoy, d.idjouet, j.lib, tj.lib AS typejouet, d.prix
FROM TOYDETAIL d
JOIN JOUET j      ON j.id = d.idjouet
JOIN TYPEJOUET tj ON tj.id = j.idtypejouet;
```
| Colonne | Vient de |
|---|---|
| `id`, `idtoy`, `idjouet` | `TOYDETAIL` (la ligne) |
| `lib` | `JOUET.lib` : le nom du jouet |
| `typejouet` | `TYPEJOUET.lib` : le nom du type |
| **`prix`** | **`TOYDETAIL.prix`** : le prix **recopié au paiement**, et **pas** `TYPEJOUET.prix` |

Lignes réelles :
```
TOD000009 | TOY000006 | JOT000013 | Mini Groot | Collector | 5000
TOD000010 | TOY000006 | JOT000015 | Yoyo       | Classique | 2000
```

**Pourquoi des vues ?** La fiche affiche des **noms** (client, paquet, jouet, type) qui sont dans d'autres tables. Sans vue, il faudrait une requête par nom : 2 pour la vente, plus 2 par jouet. Avec les vues, il en faut **2 au total**. Voir [vues_lib.md](../apprentissageAPJ/vues_lib.md).

Les classes qui les lisent : [ToyLib.java](../../cinema-ejb/src/java/toy/ToyLib.java) et [ToyDetailLib.java](../../cinema-ejb/src/java/toy/ToyDetailLib.java), en **lecture seule** (pas de `construirePK`, jamais de `createObject`).

## 5. ⭐ Le prix payé ne bouge pas, même si le prix du type change

C'est la raison d'être du **prix recopié** dans `TOYDETAIL` ([01_scenario_reservation.md](01_scenario_reservation.md), « le prix est recopié »).

**Démonstration réelle (12/11/2026) :**

| Étape | `TYPEJOUET` Collector | Fiche de `TOY000006` (Mini Groot) | Saisie, Grand caramel (Figurine Dune, Collector) |
|---|---|---|---|
| avant | 5 000 | 5 000 | 5 000 |
| `UPDATE typejouet SET prix = 8000 WHERE lib = 'Collector'` | **8 000** | **5 000** ← inchangé | **8 000** ← nouveau prix |
| remis à 5 000 | 5 000 | 5 000 | 5 000 |

- La **saisie** lit `JOUET_LIB.prix`, c'est-à-dire le prix **actuel** du type : c'est le prix des **prochaines** ventes.
- La **fiche** lit `TOYDETAIL_LIB.prix`, c'est-à-dire le prix **payé** : c'est l'**historique**, qui ne doit jamais changer.

⚠ Si la vue de la fiche prenait `tj.prix` au lieu de `d.prix`, toutes les anciennes ventes afficheraient le nouveau prix : la fiche mentirait sur ce que le client a payé.

## 6. La monnaie à rendre et le paramètre `recu`

```java
Double recu = null;
try { recu = Double.valueOf(request.getParameter("recu")); } catch (Exception ignore) { }
…
<% if (recu != null) { %> … monnaie = recu - vente.getMontanttotal() … <% } %>
```
- **`recu` n'est enregistré nulle part.** Le paiement est immédiat et complet : la base garde le **total**, pas le billet donné. `recu` voyage seulement dans l'URL de la redirection, pour afficher la monnaie une fois.
- **`recu` absent ou invalide** (`recu=abc`, testé) : `Double.valueOf` lance une exception, attrapée, et `recu` reste `null`. La fiche s'affiche normalement, sans le bandeau. Une valeur bizarre dans l'URL ne casse pas la page.
- La monnaie est calculée par le **serveur** (`recu − total`), pas en JavaScript : il n'y a **aucun script** dans cette page.

## 7. Les erreurs

| Cas (testé) | Message | Pourquoi |
|---|---|---|
| `id=TOY999999` (inexistant) | « ToyLib introuvable : TOY999999 » | `CinemaUtil.parId` ne trouve aucune ligne dans `TOY_LIB` |
| pas de paramètre `id` | « Identifiant manquant pour ToyLib. » | `parId` refuse un id vide |
| `recu=abc` | pas d'erreur : fiche sans bandeau | §6 |

Le chemin d'une erreur est le même que partout : `throw` → `catch` de la page → `alert('…'); history.back();`.

Amélioration possible : le message affiche le nom technique de la classe (`ToyLib`). Pour un message plus parlant, on pourrait l'attraper dans `chargerToy` et le remplacer par « Vente introuvable : … ».

## 8. Pourquoi une page écrite à la main, et pas `PageConsulte` d'APJ ?

`PageConsulte` marche dans le cinéma ([creer_une_page.md](../apprentissageAPJ/creer_une_page.md) §5, testé). On aurait pu écrire :
```java
PageConsulte pc = new PageConsulte(new ToyLib(), request, u);   // lit "id" tout seul
out.println(pc.getHtml());
```
La fiche est écrite à la main pour trois raisons :
1. le **bandeau « monnaie à rendre »** dépend du paramètre `recu`, que `PageConsulte` ne connaît pas ;
2. elle suit **le même modèle** que `reservation-fiche.jsp` : une seule façon de faire à retenir ;
3. elle n'affiche **que** ce qui compte, sans les ids techniques (`idclient`, `etat`…) qu'il faudrait cacher un par un avec `setVisible(false)`.

Pour une **liste des ventes** (`popcorn-liste.jsp`, pas encore faite), `PageRecherche` d'APJ serait en revanche le bon choix : recherche, pagination et totaux sont fournis.

## 9. Les fichiers

| Fichier | Rôle |
|---|---|
| [popcorn-fiche.jsp](../../cinema-war/web/pages/popcorn/popcorn-fiche.jsp) | la page |
| [ToyService.java](../../cinema-ejb/src/java/toy/ToyService.java) | `chargerToy(idToy)` → `ToyLib` ; `listerLignes(idToy)` → `ToyDetailLib[]` |
| [ToyLib.java](../../cinema-ejb/src/java/toy/ToyLib.java), [ToyDetailLib.java](../../cinema-ejb/src/java/toy/ToyDetailLib.java) | lisent les vues |
| [01_tables_metier.sql](../../database/01_tables_metier.sql) | vues `TOY_LIB` et `TOYDETAIL_LIB` (en fin de fichier) |
| [popcorn-paiement.jsp](../../cinema-war/web/pages/popcorn/popcorn-paiement.jsp) | envoie vers la fiche après le paiement (`document.location.replace`) |

## 10. Rejouer les tests

### Dans le navigateur (connecté)
| # | Action | Attendu |
|---|---|---|
| 1 | faire une vente jusqu'à « Payer » | la fiche s'ouvre avec le bandeau et la bonne monnaie |
| 2 | rafraîchir la fiche | même affichage, **aucune** nouvelle vente |
| 3 | enlever `&recu=…` de l'URL | même fiche, sans bandeau |
| 4 | remplacer l'id par `TOY999999` | alerte « … introuvable », retour en arrière |
| 5 | « Nouvelle vente » | retour à la saisie, vide |

### Avec `curl`
```bash
B=http://localhost:8080/cinema; J=/tmp/ck.txt; M="$B/pages/module.jsp?but=popcorn/popcorn-fiche.jsp"
curl -s -c $J -b $J $B/ -o /dev/null
curl -s -c $J -b $J -X POST $B/pages/testLogin.jsp --data "identifiant=cinema&passe=cinema" -o /dev/null
curl -s -b $J "$M&id=TOY000006&recu=10000.0" | grep -o 'monnaie[^.]*'                    # monnaie à rendre
curl -s -b $J "$M&id=TOY000006" | grep -c 'monnaie'                                     # 0 : pas de bandeau
curl -s -b $J "$M&id=TOY999999" | grep -o "alert('[^']*'); history.back"                # introuvable
```

### En SQL : ce que la fiche devrait afficher
```sql
SELECT * FROM toy_lib WHERE id = 'TOY000006';
SELECT lib, typejouet, prix FROM toydetail_lib WHERE idtoy = 'TOY000006' ORDER BY lib;
```

### Résultats du 12/11/2026
| Test | Résultat |
|---|---|
| fiche avec `recu=10000.0` | bandeau « monnaie à rendre : 3 000 Ar », Rakoto Jean, Grand caramel, Mini Groot 5 000 + Yoyo 2 000 = 7 000 |
| fiche sans `recu` | même contenu, sans bandeau |
| `id=TOY999999` | « ToyLib introuvable : TOY999999 » |
| sans `id` | « Identifiant manquant pour ToyLib. » |
| `recu=abc` | fiche normale, sans bandeau |
| Collector passé à 8 000 | fiche : Mini Groot toujours **5 000** ; saisie : Figurine Dune à **8 000** (puis remis à 5 000) |
| requêtes SQL d'un affichage | 3 : `utilisateur` (en-tête), `TOY_LIB`, `TOYDETAIL_LIB` |

## 11. Si ça ne marche pas

| Symptôme | Cause probable | Où regarder |
|---|---|---|
| `ORA-00942` (table ou vue inexistante) | vues `TOY_LIB` / `TOYDETAIL_LIB` pas créées en base | relancer leurs `CREATE OR REPLACE VIEW` |
| la fiche affiche « Jouets (0) » alors que la vente existe | les lignes n'ont pas été écrites (ex. ancien bug `setId` au lieu de `setIdjouet` dans `creerToy`) | `SELECT * FROM toydetail WHERE idtoy = '…'` |
| une vente n'apparaît pas alors que `TOY` contient la ligne | le client ou le paquet de la vente n'existe plus (jointure `JOIN` sans partenaire) | `SELECT * FROM toy WHERE id = '…'` puis vérifier `CLIENT` / `POPCORN` |
| la fiche affiche le **nouveau** prix d'un type | la vue prend `tj.prix` au lieu de `d.prix` | la définition de `TOYDETAIL_LIB` (§4) |
| page blanche | exception non affichée | `server.log` : `Exception`, `ORA-` |
