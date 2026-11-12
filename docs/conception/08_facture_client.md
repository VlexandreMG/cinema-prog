# Cinéma — Conception : la facture client

> **Statut (12/11/2026) :** conception validée. **Implémenté et testé** : les tables, les classes `Facture` / `FactureDetail` et `FactureService.genererFacture` (§13).
> **Pas encore fait** : l'appel de `genererFacture` dans le paiement (`reserver`), et les pages.

Ce document suit la même démarche que le [scénario 1](01_scenario_reservation.md) : raconter l'usage, en tirer la base, les règles, les fonctions et les écrans. Il s'appuie sur la **fiche de lecture du socle** (§1).

---

## 1. Fiche de lecture : la facture client dans async standard

| | Dans le socle |
|---|---|
| **Classe** | `vente.Vente` (2 545 lignes) : c'est **la facture client**. Elle hérite de `FactureCF`, une mère commune aux factures client et fournisseur |
| **Lignes** | `vente.VenteDetails` : produit, quantité, PU, remise, TVA, montants HT / TVA / TTC |
| **Tables** | `VENTE`, `VENTE_DETAILS`. `VENTE` a même une colonne `IDRESERVATION` |
| **Cycle** | créée (1) → **validée** (11) → **payée** (`payer()`) |
| **Paiement** | `payerObject()` crée un **`Encaissement`** : c'est le pont vers **la caisse** |
| **Numéro légal** | `NUMEROFACTURE` = `0001/2026` : continu, sans trou, remis à 1 chaque année. Calculé par la vue `V_NUMEROFACTURE_EN_COURS` (`MAX(numéro de l'année) + 1`). **Distinct de l'id technique** (`VNT000123`) |

**Ce qu'on garde** : la mère et ses lignes, l'état, le numéro légal distinct de l'id, le lien futur avec la caisse.
**Ce qu'on laisse** : stock, livraison, ristourne, remise, TVA, écritures comptables, échéances.

## 2. Ce qui change par rapport au socle

```
SOCLE   : facture créée → validée → payée (encaissement)    on facture d'abord, on paie ensuite
CINÉMA  : réservation → paiement immédiat → FACTURE          on paie au guichet ; la facture est la preuve
```

Au cinéma, le client paie **tout de suite**. La facture n'est donc pas une demande de paiement : c'est **la preuve officielle de ce qui a été payé**. Elle naît **au moment du paiement**, dans la même transaction que la réservation.

## 3. Les décisions (prises le 12/11/2026)

| Question | Décision |
|---|---|
| Quand la facture est-elle créée ? | **Automatiquement au paiement**, dans la **même transaction** que la réservation |
| Qu'est-ce qu'on facture ? | **Les réservations seulement** (le popcorn reste à part) |
| Quel niveau de détail ? | **Total simple** : une ligne par place avec son prix, et le total. **Pas de TVA** |
| Numéro de facture ? | **Numéro légal continu par année** (`0001/2026`), en plus de l'id technique (`FAC000001`) |

## 4. Le scénario

