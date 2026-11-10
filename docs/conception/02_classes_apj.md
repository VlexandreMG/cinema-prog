# Cinéma — Conception : les classes APJ du scénario 1

Ce document décrit les classes Java créées à partir de la base du [scénario 1](01_scenario_reservation.md). Pour la méthode pas à pas, voir le tuto [creer_une_classe_apj.md](../apprentissageAPJ/creer_une_classe_apj.md).

## Vue d'ensemble

```
Salle 1 ──── * Place * ──── 1 TypePlace
  1
  │
  *
 Film 1 ──── * Seance 1 ──── * Reservation 1 ──── * ReservationDetail * ──── 1 Place
                                   *
                                   │
                                   1
                                Client
```
Lire `A 1 ──── * B` : un A a plusieurs B, un B a un seul A. La clé étrangère est du côté `*`.

## Les fichiers

| Fichier | Classe APJ héritée | Table | Préfixe de l'id |
|---|---|---|---|
| [salle/Salle.java](../../cinema-ejb/src/java/salle/Salle.java) | `ClassMAPTable` | SALLE | `SAL` |
| [salle/TypePlace.java](../../cinema-ejb/src/java/salle/TypePlace.java) | `ClassMAPTable` | TYPEPLACE | `TPL` |
| [salle/Place.java](../../cinema-ejb/src/java/salle/Place.java) | `ClassMAPTable` | PLACE | `PLC` |
| [film/Film.java](../../cinema-ejb/src/java/film/Film.java) | `ClassMAPTable` | FILM | `FLM` |
| [film/Seance.java](../../cinema-ejb/src/java/film/Seance.java) | `ClassMAPTable` | SEANCE | `SEA` |
| [client/Client.java](../../cinema-ejb/src/java/client/Client.java) | `ClassMAPTable` | CLIENT | `CLI` |
| [reservation/Reservation.java](../../cinema-ejb/src/java/reservation/Reservation.java) | `ClassMere` | RESERVATION | `RSV` |
| [reservation/ReservationDetail.java](../../cinema-ejb/src/java/reservation/ReservationDetail.java) | `ClassFille` | RESERVATIONDETAIL | `RSD` |
| [salle/PlaceLib.java](../../cinema-ejb/src/java/salle/PlaceLib.java) | `ClassMAPTable` (lecture seule) | vue PLACE_LIB | — |
| [reservation/ReservationService.java](../../cinema-ejb/src/java/reservation/ReservationService.java) | — | — | les fonctions de l'écran, voir [03_fonctions_metier.md](03_fonctions_metier.md) |
| [utils/CinemaUtil.java](../../cinema-ejb/src/java/utils/CinemaUtil.java) | — | — | outils communs |
| [database/01_tables_metier.sql](../../database/01_tables_metier.sql) | — | toutes | tables, séquences, fonctions `GETSEQ…` |

### Pourquoi ces classes APJ ?

- **`ClassMAPTable`** : une table simple, sans lignes et sans état. C'est le cas des données de référence (salle, film, client…).
- **`ClassMere`** : un document qui a des lignes et un état. La réservation a des places (ses lignes) et un état (pour l'annulation plus tard).
- **`ClassFille`** : une ligne d'un document. Chaque place réservée est une ligne de la réservation.

## Les colonnes

Les noms sont en minuscules et collés (`idsalle`, `montanttotal`), comme dans le socle APJ : le nom de l'attribut Java est aussi celui de la colonne et de l'input à l'écran.

| Table | Colonnes |
|---|---|
| SALLE | id, nom |
| TYPEPLACE | id, libelle, prix |
| PLACE | id, idsalle, numero, idtypeplace |
| FILM | id, titre, duree (minutes), idsalle |
| SEANCE | id, idfilm, daty, heure (`"HH:mm"`) |
| CLIENT | id, nom, contact |
| RESERVATION | id, idclient, idseance, daty, montanttotal, etat |
| RESERVATIONDETAIL | id, idreservation, idplace, prix |

Deux écarts par rapport au document de conception :
- **`dateHeureDebut` devient `daty` + `heure`.** C'est la convention du socle : une date Oracle (`java.sql.Date`) et une heure en texte `"18:00"`, plus simples à saisir dans les formulaires APJ.
- **`dateReservation` devient `daty`**, le nom habituel d'une date dans APJ.

## Les contrôles (dans `createObject`)

Un contrôle lance une `Exception` : APJ annule toute la transaction et affiche le message à l'écran.

| Classe | Ce qui est refusé |
|---|---|
| Salle | nom vide |
| TypePlace | libellé vide, prix ≤ 0 |
| Place | numéro vide, salle ou type inexistant |
| Film | titre vide, durée ≤ 0, salle inexistante |
| Seance | film inexistant, date ou heure invalide, **chevauchement avec une autre séance de la même salle** |
| Client | nom vide |
| Reservation | voir ci-dessous |

### `Reservation.createObject` : la fonction `reserver` du scénario

1. Le client et la séance existent ; on **verrouille la séance** (`select … for update`) jusqu'à la fin de la transaction, puis on charge son film.
2. La séance n'a pas encore commencé.
3. Au moins une place est choisie.
4. Pour chaque place (chaque ligne) :
   - elle n'est pas choisie deux fois ;
   - elle est dans la salle du film ;
   - elle n'est pas déjà réservée pour cette séance (`Reservation.estReservee`) ;
   - son **prix est recopié depuis son type**, côté serveur.
5. `daty` = aujourd'hui, `montanttotal` = somme des prix.
6. `super.createObject` insère la réservation puis ses lignes, dans la même transaction.

`estReservee(idplace, idseance, c)` traduit la règle « c'est la réservation d'une séance qui décrit l'état d'une place » :
```sql
select count(*) from RESERVATIONDETAIL d join RESERVATION r on r.id = d.idreservation
where d.idplace = :place and r.idseance = :seance and r.etat <> 0
```

### Le chevauchement des séances

Une séance occupe sa salle de `debut` à `fin = debut + durée du film`. Deux séances `[d1, f1[` et `[d2, f2[` se chevauchent si `d1 < f2` **et** `d2 < f1`. `Seance.createObject` compare la nouvelle séance à toutes les séances des films de la même salle.

## Vérifications faites

- Les 9 classes **compilent** avec `apj-core.jar` en Java 8 (comme WildFly 10).
- Un petit programme a construit chaque objet : chacun trouve sa table, et le calcul de fin donne 18h00 + 166 min = 20h46.
- **Testé contre Oracle et dans WildFly** le 10/11/2026 (voir [l'étape 1](../etape1/00_vue_ensemble.md), sous-étape 7) : réservation créée, double réservation refusée.
- Bug corrigé pendant ces tests : la réservation est maintenant enregistrée **validée** (`etat = 11`, `ConstanteEtat.getEtatValider()`) ; avant, elle valait 0 (« annulée ») et ses places restaient libres.

## Limites connues (à traiter plus tard)

- **Deux guichets en même temps.** Le verrou sur la séance fait attendre la seconde réservation jusqu'à la fin de la première. Cela suppose qu'APJ travaille en transaction (pas d'auto-commit) pendant l'enregistrement ; à confirmer lors du premier test réel.
- **Séance qui passe minuit.** Le calcul la gère (on travaille en millisecondes), mais l'écran devra afficher la fin sur le jour suivant.
- **Modification.** Seule la création est prévue. Le piège APJ des lignes en double à la modification (fiche mémo, §4.6) n'est pas encore traité.
- **Annulation.** La colonne `etat` existe ; les règles d'annulation viendront avec leur scénario.
