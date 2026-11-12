# Cinéma — Conception : l'achat de films

> **Statut (12/11/2026) :** **terminée.** Base et classes (§11), fonctions métier (§12), page et menu (§13) faits et testés dans WildFly.

Quatrième et dernière fonctionnalité majeure. Même démarche : fiche de lecture du socle, décisions, puis base, règles, fonctions et écrans.

---

## 1. Fiche de lecture : l'achat dans async standard

Le socle suit une **chaîne complète** d'achat (`faturefournisseur/`, 43 classes) :

```
Demande d'achat → Bon de commande → Bon de livraison → Facture fournisseur → Paiement (sortie de caisse)
   DmdAchat        As_BonDeCommande   As_BonDeLivraison   FactureFournisseur     MvtCaisse
```

| Élément | Ce que c'est |
|---|---|
| **`FOURNISSEUR`** (`Fournisseur`) | à qui on achète : nom, contact, devise, banque, taxe… |
| **`As_BonDeCommande`** + lignes | la commande passée au fournisseur (mère + filles) |
| **`FactureFournisseur`** + `FactureFournisseurDetails` | la facture **reçue** du fournisseur ; hérite de la même mère que la facture client (`FactureCF`) ; lignes qté / PU / TVA |
| **le paiement** | une **sortie** de caisse |

**C'est le miroir de la vente** : la vente fait **entrer** l'argent (facture client → entrée de caisse), l'achat le fait **sortir** (achat → sortie de caisse).

**Ce qu'on garde** : le fournisseur (→ `DISTRIBUTEUR`), l'achat, la sortie de caisse.
**Ce qu'on laisse** : demande d'achat, bon de commande, livraison, facture fournisseur, TVA, devises, échéances.

## 2. Les décisions (12/11/2026)

| Question | Décision |
|---|---|
| Combien de films par achat ? | **Un seul** : un achat = un distributeur, un film, un montant. Pas de lignes |
| D'où vient le film ? | **L'achat crée le film** : acheter un film l'ajoute au catalogue, dans la même transaction |
| Comment l'achat est-il payé ? | **Immédiatement** : l'achat et la **sortie de caisse** dans la même transaction ; refusé si la caisse n'a pas assez |
| Les distributeurs ? | **Une table** `DISTRIBUTEUR` (Netflix, Disney…), choisie dans une liste |

## 3. Le scénario

**S-A1 — Acheter un film (Gestionnaire)**
Le cinéma veut passer *Interstellar*. Le gestionnaire saisit :
- le **film** : titre « Interstellar », durée 169 min, salle « Salle 2 » ;
- le **distributeur** : Netflix ;
- le **montant** : 40 000 Ar.

Au clic sur « Acheter », **en une seule opération**, le système :
1. **crée le film** *Interstellar* dans le catalogue ;
2. **enregistre l'achat** `ACH000001` (Netflix, Interstellar, 40 000) ;
3. **fait sortir l'argent** de la caisse : « Achat des droits — Interstellar — Netflix », **sortie 40 000**.

Le solde de la caisse passe de 60 000 à 20 000. *Interstellar* peut maintenant recevoir des séances.

**S-A2 — Pas assez d'argent**
Le gestionnaire veut acheter un autre film à 100 000 Ar, mais la caisse n'a plus que 20 000 Ar. Le système refuse : « Solde insuffisant : la caisse contient 20 000 Ar, impossible de sortir 100 000 Ar. » **Rien n'est enregistré** : ni le film, ni l'achat.

**Ce qui ne doit jamais arriver :**
- un achat **sans** sa sortie de caisse, ou une sortie **sans** son achat ;
- un film **créé** alors que son achat a échoué ;
- une caisse **négative** ;
- le **même film** acheté deux fois.

## 4. C'est ici que tout se rejoint

Cette fonctionnalité **n'a presque rien de neuf à inventer** côté argent : elle réutilise ce qui existe déjà.

