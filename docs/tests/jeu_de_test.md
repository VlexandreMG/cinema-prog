# Jeu de test — suivre le workflow complet du cinéma

Ce guide déroule **toutes les fonctionnalités** dans un ordre qui raconte une histoire, avec **le résultat attendu à chaque étape**. Les prix sont ronds pour tout vérifier de tête.

Scripts : [99_vider_donnees.sql](../../database/99_vider_donnees.sql) puis [04_jeu_de_test.sql](../../database/04_jeu_de_test.sql).

---

## 0. Préparer la base

1. **Vider** : exécuter `99_vider_donnees.sql` dans le compte `cinema`. Le comptage final doit donner **0** partout, sauf `CAISSE = 1`.
2. **Charger** : exécuter `04_jeu_de_test.sql`. Le comptage final doit donner : 2 types de place, 2 salles, **20 places**, 3 films, 4 séances, 3 clients, 2 types de jouet, 2 paquets, 6 jouets, 3 distributeurs, 1 caisse, 0 mouvement, compteur de factures à 0.
3. Se connecter : http://localhost:8080/cinema, compte **`cinema` / `cinema`**.

⚠ Toujours **vider avant de charger**. Si `04_jeu_de_test.sql` est lancé deux fois, il y aura deux « Salle 1 », et les sous-requêtes `(SELECT id FROM SALLE WHERE nom = 'Salle 1')` échoueront (`ORA-01427` : plusieurs lignes).

## 1. Ce que contient le jeu de test

| Élément | Contenu |
|---|---|
| Types de place | **Standard 10 000**, **VIP 20 000** |
| Salle 1 (12 places) | A1–A4 et B1–B4 Standard ; **C1–C4 VIP** |
| Salle 2 (8 places) | A1–A4 Standard ; **B1–B4 VIP** |
| Films | *Dune 3* (166 min, Salle 1), *Coco* (105 min, Salle 1), *Avatar 3* (190 min, Salle 2) |
| Séances (J = aujourd'hui) | *Coco* J+1 14:00 ; *Dune 3* J+1 18:00 ; *Dune 3* J+2 20:00 ; *Avatar 3* J+1 19:00 |
| Clients | Rakoto Jean, Rasoa Marie, Randria Paul |
| Popcorn | **Grand caramel** : Mini Groot, Figurine Dune (Collector **3 000**), Toupie, Yoyo (Classique **1 000**) ; **Petit sale** : Porte-cle Coco (Collector), Sifflet (Classique) |
| Distributeurs | Netflix, Disney, Warner |
| Caisse | « Guichet principal », **solde 0** |

## 2. Le workflow, étape par étape

On garde un œil sur **l'état de la caisse** : `module.jsp?but=caisse/caisse-etat.jsp`.

### Étape 1 — Acheter un film avec une caisse vide (doit échouer)
Menu **Cinéma › Acheter un film**.
| Saisie | Valeur |
|---|---|
| Titre / durée / salle | Interstellar / 169 / Salle 2 |
| Distributeur / montant | Netflix / 30 000 |

**Attendu :** alerte « Solde insuffisant : la caisse contient 0 Ar, impossible de sortir 30 000 Ar. ». **Rien** n'est créé : *Interstellar* n'apparaît nulle part.
*Ce que ça prouve : la règle « pas de solde négatif » et le « tout ou rien » de l'achat (le film n'est pas créé).*

### Étape 2 — Première réservation : Rakoto Jean
Menu **Cinéma › Réserver**.
| Saisie | Valeur |
|---|---|
| Client / film | Rakoto Jean / Dune 3 |
| Salle | se remplit seule : **Salle 1** |
| Séance | demain 18:00 |
| Places | **A1** (Standard) + **C1** (VIP) |

**Attendu :**
- places libres proposées : **12** ; total affiché : **30 000** ;
- récapitulatif : A1 10 000 + C1 20 000 = **30 000** ;
- montant reçu **50 000** → « Payer » → fiche : **monnaie rendue 20 000** ;
- en base : 1 réservation, **facture n° `0001`** (total 30 000), **mouvement de caisse +30 000** ;
- **état de la caisse : 30 000**.

*Ce que ça prouve : réservation + facture + encaissement dans la même transaction.*

### Étape 3 — Deuxième réservation, même séance : Rasoa Marie
| Saisie | Valeur |
|---|---|
| Client / film / séance | Rasoa Marie / Dune 3 / demain 18:00 |
| Places | **A2** |

