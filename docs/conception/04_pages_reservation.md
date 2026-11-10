# Cinéma — Conception : les pages de réservation et de paiement

Ce document décrit les écrans du [scénario 1](01_scenario_reservation.md). Ils appellent les [fonctions métier](03_fonctions_metier.md), qui s'appuient sur les [classes APJ](02_classes_apj.md).

Pages : [cinema-war/web/pages/reservation/](../../cinema-war/web/pages/reservation/)

## Le parcours

```
 reservation-saisie.jsp          reservation-paiement.jsp             reservation-fiche.jsp
 ┌──────────────────────┐        ┌───────────────────────────┐        ┌──────────────────────┐
 │ Client  Film  Salle  │        │ Récapitulatif             │        │ Réservation RSV0001  │
 │ Séance               │ ─────► │ Places + total            │ ─────► │ Monnaie rendue       │
 │ ☐ places libres      │ GET    │ Montant reçu → monnaie    │ POST   │ Places, prix payés   │
 │ Total     [Continuer]│        │ [Modifier]       [Payer]  │ payer  │ [Nouvelle réserv.]   │
 └──────────────────────┘        └───────────────────────────┘        └──────────────────────┘
        ▲     │ chaque choix                │ Modifier
        └─────┘ recharge la page            └──► retour à la saisie, avec le même choix
```

Les trois étapes du scénario : **choisir** (film, salle, place) → **vérifier** → **payer**.

## Page 1 — `reservation-saisie.jsp` : choisir

URL : `module.jsp?but=reservation/reservation-saisie.jsp`

| Champ | Rempli par | Ce qui se passe quand on le change |
|---|---|---|
| Client (liste) | `listerClients` | rien |
| Film (liste) | `listerFilms` | la séance et les places cochées sont effacées, la page se recharge |
| Salle (lecture seule) | `salleDuFilm(idfilm)` | — |
| Séance (liste) | `listerSeances(idfilm)` | la page se recharge |
| Places libres (cases à cocher) | `listerPlacesLibres(idseance)` | le total se met à jour |
| Total (lecture seule) | JavaScript, avec le prix de chaque case (`data-prix`) | — |

**Comment marchent les listes dépendantes.** Il n'y a pas d'AJAX : le formulaire se renvoie à lui-même en `GET`, avec ce qui est déjà choisi (`idclient`, `idfilm`, `idseance`, `idplace`). La page relit ces paramètres et remplit les listes suivantes. C'est la façon la plus simple, et l'URL garde tout le choix.

Protections :
- si on change de film, une séance d'un autre film est ignorée ;
- seules les séances à venir sont proposées ;
- « Continuer » vérifie en JavaScript qu'un client, une séance et au moins une place sont choisis.

« Continuer vers le paiement » envoie le même formulaire à `reservation-paiement.jsp`.

## Page 2 — `reservation-paiement.jsp` : vérifier et payer

URL : `module.jsp?but=reservation/reservation-paiement.jsp&idclient=…&idseance=…&idplace=…&idplace=…`

**Sans `acte` : le récapitulatif.**
- Client, film, salle et séance.
- Une ligne par place (numéro, type, prix), via `chargerPlaces`.
- Le total, calculé **par le serveur** (`calculerMontant`), jamais repris du navigateur.
- Le formulaire de paiement :
  - le montant à payer ;
  - le montant reçu (par défaut le total exact) ;
  - la monnaie à rendre, calculée en direct.
- « Modifier » revient à la saisie avec le même choix ; « Payer » envoie le formulaire en `POST` avec `acte=payer`.

**Avec `acte=payer` (en `POST` seulement) : le paiement.**
1. Relit le total côté serveur.
2. Refuse si le montant reçu est invalide ou inférieur au total.
3. Appelle `ReservationService.reserver(idclient, idseance, idplaces, u.getUser().getTuppleID(), null)`. Tous les contrôles métier se font là (séance pas commencée, places libres, bonne salle…), dans une seule transaction.
4. Redirige vers la fiche avec `document.location.replace(...)`, comme `apresMultiple.jsp`. `replace` retire la page de paiement de l'historique : le bouton « Retour » ne la renvoie pas.

Protections contre un double paiement :
- le bouton « Payer » est désactivé dès le premier clic ;
- après le paiement, la fiche remplace la page dans l'historique ;
- si la même place est quand même envoyée deux fois, `reserver` la refuse (« déjà réservée pour cette séance »).

**Le montant reçu n'est pas enregistré.** Le paiement est immédiat et complet : la réservation existe seulement si elle est payée. Le montant reçu sert uniquement à calculer la monnaie. Une table Paiement (mode de paiement, paiement en plusieurs fois…) pourra venir plus tard.

## Page 3 — `reservation-fiche.jsp` : la confirmation

URL : `module.jsp?but=reservation/reservation-fiche.jsp&id=RSV000001[&recu=50000]`