| Déjà fait | Réutilisé par l'achat |
|---|---|
| `Film.createObject` (titre, durée > 0, salle existe) | créer le film acheté |
| `CaisseService.caissePrincipale` | la caisse d'où sort l'argent |
| `CaisseService.decaisser` | la sortie de caisse |
| `MouvementCaisse.createObject`, règle ⑤ : verrou + « pas de solde négatif » | **refuser** un achat trop cher |
| `idorigine` UNIQUE dans `MOUVEMENTCAISSE` | un achat n'est décaissé qu'une fois |

## 5. La base

| Table | Colonnes | Rôle |
|---|---|---|
| **`DISTRIBUTEUR`** | `id` (DIS…), `nom`, `contact` | à qui on achète (le `FOURNISSEUR` du socle) |
| **`ACHAT`** | `id` (ACH…), `daty`, `iddistributeur`, `idfilm` (**UNIQUE**), `montant`, `etat` | l'achat des droits d'un film |

- **`idfilm` UNIQUE** : un film n'est acheté qu'une fois (la base le garantit).
- **`montant`** > 0 (`CHECK`).
- **`etat`** : 11 = payé (immédiatement) ; 0 = annulé (plus tard).
- **Pas de lignes** : un film par achat, donc `ACHAT` est une table simple (`ClassMAPTable`), comme `MOUVEMENTCAISSE`.
- **Pas de vue `_LIB` pour l'instant** : une liste des achats pourra en avoir une (nom du distributeur, titre du film), car ces noms sont **vivants** ; l'achat lui-même n'est pas un document officiel figé comme la facture.

Données de départ : quelques distributeurs (Netflix, Disney, Warner).

## 6. Les règles (dans `Achat.createObject`)

1. le distributeur existe ;
2. le film existe (créé juste avant, dans la même transaction) ;
3. le film n'a **pas déjà** été acheté ;
4. `montant` > 0 ;
5. compléter : `daty` = aujourd'hui, `etat` = 11 (**fixé explicitement**) ;
6. `super.createObject` → INSERT.

La règle « assez d'argent en caisse » **n'est pas ici** : elle est déjà dans `MouvementCaisse.createObject` (règle ⑤), appelée par `decaisser`. Pas besoin de l'écrire deux fois.

## 7. Les fonctions (`AchatService`)

| Fonction | Rôle |
|---|---|
| `acheterFilm(titre, duree, idsalle, iddistributeur, montant, u, c)` | **l'opération complète** : crée le film, enregistre l'achat, fait la sortie de caisse ; une seule transaction |
| `listerDistributeurs(c)` | pour la liste déroulante de l'écran |
| `listerAchats(c)` | (plus tard) pour une liste des achats |