**S-F1 — Payer une réservation produit sa facture (Guichetier)**
1. Rakoto Jean réserve A1 (Standard) et E8 (VIP) pour *Dune 3*, mardi 11/11 à 18h00. Il donne 50 000 Ar.
2. Le guichetier clique « Payer ». **En une seule opération**, le système :
   - enregistre la réservation (comme aujourd'hui) ;
   - **émet la facture n° `0003/2026`**, datée du jour, au nom de Rakoto Jean :

     | Désignation | Prix |
     |---|---|
     | Dune 3 — 11/11/2026 18:00 — Salle 1 — Place A1 (Standard) | 15 000 |
     | Dune 3 — 11/11/2026 18:00 — Salle 1 — Place E8 (VIP) | 25 000 |
     | **Total** | **40 000** |
3. La fiche de la réservation affiche « Facture n° 0003/2026 » avec un lien **« Voir la facture »**.
4. La page de la facture est **imprimable**, comme un reçu.

**S-F2 — Retrouver une facture**
Le gestionnaire ouvre la facture depuis la fiche de réservation, ou (plus tard) depuis une **liste des factures** (recherche par client, numéro, date).

**Ce qui ne doit jamais arriver :**
- une réservation payée **sans** facture, ou une facture **sans** réservation payée ;
- **deux** factures pour la même réservation ;
- deux factures avec **le même numéro**, ou un **trou** dans les numéros d'une année ;
- une facture qui **change** après son émission (prix, désignation, client).

## 5. Facture ≠ réservation

| | Réservation | Facture |
|---|---|---|
| dit… | « ces places sont prises pour cette séance » | « ce client a payé ce montant pour ces choses » |
| sert à… | savoir quelles places sont libres | prouver un paiement (document officiel) |
| peut changer ? | oui, plus tard (annulation → places libérées) | **non** : figée dès son émission |
| contient… | des **ids** (place, séance) | des **textes recopiés** (désignation, prix) |

**Pourquoi recopier la désignation en texte ?** Si demain le film change de titre, la place change de numéro ou de type, la facture doit **toujours** montrer ce qui a été vendu ce jour-là. C'est le principe du **prix recopié**, appliqué à toute la ligne.

## 6. La base

| Table | Colonnes | Rôle |
|---|---|---|
| **FACTURE** | `id` (FAC…), `numero` (`0003/2026`, **UNIQUE**), `daty`, `idclient`, **`client`** (nom recopié), `idreservation` (**UNIQUE**), **`objet`** (« Dune 3 — 11/11/2026 18:00 — Salle 1 », recopié), `montanttotal`, `etat` | la facture (la **mère**) |
| **FACTUREDETAIL** | `id` (FAD…), `idfacture`, `designation`, `prix` | une ligne de la facture (la **fille**) |
| **COMPTEURFACTURE** | `annee` (clé), `dernier` | le dernier numéro de facture émis pour chaque année |

**Pas de vue `_LIB` pour la facture.** Une `_LIB` va chercher les noms **en direct** dans les autres tables : si le client changeait de nom, ses anciennes factures changeraient aussi. Or une facture est **figée**. On **recopie** donc les textes une fois pour toutes, au moment de l'émission : le nom du client (`client`), l'objet (`objet`) et chaque ligne (`designation`). La facture s'affiche sans aucune jointure.

| Document | Vivant ou figé ? | Vue `_LIB` ? |
|---|---|---|
| réservation, places, jouets | **vivant** : on veut les noms à jour | oui |
| facture | **figé** : on veut les noms du jour du paiement | **non** : textes recopiés |

### Pourquoi ces choix
- **`idreservation` UNIQUE** : la base elle-même interdit deux factures pour une réservation, même si le code oubliait de vérifier.
- **`numero` UNIQUE** : même protection pour les numéros.
- **`idclient` ET `client`** : `idclient` sert aux **liens** (les factures d'un client), `client` sert à l'**affichage** (le nom tel qu'il était au paiement).
- **`montanttotal`** = somme des lignes = `RESERVATION.montanttotal` au moment du paiement.
- **`etat`** : 11 = émise. Plus tard, 0 = annulée (par un avoir). Une facture n'est **jamais supprimée**.

## 7. Le numéro légal, continu et sans trou

C'est le point le plus délicat de la fonctionnalité.

**Pourquoi pas une séquence ?** Une séquence ne revient jamais en arrière : une transaction annulée « perd » un numéro ([creer_une_sequence.md](../apprentissageAPJ/creer_une_sequence.md) §7). Pour un id technique, c'est sans importance. Pour un numéro de facture, un trou est **interdit** : il ferait croire qu'une facture a été supprimée.

**Pourquoi pas `MAX() + 1`, comme le socle ?** Si deux guichets paient au même instant, les deux lisent le même `MAX`, et les deux factures prennent **le même numéro**.

**La solution : un compteur verrouillé, dans la même transaction.**
```
Dans la transaction du paiement (autoCommit = false) :
  1. SELECT dernier FROM COMPTEURFACTURE WHERE annee = 2026 FOR UPDATE   ← verrou : un autre guichet ATTEND ici
  2. numero = dernier + 1 = 3  →  "0003/2026"
  3. UPDATE COMPTEURFACTURE SET dernier = 3 WHERE annee = 2026
  4. INSERT de la facture avec le numéro 0003/2026
  5. COMMIT  → le verrou est libéré, l'autre guichet lit dernier = 3 et prend 0004
     (ou ROLLBACK → l'UPDATE est annulé : le 3 n'est pas perdu, il sera redonné)
```
| Problème | Réglé par |
|---|---|
| un trou si le paiement échoue | le compteur est mis à jour **dans** la transaction : un `rollback` l'annule aussi |
| deux factures avec le même numéro | `FOR UPDATE` : un seul paiement à la fois lit et avance le compteur |
| changement d'année | une ligne par année : la 1re facture de 2027 crée la ligne `2027` et repart à `0001/2027` |

**Qui calcule quoi : le calcul est dans le métier (Java), pas dans la base.**

| Qui | Fait quoi |
|---|---|
| **Java** : `FactureService.prochainNumero(c)` | lit `dernier`, **ajoute 1**, **formate** `0003/2026`, crée la ligne de l'année si elle n'existe pas, demande la mise à jour |
| **Base** : table `COMPTEURFACTURE` | **stocke** `dernier` et **tient le verrou** (`FOR UPDATE`) jusqu'au `commit` |

Pas de trigger, pas de fonction PL/SQL, pas de vue qui calcule le numéro. C'est une différence avec le socle, qui calcule le prochain numéro **dans une vue** (`V_NUMEROFACTURE_EN_COURS`, `MAX() + 1`). Le verrou est le seul rôle laissé à Oracle : deux guichets sont deux connexions différentes, et seule la base peut faire attendre l'une pendant que l'autre travaille.

## 8. Les règles (dans `Facture.createObject`)

1. la réservation existe et est **validée** (payée) ;
2. elle n'a **pas déjà** de facture ;
3. au moins une ligne ;
4. total = somme des lignes, **et** = le total de la réservation (sinon, incohérence → refus) ;
5. compléter : `numero` (§7), `daty` = aujourd'hui, `idclient` recopié de la réservation, `etat` = 11 (**fixé explicitement** : piège du `etat = 0`, [createObject.md](../apprentissageAPJ/createObject.md) §7) ;
6. `super.createObject` → INSERT de la facture puis de ses lignes.

## 9. Les fonctions

| Fonction | Rôle |
|---|---|
| `FactureService.genererFacture(idReservation, u, c)` | construit la facture et ses lignes à partir de **l'id** de la réservation (textes recopiés), puis `createObject`. Avec la connexion `c` du paiement : même transaction |
| `FactureService.prochainNumero(c)` | le mécanisme du §7 : verrou, +1, mise à jour du compteur |
| `FactureService.chargerFacture(idFacture)` | la facture (table `FACTURE` directement : ses textes sont déjà dedans) |
| `FactureService.listerLignes(idFacture)` | ses lignes |
| `FactureService.factureDeLaReservation(idReservation)` | la facture d'une réservation, pour le lien « Voir la facture » |

### Le workflow modifié du paiement
```
reservation-paiement.jsp  « Payer »
   ▼
ReservationService.reserver(...)            ← ouvre la transaction (autoCommit = false)
   ├─ Reservation.createObject(u, c)        ← comme aujourd'hui : règles + INSERT réservation et lignes
   ├─ FactureService.genererFacture(r.getId(), u, c)  ← NOUVEAU, même connexion c
   │     ├─ prochainNumero(c)               ← compteur verrouillé
   │     └─ Facture.createObject(u, c)      ← règles + INSERT facture et lignes
   └─ commit                                ← TOUT est écrit, ou RIEN (rollback)
   ▼
reservation-fiche.jsp                       ← affiche « Facture n° 0003/2026 » + « Voir la facture »
```

## 10. Les écrans

| Page | Contenu |
|---|---|
| `facture/facture-fiche.jsp` | **nouvelle** : en-tête (cinéma, n° de facture, date), client, film/séance, lignes, total ; mise en page imprimable |
| `reservation/reservation-fiche.jsp` | **modifiée** : affiche le numéro de facture et un lien « Voir la facture » |
| `facture/facture-liste.jsp` | facultative : `PageRecherche` APJ directement sur `FACTURE` (recherche par client, numéro, date) |

## 11. Hors périmètre (pour plus tard)

- **Annuler** une facture : on ne supprime jamais, on émet un **avoir** (comme dans le socle) ;
- la **TVA** (HT / TVA / TTC) ;
- la facture du **popcorn** ;
- le lien avec la **caisse** (l'encaissement de la facture) : c'est la **fonctionnalité suivante**. La facture en sera le point de départ.

## 12. Questions encore ouvertes (à trancher en relisant)

1. **Les réservations déjà payées** (`RSV000004`…) n'ont pas de facture. On leur en génère une (rattrapage), ou on ne facture qu'à partir de maintenant ?
2. **La date de la facture** = la date du paiement (aujourd'hui) : d'accord ?
3. **L'en-tête de la facture** : nom du cinéma, adresse, NIF/STAT… On utilise ce qu'il y a dans `MASOCIETE`, ou un texte fixe ?

---

## 13. Implémentation — étape 1 : `genererFacture` et les classes (12/11/2026)

### 13.1 Les fichiers

| Fichier | Rôle |
|---|---|
| [database/01_tables_metier.sql](../../database/01_tables_metier.sql) (fin) | tables `FACTURE`, `FACTUREDETAIL`, `COMPTEURFACTURE` ; séquences + fonctions `GETSEQFACTURE` (`FAC`), `GETSEQFACTUREDETAIL` (`FAD`). **Exécuté en base** |
| [facture/Facture.java](../../cinema-ejb/src/java/facture/Facture.java) | la mère (`ClassMere`) ; `createObject` = les règles du §8 |
| [facture/FactureDetail.java](../../cinema-ejb/src/java/facture/FactureDetail.java) | la fille (`ClassFille`), liaison `idfacture` |
| [facture/FactureService.java](../../cinema-ejb/src/java/facture/FactureService.java) | `genererFacture`, `prochainNumero`, `chargerFacture`, `listerLignes`, `factureDeLaReservation` |

### 13.2 `genererFacture(idReservation, u, c)`, pas à pas

```java
// 1. LIRE la réservation et ses places, avec leurs libellés — DANS la même connexion c
ReservationLib r = ReservationService.chargerReservation(idReservation, c);        // client, film, séance, salle
ReservationDetailLib[] places = ReservationService.listerLignes(idReservation, c); // numéro, type, PRIX PAYÉ

// 2. La mère : les textes de l'en-tête sont RECOPIÉS
String objet = r.getFilm() + " — " + CinemaUtil.date(r.getDateseance()) + " " + r.getHeure() + " — " + r.getSalle();
Facture f = new Facture();
f.setIdreservation(r.getId());   f.setClient(r.getClient());   f.setObjet(objet);

// 3. Une ligne par place : désignation recopiée + prix payé (pas le prix actuel du type)
d.setDesignation(objet + " — Place " + place.getNumero() + " (" + place.getTypeplace() + ")");
d.setPrix(place.getPrix());
f.setFille(lignes);

// 4. Les règles, le numéro légal, puis INSERT facture et lignes
f.createObject(u, c);
```

- **Elle réutilise les fonctions de la réservation** (`chargerReservation`, `listerLignes`) et leurs vues `_LIB` : la réservation est vivante, on lit donc ses libellés à jour… **au moment** de la facture, puis on les recopie.
- **Elle lit avec la connexion `c`** : appelée pendant le paiement, elle voit la réservation que la même transaction vient d'insérer, même si elle n'est pas encore « commitée ».
- **Avec `c == null`**, elle ouvre sa propre transaction et fait `commit`. Elle peut donc aussi servir à **facturer après coup** une réservation déjà payée (question 1 du §12).

### 13.3 `Facture.createObject` : les règles

| # | Règle | Si elle échoue |
|---|---|---|
| ① | la réservation existe et a `etat ≥ 11` | « La réservation … n'est pas payée : facture impossible. » |
| ② | aucune facture pour cette réservation (`count(*)`) | « La réservation … a déjà une facture. » |
| ③ | au moins une ligne | « Une facture doit avoir au moins une ligne. » |
| ④ | chaque ligne a une désignation ; somme des lignes = `RESERVATION.montanttotal` | « Incohérence : total des lignes (…) différent du total de la réservation (…). » |
| ⑤ | compléter : `idclient` (de la réservation), `daty` = aujourd'hui, **`numero` = `prochainNumero(c)`**, `montanttotal`, `etat = 11` | |
| ⑥ | `super.createObject(u, c)` : INSERT `FACTURE`, puis les lignes `FACTUREDETAIL` | |

Le numéro est demandé **en dernier**, juste avant l'INSERT : une facture refusée par ① à ④ ne touche **jamais** au compteur.

### 13.4 `prochainNumero(c)` : le calcul en Java

```java
Integer dernier = lireDernierVerrouille(annee, c);         // SELECT dernier … WHERE annee = ? FOR UPDATE
if (dernier == null) {                                     // 1re facture de l'année
    insert into COMPTEURFACTURE (annee, dernier) values (?, 0)   // (clé en double → un autre l'a créée : on continue)
    dernier = lireDernierVerrouille(annee, c);
}
int prochain = dernier + 1;                                // le CALCUL, en Java
update COMPTEURFACTURE set dernier = ? where annee = ?
return String.format("%04d/%d", prochain, annee);          // 3 → "0003/2026"
```
- Écrit en **JDBC simple** (`PreparedStatement`) : `CGenUtil` sait lire, mais pas faire un `UPDATE` libre.
- **`c` est obligatoire** : sans transaction, le verrou et le « pas de trou » ne veulent plus rien dire.

### 13.5 Les tests (harnais Java, transactions **annulées** : rien n'est resté en base)

**Test 1 — deux factures, puis deux refus**
```
FACTURE FAC000001 n°0001/2026 du 2026-11-12 | Rakoto Jean | Dune 3 — 11/11/2026 18:00 — Salle 1 | total=40000.0 etat=11
   - Dune 3 — 11/11/2026 18:00 — Salle 1 — Place A1 (Standard) : 15000.0
   - Dune 3 — 11/11/2026 18:00 — Salle 1 — Place E8 (VIP) : 25000.0
FACTURE FAC000002 n°0002/2026 du 2026-11-12 | Randria Paul | Tsara ny fiainana — 13/11/2026 19:00 — Salle 2 | total=40000.0 etat=11
   - Tsara ny fiainana — 13/11/2026 19:00 — Salle 2 — Place A1 (Standard) : 15000.0
   - Tsara ny fiainana — 13/11/2026 19:00 — Salle 2 — Place C6 (VIP) : 25000.0
factureDeLaReservation(RSV000004) = 0001/2026
refus OK (deja facturee) : La réservation RSV000004 a déjà une facture.
refus OK (reservation inexistante) : ReservationLib introuvable : RSV999999
```

**Test 2 — pas de trou.** Après le `rollback` du test 1, une nouvelle transaction obtient de nouveau **`0001/2026`** : le compteur a été annulé avec le reste. (L'id technique, lui, a consommé ses numéros `FAC…` : c'est normal, il peut avoir des trous.)

**Test 3 — deux guichets en même temps.**
```
guichet 1 prend 0001/2026 (pas encore commit)
guichet 1 annule (rollback) après 2 s
guichet 2 obtient 0001/2026 après 2.012 s d'attente
```
Le guichet 2 a **attendu** que le guichet 1 ait fini. Comme le guichet 1 a annulé, le numéro 1 était de nouveau libre : pas de trou. (Si le guichet 1 avait validé, le guichet 2 aurait obtenu `0002/2026`. Ce cas n'a pas été joué, pour ne pas laisser de facture en base.)

**Après tous les tests :** `FACTURE` = 0 ligne, `COMPTEURFACTURE` = 0 ligne.

### 13.6 Prochaine étape
1. Appeler `FactureService.genererFacture(r.getId(), u, c)` dans `ReservationService.reserver`, **avant** le `commit` (§9).
2. La page `facture/facture-fiche.jsp` et le lien « Voir la facture » sur la fiche de réservation.
3. Les questions 2 et 3 du §12 (date de facture, en-tête). La question 1 (rattrapage) est techniquement possible : `genererFacture(idReservation, u, null)`.
