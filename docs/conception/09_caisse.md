# Cinéma — Conception : la caisse

> **Statut (12/11/2026) :** conception validée. **Faits et testés** : les tables (§12) et les classes `Caisse`, `MouvementCaisse`, `CaisseService.solde` (§13).
> **Pas encore fait** : `encaisserFacture` et le reste du service, le branchement dans le paiement, la page.

Troisième fonctionnalité majeure, après la réservation et la facture. Même démarche : fiche de lecture du socle, décisions, puis base, règles, fonctions et écrans.

---

## 1. Fiche de lecture : la caisse dans async standard

| Élément du socle | Ce que c'est |
|---|---|
| **`CAISSE`** (`caisse.Caisse`) | une caisse : nom (`val`), type (espèces, banque…), point de vente, devise |
| **`MOUVEMENTCAISSE`** (`caisse.MvtCaisse`, 1 185 lignes) | **chaque entrée ou sortie d'argent** : date, caisse, `credit` (entrée), `debit` (sortie), `idOrigine` (le document qui l'a causée), mode de paiement, état |
| **`REPORTCAISSE`** (`ReportCaisse`) | l'**arrêté de caisse** : on compte l'argent réel (`montant`) et on le compare au théorique |
| **`OUVERTURECAISSE`** | l'ouverture de la caisse en début de journée |
| **`V_ETATCAISSE`** | une **vue** qui calcule le solde : dernier arrêté + entrées − sorties depuis |
| **`encaissement.Encaissement`** | le pont **facture → caisse** : payer une facture (`Vente.payerObject`) crée un mouvement d'entrée |

**L'idée centrale, qu'on garde : une caisse ne stocke jamais son solde.** On garde la **liste des mouvements**, et le solde se **calcule** (entrées − sorties). Un mouvement n'est jamais modifié ni supprimé : une erreur se corrige par un mouvement inverse.

**Ce qu'on laisse** : types de caisse, devises et taux de change, points de vente, modes de paiement, ouverture, arrêté (pour l'instant), compta.

## 2. Les décisions (12/11/2026)

| Question | Décision |
|---|---|
| Combien de caisses ? | **Une seule** (« Guichet principal »). La table `CAISSE` existe quand même, pour en ajouter plus tard |
| Comment la facture entre-t-elle en caisse ? | **Automatiquement au paiement**, dans la **même transaction** que la réservation et la facture |
| Arrêté de caisse (comptage de fin de journée) ? | **Pas maintenant** |
| Où calculer le solde ? | **En Java** (`CaisseService.solde`) ; la base ne fait que stocker les mouvements |

## 3. Le scénario

**S-C1 — Un paiement fait entrer l'argent en caisse (Guichetier)**
Rakoto Jean paie 30 000 au guichet (il donne 50 000, on lui rend 20 000). En **une seule opération**, le système enregistre :
1. la réservation `RSV…` ;
2. la facture `0003` ;
3. **le mouvement de caisse** : « Facture n° 0003 — Rakoto Jean », **entrée 30 000**, dans « Guichet principal ».

**S-C2 — Consulter la caisse (Gestionnaire)**
Le gestionnaire ouvre la caisse et voit :
- son **solde** actuel, par exemple 90 000 ;
- la **liste de ses mouvements** (date, désignation, entrée, sortie), avec les totaux.

**S-C3 — Une sortie d'argent (fonctionnalité 4, plus tard)**
L'achat d'un film à un distributeur fera **sortir** de l'argent de la caisse, avec un mouvement de **sortie**. La caisse doit déjà savoir faire des sorties, et refuser d'aller sous zéro.

**Ce qui ne doit jamais arriver :**
- une facture payée **sans** son mouvement de caisse, ou l'inverse ;
- une facture encaissée **deux fois** ;
- un mouvement **modifié** ou **supprimé** ;
- une sortie qui rend le solde **négatif**.

## 4. Ce qui entre en caisse : le total de la facture, pas le montant reçu

| | Montant |
|---|---|
| le client donne | 50 000 |
| on lui rend (monnaie) | − 20 000 |
| **reste dans le tiroir** | **30 000** = le total de la facture |

Le mouvement d'entrée vaut donc **le total de la facture**. Le montant reçu et la monnaie se compensent dans le tiroir : il est inutile de les enregistrer (et c'est cohérent avec la réservation, qui ne les enregistre pas non plus).

## 5. La base

| Table | Colonnes | Rôle |
|---|---|---|
| **`CAISSE`** | `id` (CAI…), `nom` | une caisse ; une seule ligne pour l'instant : « Guichet principal » |
| **`MOUVEMENTCAISSE`** | `id` (MVC…), `daty`, `idcaisse`, `designation`, `entree`, `sortie`, `idorigine`, `etat` | **chaque** mouvement d'argent |

Détail de `MOUVEMENTCAISSE` :