- La réservation, lue dans la vue `RESERVATION_LIB` (client, film, salle, séance, date de réservation).
- Ses places, lues dans `RESERVATIONDETAIL_LIB`, avec le **prix payé** (recopié à la réservation), pas le prix actuel du type.
- Le paramètre `recu` n'est présent que juste après le paiement : il affiche « monnaie rendue ».
- Bouton « Nouvelle réservation ».

## Les erreurs

Chaque page est dans un `try … catch`. Une exception, par exemple « La place A5 est déjà réservée pour cette séance », s'affiche en alerte, puis `history.back()` ramène à la page précédente. C'est le même comportement que les pages d'akoho.

Tous les textes venant de la base passent par `CinemaUtil.html(...)` avant d'être écrits dans la page, pour qu'un nom contenant `<` ou `"` ne casse pas l'affichage.

## Pourquoi des pages écrites à la main, et pas `PageInsertMultiple` ?

`PageInsertMultiple` (mère + lignes) génère un tableau de lignes à **saisir**, où l'utilisateur coche chaque ligne à enregistrer, puis poste vers `apresMultiple.jsp`. Notre écran est différent :
- les lignes (places libres) sont **calculées** à partir de la séance, et non saisies ;
- les listes dépendent les unes des autres (film → séance → places) ;
- il y a une étape de vérification et de paiement avant l'enregistrement.

Les pages restent dans le cadre APJ : elles sont incluses par `module.jsp`, utilisent la session (`u`, `lien`) et appellent les classes métier, dont `createObject` fait tous les contrôles.

## Ce qu'il faut pour les voir fonctionner

C'est en place depuis l'étape 1 ([00_vue_ensemble.md](../etape1/00_vue_ensemble.md)) :
1. `module.jsp`, la connexion, `UserEJB`, le `build.xml` et le déploiement ;
2. les scripts [00_socle.sql](../../database/00_socle.sql), [01_tables_metier.sql](../../database/01_tables_metier.sql) et [02_donnees_test.sql](../../database/02_donnees_test.sql) exécutés ;
3. après la connexion avec `cinema` / `cinema`, on arrive directement sur cet écran (`USERHOMEPAGE`) ;
4. l'entrée de menu « Cinéma › Réserver ». Elle est créée par `00_socle.sql`, sur ce modèle :
   ```sql
   INSERT INTO menudynamique (id, libelle, icone, href, rang, niveau, id_pere)
   VALUES ('MENDYNRESA', UNISTR('R\00E9servation'), 'event_seat',
           'module.jsp?but=reservation/reservation-saisie.jsp', 1, 1, NULL);
   COMMIT;
   ```
   À adapter (`niveau`, `id_pere`) à la structure du menu du socle. Ensuite, se déconnecter puis se reconnecter.

## Vérifications faites

- Les classes Java compilent avec `apj-core.jar` en Java 8.
- Le code Java des trois JSP a été extrait et compilé avec les API servlet et JSP de WildFly 10 et la vraie classe `user.UserEJB` d'akoho : aucune erreur.
- **Testées dans WildFly** le 10/11/2026 avec `curl` (connexion, choix, récapitulatif, paiement refusé puis accepté, fiche, double réservation refusée) : voir [l'étape 1](../etape1/00_vue_ensemble.md), sous-étape 7. Pas encore vérifiées visuellement dans un navigateur.

## Fichiers ajoutés ou modifiés

| Fichier | Changement |
|---|---|
| [pages/reservation/reservation-saisie.jsp](../../cinema-war/web/pages/reservation/reservation-saisie.jsp) | nouveau : choisir |
| [pages/reservation/reservation-paiement.jsp](../../cinema-war/web/pages/reservation/reservation-paiement.jsp) | nouveau : vérifier et payer |
| [pages/reservation/reservation-fiche.jsp](../../cinema-war/web/pages/reservation/reservation-fiche.jsp) | nouveau : confirmation |
| [reservation/ReservationLib.java](../../cinema-ejb/src/java/reservation/ReservationLib.java) | nouveau : lit la vue `RESERVATION_LIB` |
| [reservation/ReservationDetailLib.java](../../cinema-ejb/src/java/reservation/ReservationDetailLib.java) | nouveau : lit la vue `RESERVATIONDETAIL_LIB` |
| [reservation/ReservationService.java](../../cinema-ejb/src/java/reservation/ReservationService.java) | ajout de `chargerPlaces`, `chargerReservation`, `listerLignes` |
| [utils/CinemaUtil.java](../../cinema-ejb/src/java/utils/CinemaUtil.java) | ajout de `html`, `montant`, `date` (affichage) |
| [database/01_tables_metier.sql](../../database/01_tables_metier.sql) | ajout des vues `RESERVATION_LIB` et `RESERVATIONDETAIL_LIB` |
