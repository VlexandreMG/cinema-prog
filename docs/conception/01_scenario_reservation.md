# Cinéma — Conception : scénario 1, la réservation

## Le scénario

Un client réserve des places pour voir un film.

1. On choisit le **client** dans la liste des clients.
2. On choisit le **film**. La salle s'en déduit : un film passe toujours dans la même salle.
3. On choisit la **séance** du film, c'est-à-dire sa date et son heure de début.
4. On choisit **une ou plusieurs places** parmi les places libres de la salle pour cette séance. Chaque place a un type (par exemple Standard ou VIP), et chaque type a son prix.
5. On vérifie le récapitulatif (client, film, salle, séance, places, prix, total), puis on **paie tout, immédiatement**. La réservation est alors enregistrée.

Choix de simplicité pour commencer : les clients existent déjà dans une liste, et le paiement est immédiat et complet. Les cas plus compliqués (réservation non payée, client créé à la volée…) viendront à la fin.

---

## La base

| Table | Colonnes | Rôle |
|---|---|---|
| **Salle** | id, nom | une salle du cinéma |
| **Film** | id, titre, durée (min), idSalle | un film, et la salle où il passe toujours |
| **Seance** | id, idFilm, dateHeureDebut | une projection du film à une date et une heure données |
| **TypePlace** | id, libellé, prix | une catégorie de place et son prix |
| **Place** | id, idSalle, numéro, idTypePlace | un siège d'une salle, avec son type |
| **Client** | id, nom, contact | une personne qui réserve |
| **Reservation** | id, idClient, idSeance, dateReservation, montantTotal | l'achat d'un client pour une séance |
| **ReservationDetail** | id, idReservation, idPlace, prix | une place de la réservation, avec son prix au moment de l'achat |

### Pourquoi c'est fait comme ça

- **La salle est portée par le film** (`Film.idSalle`), puisqu'un film passe toujours dans la même salle.
- **On ne stocke pas l'heure de fin d'une séance.** On la calcule : `dateHeureDebut + durée du film`.
- **Une place est réservée pour une séance**, pas pour toujours. La place A5 réservée pour la séance de 18h reste libre pour celle de 21h.
- **Le prix est sur le type de place**, pas sur chaque place : toutes les places VIP coûtent le même prix.
- **Le prix est recopié dans `ReservationDetail`.** Si le prix d'un type change plus tard, les anciennes réservations gardent le montant réellement payé. `montantTotal` est la somme des prix de ses lignes.
- **Il n'y a pas de table Paiement.** Comme le paiement est immédiat et complet, une réservation qui existe est une réservation payée.

### Pourquoi une table Séance

Le film dit **quoi** on regarde et **où** (sa salle). La séance dit **quand**. Un même film est projeté plusieurs fois : *Dune 3* le samedi à 18h, le samedi à 21h, le dimanche à 15h…

Sans séance, réserver la place A5 pour *Dune 3* la bloquerait pour toutes les projections du film. La séance permet de dire « A5 est prise **pour la projection de samedi 18h** », c'est-à-dire du début à la fin de ce film-là, ce jour-là.

---

## Les fonctions

| Fonction | Étape | Rôle |
|---|---|---|
| `listerClients()` | 1 | la liste des clients |
| `listerFilms()` | 2 | la liste des films, avec leur salle |
| `listerSeances(idFilm)` | 3 | les séances à venir de ce film |
| `listerPlacesLibres(idSeance)` | 4 | les places de la salle du film, sauf celles déjà réservées pour cette séance |
| `calculerMontant(idPlaces)` | 5 | la somme des prix des types de ces places |
| `reserver(idClient, idSeance, idPlaces)` | 5 | vérifie les règles, puis crée la réservation et ses détails en une seule transaction |

## Les règles

Vérifiées par `reserver` :
- au moins une place est choisie ;
- chaque place appartient à la salle du film de la séance ;
- chaque place est encore libre pour cette séance (si deux réservations arrivent en même temps, une seule passe) ;
- la séance n'est pas déjà passée.

Règle qui en découle pour la création des séances (scénario à venir) :
- deux séances d'une même salle ne doivent pas se chevaucher : une séance doit commencer après la fin de la précédente.

---

Suite : les classes APJ et le script SQL qui implémentent cette base sont décrits dans [02_classes_apj.md](02_classes_apj.md).
