# Cinéma — Conception : la facture client

> **Statut : conception à valider. Aucun code n'est encore écrit.**
> Relis, corrige ce qui ne te va pas, puis on implémente.

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
| **FACTURE** | `id` (FAC…), `numero` (`0003/2026`, **UNIQUE**), `daty`, `idclient`, `idreservation` (**UNIQUE**), `montanttotal`, `etat` | la facture (la **mère**) |
| **FACTUREDETAIL** | `id` (FAD…), `idfacture`, `designation`, `prix` | une ligne de la facture (la **fille**) |
| **COMPTEURFACTURE** | `annee` (clé), `dernier` | le dernier numéro de facture émis pour chaque année |

Et pour l'affichage :
| Vue | Ajoute | Pour |
|---|---|---|
| `FACTURE_LIB` | nom du client, film, salle, séance | la fiche de la facture, et une future liste |

Pas besoin de `FACTUREDETAIL_LIB` : les lignes contiennent déjà leur texte et leur prix.

### Pourquoi ces choix
- **`idreservation` UNIQUE** : la base elle-même interdit deux factures pour une réservation, même si le code oubliait de vérifier.
- **`numero` UNIQUE** : même protection pour les numéros.
- **`idclient` dans la facture**, alors que la réservation l'a déjà : la facture doit rester lisible et juste toute seule, même si la réservation change plus tard.
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
| `FactureService.genererFacture(reservation, u, c)` | construit la facture et ses lignes à partir de la réservation (désignations recopiées), puis `createObject`. **Reçoit la connexion `c` de la réservation** : même transaction |
| `FactureService.prochainNumero(c)` | le mécanisme du §7 : verrou, +1, mise à jour du compteur |
| `FactureService.chargerFacture(idFacture)` | la facture avec ses libellés (vue `FACTURE_LIB`), pour la page |
| `FactureService.listerLignes(idFacture)` | ses lignes |
| `FactureService.factureDeLaReservation(idReservation)` | la facture d'une réservation, pour le lien « Voir la facture » |

### Le workflow modifié du paiement
```
reservation-paiement.jsp  « Payer »
   ▼
ReservationService.reserver(...)            ← ouvre la transaction (autoCommit = false)
   ├─ Reservation.createObject(u, c)        ← comme aujourd'hui : règles + INSERT réservation et lignes
   ├─ FactureService.genererFacture(r, u, c)  ← NOUVEAU, même connexion c
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
| `facture/facture-liste.jsp` | facultative : `PageRecherche` APJ sur `FACTURE_LIB` (recherche par client, numéro, date) |

## 11. Hors périmètre (pour plus tard)

- **Annuler** une facture : on ne supprime jamais, on émet un **avoir** (comme dans le socle) ;
- la **TVA** (HT / TVA / TTC) ;
- la facture du **popcorn** ;
- le lien avec la **caisse** (l'encaissement de la facture) : c'est la **fonctionnalité suivante**. La facture en sera le point de départ.

## 12. Questions encore ouvertes (à trancher en relisant)

1. **Les réservations déjà payées** (`RSV000004`…) n'ont pas de facture. On leur en génère une (rattrapage), ou on ne facture qu'à partir de maintenant ?
2. **La date de la facture** = la date du paiement (aujourd'hui) : d'accord ?
3. **L'en-tête de la facture** : nom du cinéma, adresse, NIF/STAT… On utilise ce qu'il y a dans `MASOCIETE`, ou un texte fixe ?