### Le déroulement de `acheterFilm`
```
acheterFilm(...)                                            autoCommit = false
  ├─ 1. Film f = new Film(titre, duree, idsalle) ; f.createObject(u, c)       → INSERT FILM
  ├─ 2. Achat a = new Achat(iddistributeur, f.getId(), montant) ; a.createObject(u, c)  → INSERT ACHAT
  ├─ 3. CaisseService.decaisser(caissePrincipale, montant,
  │        "Achat des droits — " + titre + " — " + distributeur, a.getId(), u, c)
  │        └─ MouvementCaisse.createObject : verrou caisse + solde ≥ montant ?   → INSERT MOUVEMENTCAISSE
  └─ commit                                                  le film, l'achat et la sortie, ou RIEN
```
- **L'ordre compte** : le film d'abord (l'achat a besoin de son id), puis l'achat (la sortie a besoin de son id comme origine), puis la sortie.
- **Si la caisse n'a pas assez** : `decaisser` lance « Solde insuffisant », `acheterFilm` fait `rollback` → le film et l'achat, déjà insérés dans la transaction, **disparaissent** aussi. C'est le scénario S-A2.

## 8. Les écrans

| Page | Contenu |
|---|---|
| `achat/achat-saisie.jsp` | formulaire : titre, durée, salle (liste), distributeur (liste), montant ; **le solde de la caisse affiché** (lecture seule), pour savoir ce qu'on peut dépenser ; bouton « Acheter » (POST) |
| après l'achat | redirection vers la page « État de la caisse », qui montre la nouvelle sortie |
| entrée de menu « Acheter un film » | `MENUDYNAMIQUE` + `USERMENU` ([menu_dynamique.md](../apprentissageAPJ/menu_dynamique.md)) |

## 9. Hors périmètre (pour plus tard)

- plusieurs films par achat (mère + lignes) ;
- facture fournisseur, TVA, paiement différé ;
- annuler un achat (sortie inverse, film retiré) ;
- empêcher de programmer une séance pour un film **non acheté** (aujourd'hui, les séances sont créées en SQL).

## 10. Questions encore ouvertes

1. **Les films déjà au catalogue** (*Dune 3*, *Coco*, *Tsara ny fiainana*) n'ont jamais été « achetés ». On les laisse comme ça (films d'avant le module), ou on leur crée un achat sans sortie de caisse ?
2. **Les montants** : la caisse contient **60 000 Ar** aujourd'hui. Avec des prix réalistes de droits de film (plusieurs millions), **tout achat serait refusé**. Pour les tests, on prend de petits montants (ex. 40 000), ou on prévoit un moyen d'alimenter la caisse (un apport en entrée) ?
3. **Les distributeurs de départ** : Netflix, Disney, Warner — d'accord, ou d'autres noms ?

---

## 11. Implémentation — la base et les classes (12/11/2026)

### 11.1 La base
Ajoutée à la fin de [01_tables_metier.sql](../../database/01_tables_metier.sql) et exécutée dans `cinema` :

| Objet | Détail |
|---|---|
| `DISTRIBUTEUR` | `id`, `nom`, `contact` |
| `ACHAT` | `id`, `daty`, `iddistributeur` (→ `DISTRIBUTEUR`), `idfilm` (→ `FILM`, **UNIQUE**), `montant` (`CHECK > 0`), `etat` |
| séquences + fonctions | `GETSEQDISTRIBUTEUR` (`DIS`), `GETSEQACHAT` (`ACH`) |
| données de départ | Netflix (`DIS000002`), Disney (`DIS000003`), Warner (`DIS000004`) |

Les ids des distributeurs commencent à `DIS000002`, comme la caisse à `CAI000002` : un numéro de séquence a été consommé sans être utilisé. C'est un trou normal ([creer_une_sequence.md](../apprentissageAPJ/creer_une_sequence.md) §7) : le code ne doit jamais écrire ces ids en dur.

### 11.2 Les classes (package `achat`)

| Fichier | Rôle |
|---|---|
| [achat/Distributeur.java](../../cinema-ejb/src/java/achat/Distributeur.java) | `ClassMAPTable` ; contrôle : nom obligatoire |
| [achat/Achat.java](../../cinema-ejb/src/java/achat/Achat.java) | `ClassMAPTable` (pas de lignes : un film par achat) ; `createObject` = les règles du §6 |

`Achat.createObject`, dans l'ordre :
| # | Règle | Message si refus |
|---|---|---|
| ① | le distributeur existe | « Distributeur introuvable : … » |
| ② | le film existe (créé juste avant, même transaction) | « Film introuvable : … » |
| ③ | le film n'est pas déjà acheté | « Le film … a déjà été acheté. » |
| ④ | montant > 0 | « Le montant de l'achat doit être supérieur à 0. » |
| ⑤ | `daty` = aujourd'hui, `etat` = 11 (fixé explicitement) | |
| ⑥ | `super.createObject` → INSERT + historique | |

La règle « assez d'argent en caisse » n'y est pas : elle sera appliquée par `decaisser` → `MouvementCaisse.createObject` (règle ⑤), dans `acheterFilm`.

### 11.3 Les tests (harnais Java, transaction annulée)
Le film est créé avec `Film.createObject` (déjà existant), puis acheté :
```
film cree FLM000004 Interstellar (169 min, SAL000002)
OK    achat ACH000001 | DIS000002 | FLM000004 | montant=40000.0 | etat=11 | daty=2026-11-12
REFUS meme film achete 2 fois : Le film FLM000004 a déjà été acheté.
REFUS distributeur inexistant : Distributeur introuvable : DIS999999
REFUS film inexistant : Film introuvable : FLM999999
REFUS montant 0 : Le montant de l'achat doit être supérieur à 0.
apres rollback : achats=0 films Interstellar=0
```

### 11.4 Prochaine étape
`AchatService` : `acheterFilm` (film → achat → `CaisseService.decaisser`, une transaction) et `listerDistributeurs` ; puis la page `achat/achat-saisie.jsp` et l'entrée de menu.

---

## 12. Implémentation — les fonctions métier (12/11/2026)

### 12.1 `AchatService` ([achat/AchatService.java](../../cinema-ejb/src/java/achat/AchatService.java))

| Fonction | Rôle |
|---|---|
| `listerDistributeurs(c)` | les distributeurs par nom, pour la liste déroulante |
| `listerSalles(c)` | les salles par nom, pour choisir la salle du film acheté (**ajoutée** : aucune fonction ne listait les salles) |
| `acheterFilm(titre, duree, idSalle, idDistributeur, montant, u, c)` | l'opération complète, en **une** transaction |

### 12.2 `acheterFilm`, pas à pas
```java
Film film = new Film();  film.setTitre(titre);  film.setDuree(duree);  film.setIdsalle(idSalle);
film.createObject(u, c);                                   // 1. INSERT FILM        (titre, durée > 0, salle existe)

Achat achat = new Achat();  achat.setIddistributeur(idDistributeur);
achat.setIdfilm(film.getId());  achat.setMontant(montant);
achat.createObject(u, c);                                  // 2. INSERT ACHAT       (distributeur, pas déjà acheté, montant > 0)

String designation = "Achat des droits — " + titre + " — " + distributeur.getNom();   // texte recopié
CaisseService.decaisser(CaisseService.caissePrincipale(c).getId(), montant, designation,
        achat.getId(), u, c);                              // 3. INSERT MOUVEMENTCAISSE (verrou + solde suffisant ?)
```
- **Aucune règle nouvelle** : chaque étape réutilise un `createObject` déjà écrit (`Film`, `Achat`, `MouvementCaisse`).
- **L'ordre compte** : l'achat a besoin de l'id du film ; la sortie a besoin de l'id de l'achat (`idorigine`).
- **Tout ou rien** : avec `c == null`, `acheterFilm` ouvre sa transaction ; si la caisse refuse à l'étape 3, le `rollback` annule aussi le film (1) et l'achat (2).
- ⚠ **Avec `c` fourni**, `acheterFilm` ne fait **pas** de `rollback` : c'est l'appelant qui doit le faire. Depuis une page, on passe donc `null`.

### 12.3 Les tests (harnais Java)
```
listerDistributeurs : Disney Netflix Warner | listerSalles : Salle 1 Salle 2

== A. achat qui passe (transaction annulee a la fin)
solde avant = 60000.0
achat ACH000002 | film FLM000006 | montant 40000.0
mouvement MVC000008 | Achat des droits — Interstellar — Netflix | sortie=40000.0 | origine=ACH000002
solde apres = 20000.0

== B. achat trop cher, transaction geree par acheterFilm (c = null)
REFUS : Solde insuffisant : la caisse contient 60 000 Ar, impossible de sortir 10 000 000 Ar.
en base : film 'Film trop cher'=0 achats=0 sorties=0 | solde=60000.0
```
- **A** : le film, l'achat et la sortie sont créés ; le solde baisse exactement du montant.
- **B** : le film « Film trop cher » **avait été inséré** à l'étape 1, mais le refus de l'étape 3 l'a fait disparaître avec le reste. C'est le scénario S-A2 (§3), vérifié.

Rien n'est resté en base après ces tests (A annulé, B refusé).

### 12.4 Prochaine étape
La page `achat/achat-saisie.jsp` (titre, durée, salle, distributeur, montant, avec le solde de la caisse affiché), puis l'entrée de menu « Acheter un film ».

---

## 13. Implémentation — la page et le menu (12/11/2026)

### 13.1 La page [achat/achat-saisie.jsp](../../cinema-war/web/pages/achat/achat-saisie.jsp)

URL : `module.jsp?but=achat/achat-saisie.jsp` (menu « Cinéma › Acheter un film »).

Une seule page, deux comportements (le modèle de `reservation-paiement.jsp`) :

| Cas | Ce qui se passe |
|---|---|
| **sans `acte`** | le formulaire : solde de la caisse (lecture seule), titre, durée, salle, distributeur, montant |
| **`acte=acheter`** (POST) | `AchatService.acheterFilm(…, u.getUser().getTuppleID(), null)`, puis `document.location.replace` vers `caisse/caisse-etat.jsp` |

```
Acheter un film
Solde de la caisse (Ar)  [ 60 000 ]   (lecture seule : ce qu'on peut dépenser)
Le film      Titre [          ]   Durée (minutes) [   ]   Salle [ ▼ ]
L'achat      Distributeur [ ▼ ]   Montant (Ar) [      ]
                                                          [Acheter]
```

- **Les fonctions appelées** : `AchatService.listerSalles`, `AchatService.listerDistributeurs`, `CaisseService.caissePrincipale` + `CaisseService.solde` (affichage) ; `AchatService.acheterFilm` (au clic).
- **Pas de JavaScript** (hors la redirection) : `required` et `min` font vérifier les champs par le navigateur ; le serveur revérifie tout (`Film`, `Achat`, `MouvementCaisse`).
- **`c = null`** : `acheterFilm` gère sa transaction (commit, ou rollback de tout en cas de refus).
- **Après l'achat**, on arrive sur l'état de la caisse, qui montre le solde diminué.

### 13.2 L'entrée de menu : [database/03_menu.sql](../../database/03_menu.sql)

Un nouveau script pour les entrées de menu des fonctionnalités :
```sql
INSERT INTO MENUDYNAMIQUE (id, libelle, icone, href, rang, niveau, id_pere)
VALUES ('MENCINEMAACHAT', 'Acheter un film', 'shopping_cart',
        'module.jsp?but=achat/achat-saisie.jsp', 4, 2, 'MENCINEMA');
INSERT INTO USERMENU (id, refuser, idmenu, idrole, codeservice, codedir, interdit)
VALUES ('USMCINEMAACHAT', '*', 'MENCINEMAACHAT', NULL, NULL, NULL, 0);
```
- rang **4** : les rangs 2 et 3 sont gardés pour « Vendre du popcorn » et « État de la caisse » (pas encore au menu) ;
- exécuté, puis **redéployé** et **reconnecté** ([menu_dynamique.md](../apprentissageAPJ/menu_dynamique.md) §6).

Le menu reçu après reconnexion (JSON produit par APJ) :
```
"libelle":"Cinéma",          "href":"#?currentMenu=MENCINEMA"
"libelle":"Réserver",        "href":"module.jsp?but=reservation/reservation-saisie.jsp&currentMenu=MENCINEMARESA"
"libelle":"Acheter un film", "href":"module.jsp?but=achat/achat-saisie.jsp&currentMenu=MENCINEMAACHAT"
```

### 13.3 Les tests dans WildFly (`curl`)
| Test | Résultat |
|---|---|
| menu | « Acheter un film » présent, icône `shopping_cart` |
| page | solde 60 000 ; 2 salles ; distributeurs Disney, Netflix, Warner |
| achat à 10 000 000 | « Solde insuffisant : la caisse contient 60 000 Ar, impossible de sortir 10 000 000 Ar. » ; aucun « Film trop cher » en base |
| achat d'*Interstellar* (169 min, Salle 2, Netflix, 5 000) | redirection vers l'état de la caisse ; solde **55 000** |

Les `INSERT` du vrai achat, relevés dans `server.log`, dans l'ordre :
```
INSERT INTO FILM ( id , titre , duree , idsalle ) …
INSERT INTO ACHAT ( id , daty , iddistributeur , idfilm , montant , etat ) …
INSERT INTO MOUVEMENTCAISSE ( id , daty , idcaisse , designation , entree , sortie , idorigine , etat ) …
```
En base :
```
ACHAT            ACH000005 | Netflix | Interstellar (FLM000009) | 5000 | etat 11
MOUVEMENTCAISSE  MVC000009 | sortie = 5000 | origine ACH000005
```
⚠ Cet achat est **resté en base** (donnée de démonstration) : *Interstellar* est au catalogue, et la caisse est passée de 60 000 à 55 000.
