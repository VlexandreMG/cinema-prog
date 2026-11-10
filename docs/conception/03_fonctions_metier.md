# Cinéma — Conception : les fonctions métier de la réservation

Ce document décrit les fonctions de l'écran de réservation, telles qu'elles sont dessinées sur le croquis du [scénario 1](01_scenario_reservation.md). Elles s'appuient sur les [classes APJ](02_classes_apj.md).

Code : [reservation/ReservationService.java](../../cinema-ejb/src/java/reservation/ReservationService.java)

## L'écran et ses fonctions

```
Client  [ ▼ ]   Film [ ▼ ] ──► Salle [ lecture seule ]   Séance [ ▼ ]

Liste place [ ☐ A1 Standard 15 000 | ☐ F4 VIP 25 000 ... ]

Prix (total) [ lecture seule ]                         [ Réserver ]
```

| Champ de l'écran | Fonction | Renvoie | Quand l'appeler |
|---|---|---|---|
| Client | `listerClients(c)` | `Client[]`, par nom | à l'ouverture de l'écran |
| Film | `listerFilms(c)` | `Film[]`, par titre | à l'ouverture de l'écran |
| Salle | `salleDuFilm(idFilm, c)` | `Salle` | quand on choisit un film |
| Séance | `listerSeances(idFilm, c)` | `Seance[]` à venir, de la plus proche à la plus lointaine | quand on choisit un film |
| Liste place | `listerPlacesLibres(idSeance, c)` | `PlaceLib[]` (numéro, type, prix), par numéro | quand on choisit une séance |
| Prix | `calculerMontant(idPlaces, c)` | `double`, le total | quand on coche ou décoche une place |
| Réserver | `reserver(idClient, idSeance, idPlaces, u, c)` | `Reservation` créée (id, total) | au clic sur le bouton |

L'ordre des dépendances suit les flèches du croquis : **Film → Salle et Séance → Places → Prix → Réserver**.

## Le paramètre `Connection c`

Toutes les fonctions suivent la convention du socle APJ (même modèle que `Prevision.modifierPP` dans akoho) :

| Appel | Comportement |
|---|---|
| `c == null` | la fonction ouvre sa connexion (`new UtilDB().GetConn()`), puis la ferme. `reserver` fait en plus `commit`, ou `rollback` en cas d'erreur. |
| `c` fourni | la fonction travaille dans la transaction de l'appelant, sans commit ni fermeture. C'est l'appelant qui décide. |

Depuis une JSP, on passe donc simplement `null` :
```java
Client[] clients = ReservationService.listerClients(null);
```

## Détail des fonctions

### `listerSeances(idFilm, c)`
- SQL : les séances du film dont la date est aujourd'hui ou plus tard (`daty >= trunc(sysdate)`).
- Java : on retire celles d'aujourd'hui qui ont déjà commencé (`Seance.calculerDebut()`).
- On ne propose donc que des séances encore réservables.

### `listerPlacesLibres(idSeance, c)`
Les places de la salle du film, **sauf** celles déjà réservées pour cette séance :
```sql
select * from PLACE_LIB
where idsalle = :salleDuFilm
  and id not in (select d.idplace from RESERVATIONDETAIL d
                 join RESERVATION r on r.id = d.idreservation
                 where r.idseance = :seance and r.etat <> 0)
order by numero asc
```
C'est la règle « la réservation d'une séance décrit l'état de ses places ». Une réservation annulée (`etat = 0`) libère ses places.

Elle lit la vue **`PLACE_LIB`** (classe [salle/PlaceLib.java](../../cinema-ejb/src/java/salle/PlaceLib.java)), qui ajoute à chaque place le nom de sa salle, le libellé de son type et son prix. L'écran peut ainsi afficher « F4 — VIP — 25 000 » sans autre requête.

### `calculerMontant(idPlaces, c)`
- La somme des prix des places choisies, lus dans `PLACE_LIB`.
- Une place inconnue → exception « Place introuvable ».
- **Pour l'affichage seulement.** Au moment de réserver, le prix est recalculé côté serveur : on ne fait pas confiance au total envoyé par le navigateur.

### `reserver(idClient, idSeance, idPlaces, u, c)`
1. Refuse une liste de places vide.
2. Construit la `Reservation` (client, séance) et une `ReservationDetail` par place.
3. Les attache avec `setFille(...)`.
4. Appelle `createObject(u, c)`. C'est là que se font **tous les contrôles** (séance pas commencée, places dans la bonne salle, libres, pas en double), le calcul des prix et du total, puis l'`INSERT` de la mère et des lignes (voir [02_classes_apj.md](02_classes_apj.md)).
5. `commit` si la fonction a ouvert la connexion ; `rollback` en cas d'erreur.

Le service ne refait pas les contrôles : ils restent dans la classe métier, pour qu'ils s'appliquent aussi si on enregistre par le moteur APJ (`apresMultiple.jsp`).

## Vérifications faites

- Le service compile avec `apj-core.jar`, en Java 8.
- Les casts `(Client[])`, `(Film[])`… sont sûrs : `CGenUtil.rechercher` crée un tableau du type de l'objet passé (`Array.newInstance`, vu en décompilant `apj-core.jar`).
- **Pas encore testé contre Oracle** : le compte `cinema` est vide, le script [database/01_tables_metier.sql](../../database/01_tables_metier.sql) (tables + vue `PLACE_LIB`) n'a pas encore été exécuté.

## Fichiers ajoutés ou modifiés

| Fichier | Changement |
|---|---|
| [reservation/ReservationService.java](../../cinema-ejb/src/java/reservation/ReservationService.java) | nouveau : les 7 fonctions |
| [salle/PlaceLib.java](../../cinema-ejb/src/java/salle/PlaceLib.java) | nouveau : lecture de la vue `PLACE_LIB` |
| [database/01_tables_metier.sql](../../database/01_tables_metier.sql) | ajout de la vue `PLACE_LIB` |