| Colonne | Exemple | Pourquoi |
|---|---|---|
| `daty` | 12/11/2026 | la date du mouvement |
| `idcaisse` | CAI000001 | la caisse touchée |
| `designation` | « Facture n° 0003 — Rakoto Jean » | texte **recopié**, comme une facture : le mouvement est figé |
| `entree` / `sortie` | 30 000 / 0 | **l'un des deux** vaut 0. Plus clair que `credit` / `debit` du socle |
| `idorigine` | FAC000007 | le document qui a causé le mouvement (la facture ; plus tard, l'achat). **UNIQUE** : une facture n'est encaissée qu'une fois |
| `etat` | 11 | 11 = validé ; 0 = annulé (plus tard, par un mouvement inverse) |

**Pas de colonne « solde » dans `CAISSE`** : le solde se calcule à partir des mouvements (§7). C'est ce qui garantit qu'il est toujours juste.

**Pas de vue `_LIB`** : comme la facture, le mouvement contient déjà son texte (`designation`). La liste des mouvements lit la table directement.

## 6. Les règles (dans `MouvementCaisse.createObject`)

1. la caisse existe ;
2. **exactement un** des deux montants est positif : `entree > 0` et `sortie = 0`, **ou** l'inverse ;
3. une désignation est obligatoire ;
4. si `idorigine` est rempli : **aucun autre mouvement** avec la même origine (pas de double encaissement ; la base le garantit aussi par la contrainte `UNIQUE`) ;
5. **pour une sortie** : le solde **après** la sortie doit rester ≥ 0. Le solde est calculé dans la transaction, avec la caisse **verrouillée** (`FOR UPDATE`), pour que deux sorties simultanées ne puissent pas passer toutes les deux ;
6. compléter : `daty` = aujourd'hui, `etat` = 11 (**fixé explicitement**) ;
7. `super.createObject` → INSERT.

## 7. Les fonctions (`CaisseService`)

| Fonction | Rôle |
|---|---|
| `encaisserFacture(idFacture, u, c)` | crée le mouvement d'**entrée** d'une facture : montant = total de la facture, désignation « Facture n° … — client », origine = la facture, caisse = la caisse principale. Appelée **pendant le paiement**, avec la connexion `c` |
| `caissePrincipale(c)` | la caisse unique (« Guichet principal ») |
| `solde(idCaisse, c)` | **le calcul en Java** : lit les mouvements validés de la caisse et fait Σ entrées − Σ sorties |
| `listerMouvements(idCaisse, c)` | les mouvements d'une caisse, du plus récent au plus ancien |
| `decaisser(idCaisse, montant, designation, idOrigine, u, c)` | une **sortie** (préparée pour l'achat de films, fonctionnalité 4) |

**Le solde en Java, concrètement :**
```
mouvements = rechercher(MOUVEMENTCAISSE where idcaisse = … and etat = 11)
solde = 0
pour chaque mouvement : solde = solde + entree − sortie
```
La base ne fait que **stocker** les mouvements ; le **calcul** est dans le métier, comme le compteur de facture.

## 8. Le paiement, maintenant

```
reservation-paiement.jsp  « Payer »
  └─ ReservationService.reserver(...)                      UNE transaction
        ├─ Reservation.createObject           → INSERT RESERVATION + lignes
        ├─ FactureService.genererFacture      → INSERT FACTURE + lignes (numéro 0003)
        ├─ CaisseService.encaisserFacture     → INSERT MOUVEMENTCAISSE (+ 30 000)    ← NOUVEAU
        └─ commit                             → les trois, ou rien
```

Faut-il l'appeler dans `reserver`, ou dans `genererFacture` ? **Dans `reserver`**, juste après la facture. `genererFacture` doit rester capable de facturer **sans encaisser**, par exemple pour rattraper une vieille réservation déjà payée et déjà en caisse.

## 9. Les écrans

| Page | Contenu | Technique |
|---|---|---|
| `caisse/caisse-etat.jsp` | la caisse, son **solde**, et la liste de ses mouvements avec les totaux entrées et sorties | page écrite à la main (le solde vient de `CaisseService.solde`) ; ou `PageRecherche` APJ sur `MOUVEMENTCAISSE` avec `colSomme = {entree, sortie}` pour la liste |
| entrée de menu « Caisse » | | `MENUDYNAMIQUE` + `USERMENU` |

Aucun écran de saisie : les entrées viennent du paiement. Les sorties viendront de l'achat de films.

## 10. Hors périmètre (pour plus tard)

- l'**arrêté de caisse** (comptage, écart, report) ;
- plusieurs caisses, ou une caisse par guichet ;
- l'annulation d'un mouvement (par un mouvement inverse) ;
- les modes de paiement (espèces, mobile money…) ;
- l'encaissement du **popcorn** (la vente de jouets n'a pas de facture).

## 11. Questions encore ouvertes

1. **Les factures déjà émises** (`0001`, `0002`) n'ont pas de mouvement de caisse. On les encaisse après coup, ou on part de zéro ?
2. **Le nom de la caisse** : « Guichet principal », ou un autre ?
3. **Le popcorn** : il ne passe pas par la caisse pour l'instant (pas de facture). On le laisse hors caisse, ou on prévoit de l'y faire entrer plus tard ?

---

## 12. Implémentation — la base (12/11/2026)

Ajoutée à la fin de [01_tables_metier.sql](../../database/01_tables_metier.sql) et exécutée dans `cinema` :

| Objet | Détail |
|---|---|
| `CAISSE` | `id`, `nom` ; une ligne : **« Guichet principal », id `CAI000002`** (la séquence a sauté un numéro : trou normal). Le code ne doit donc **jamais** écrire l'id en dur : il cherche la caisse par son nom |
| `MOUVEMENTCAISSE` | `id`, `daty`, `idcaisse` (→ `CAISSE`), `designation`, `entree`, `sortie`, `idorigine` (**UNIQUE**), `etat` |
| contrainte `CK_MVT_UN_SENS` | `(entree > 0 AND sortie = 0) OR (entree = 0 AND sortie > 0)` : exactement un sens |
| `CHECK (entree >= 0)`, `CHECK (sortie >= 0)` | pas de montant négatif |
| `SEQ_CAISSE` / `GETSEQCAISSE` (`CAI`), `SEQ_MOUVEMENTCAISSE` / `GETSEQMOUVEMENTCAISSE` (`MVC`) | les ids |

**Tests SQL directs** (session annulée) : entrée 30 000 et sortie 5 000 acceptées ; deux montants à 0, deux montants remplis et montant négatif refusés (`CK_MVT_UN_SENS`) ; caisse inexistante refusée (clé étrangère) ; même `idorigine` deux fois refusé (`ORA-00001`).

La règle « pas de solde négatif » n'est **pas** en base : elle demande le solde, calculé en Java (§13).

## 13. Implémentation — les classes (12/11/2026)

| Fichier | Rôle |
|---|---|
| [caisse/Caisse.java](../../cinema-ejb/src/java/caisse/Caisse.java) | `ClassMAPTable` ; contrôle : nom obligatoire |
| [caisse/MouvementCaisse.java](../../cinema-ejb/src/java/caisse/MouvementCaisse.java) | `ClassMAPTable` (pas une mère : un mouvement n'a pas de lignes) ; `createObject` = les règles du §6 |
| [caisse/CaisseService.java](../../cinema-ejb/src/java/caisse/CaisseService.java) | pour l'instant **seulement `solde`** (nécessaire à la règle ⑤) |

### `MouvementCaisse.createObject`, dans l'ordre
| # | Règle | Message si refus |
|---|---|---|
| ① | la caisse existe | « Caisse introuvable : … » |
| ② | exactement un montant positif | « Un mouvement de caisse est soit une entrée, soit une sortie, d'un montant positif. » |
| ③ | une désignation | « Un mouvement de caisse doit avoir une désignation. » |
| ④ | `idorigine` pas déjà utilisé | « Le document … a déjà un mouvement de caisse. » |
| ⑤ | **sortie** : verrou sur la caisse (`select … for update`), puis `solde − sortie ≥ 0` | « Solde insuffisant : la caisse contient … Ar, impossible de sortir … Ar. » |
| ⑥ | `daty` = aujourd'hui, `etat` = 11 (fixé explicitement) | |
| ⑦ | `super.createObject` → INSERT + historique | |

### `CaisseService.solde(idCaisse, c)` : le calcul en Java
```java
Object[] res = CGenUtil.rechercher(new MouvementCaisse(), null, null, c,
        " and idcaisse = '…' and etat >= 11");          // la base : seulement LIRE les mouvements
double solde = 0;
for (Object o : res) solde = solde + m.getEntree() - m.getSortie();   // Java : le CALCUL
```
Avec la connexion `c` d'une transaction, le solde **inclut les mouvements de cette transaction** pas encore « commités » : c'est ce qui permet à la règle ⑤ de voir une entrée faite juste avant.

### Les tests (harnais Java, transaction annulée)
```
caisse CAI000002 solde de depart = 0.0
OK    entree 30 000 (facture FACTEST1) -> MVC000001 etat=11 daty=2026-11-12 | solde=30000.0
OK    sortie 5 000 -> MVC000002 etat=11 daty=2026-11-12 | solde=25000.0
REFUS sortie 50 000 > solde : Solde insuffisant : la caisse contient 25 000 Ar, impossible de sortir 50 000 Ar.
REFUS meme facture encaissee 2 fois : Le document FACTEST1 a déjà un mouvement de caisse.
REFUS entree et sortie a 0 : Un mouvement de caisse est soit une entrée, soit une sortie, d'un montant positif.
REFUS entree ET sortie : Un mouvement de caisse est soit une entrée, soit une sortie, d'un montant positif.
REFUS sans designation : Un mouvement de caisse doit avoir une désignation.
REFUS caisse inexistante : Caisse introuvable : CAI999999
apres rollback : mouvements=0 solde=0.0
```

### Prochaine étape
`CaisseService` : `caissePrincipale` (par le nom, pas par l'id), `encaisserFacture`, `listerMouvements`, `decaisser` ; puis l'appel de `encaisserFacture` dans `ReservationService.reserver`, après `genererFacture` (§8).