**Attendu :**
- places libres proposées : **10** (A1 et C1 ne sont plus proposées) ;
- total **10 000** ; montant reçu 10 000 → monnaie 0 ;
- **facture n° `0002`** (numéro **continu**) ;
- **état de la caisse : 40 000**.

### Étape 4 — Acheter le film, maintenant que la caisse a de l'argent
**Cinéma › Acheter un film** : Interstellar / 169 / Salle 2 / Netflix / **30 000**.

**Attendu :**
- la page affiche le solde **40 000** avant l'achat ;
- après « Acheter » : redirection vers l'état de la caisse → **10 000** ;
- *Interstellar* apparaît dans la liste des films de « Réserver » (sans séance pour l'instant).

### Étape 5 — Un deuxième achat trop cher
**Acheter un film** : Oppenheimer / 180 / Salle 1 / Warner / **20 000**.

**Attendu :** « Solde insuffisant : la caisse contient 10 000 Ar, impossible de sortir 20 000 Ar. » ; *Oppenheimer* n'est **pas** créé ; solde toujours **10 000**.

### Étape 6 — Une vente de popcorn : Randria Paul
URL : `module.jsp?but=popcorn/popcorn-saisie.jsp` (pas encore au menu).
| Saisie | Valeur |
|---|---|
| Client / paquet | Randria Paul / Grand caramel |
| Jouets | **Mini Groot** (Collector) + **Toupie** (Classique) |

**Attendu :**
- jouets proposés : **4** ; total **4 000** ;
- montant reçu 5 000 → fiche : **monnaie 1 000** ;
- revenir sur la saisie, Grand caramel : il ne reste que **Figurine Dune** et **Yoyo** ;
- **état de la caisse : toujours 10 000**. Le popcorn n'a pas de facture et n'entre pas en caisse (hors périmètre, [09_caisse.md](../conception/09_caisse.md) §10).

### Étape 7 — Les refus qu'on peut provoquer à l'écran
| Action | Attendu |
|---|---|
| Paiement d'une réservation avec un montant reçu < total | le navigateur refuse (`min`) ; avec `curl`, « Montant reçu insuffisant : il manque … Ar. » |
| Revenir en arrière après « Payer » et rafraîchir | **pas** de deuxième réservation ni de deuxième facture (`document.location.replace`) |
| Réserver une séance complète (cocher toutes les places restantes puis réessayer) | « Cette séance est complète. » |

## 3. Les chiffres attendus à la fin

| Élément | Attendu |
|---|---|
| Réservations | 2 (Rakoto : A1 + C1 ; Rasoa : A2) |
| Factures | **0001** (30 000) et **0002** (10 000) ; compteur = 2 |
| Mouvements de caisse | +30 000, +10 000, **−30 000** (Interstellar) |
| Solde de la caisse | **10 000** |
| Achats | 1 (Interstellar, Netflix, 30 000) |
| Films | 4 (*Dune 3*, *Coco*, *Avatar 3*, *Interstellar*) — pas d'*Oppenheimer* |
| Ventes de popcorn | 1 (Mini Groot + Toupie, 4 000) |

### Les vérifier en SQL
```sql
SELECT id, idclient, montanttotal, etat FROM reservation ORDER BY id;
SELECT numero, client, objet, montanttotal FROM facture ORDER BY numero;
SELECT dernier FROM compteurfacture;                                    -- 2
SELECT designation, entree, sortie, idorigine FROM mouvementcaisse ORDER BY id;
SELECT SUM(entree) - SUM(sortie) AS solde FROM mouvementcaisse WHERE etat >= 11;   -- 10000
SELECT a.id, d.nom, f.titre, a.montant FROM achat a
  JOIN distributeur d ON d.id = a.iddistributeur JOIN film f ON f.id = a.idfilm;
SELECT titre FROM film ORDER BY titre;                                  -- pas d'Oppenheimer
SELECT id, idclient, idpopcorn, montanttotal FROM toy;
```

## 4. Recommencer

Pour rejouer tout le workflow depuis le début : `99_vider_donnees.sql`, puis `04_jeu_de_test.sql`. Les ids (`RSV…`, `FAC…`, `MVC…`) continueront à partir des derniers numéros des séquences, mais les **numéros de facture** repartiront de **0001** (compteur remis à 0).
