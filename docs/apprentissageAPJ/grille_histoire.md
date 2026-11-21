# La grille pour raconter son projet (et réussir un aléa)

## La fondation (pour CONCEVOIR, avant le code) — valable pour tout projet

> **« Mais Dis, Comment Il Tiendra Vraiment ? »**

| Lettre | Couche | La seule question à retenir |
|---|---|---|
| **M** | Métier | Qui fait quoi ? (acteurs, verbes, règles en phrases) |
| **D** | Données | Avec quelles choses, reliées comment ? (stocké ou calculé ? référence ou document figé ?) |
| **C** | Cycle | Par quels états ça passe ? (dessiner les flèches) |
| **I** | Invariants | Qu'est-ce qui ne doit **jamais** arriver ? (et qui le protège : écran, serveur, base) |
| **T** | Temps | Et la fois suivante, en même temps, plus tard ? |
| **V** | Vérité | Qui je crois ? (une seule source ; jamais le navigateur) |

**Pour chaque flèche du cycle : A-A-R**

| | Question |
|---|---|
| **A**vant | qu'est-ce qui doit être vrai pour avoir le droit de faire l'action ? |
| **A**près | qu'est-ce qui a changé (états, lignes écrites) ? |
| **R**até | si ça échoue au milieu, que reste-t-il ? (tout ou rien) |

Exemple, l'aléa « annuler une réservation » :
```
          réserver            viser
(rien) ──────────► CRÉÉE ──────────► PAYÉE
                     └── annuler ──► ANNULÉE      ← et depuis PAYÉE ? à décider AVANT de coder
```
Avant : elle existe et est CRÉÉE. Après : état 0, ses places redeviennent libres. Raté : rien ne change.

La fondation sert à **concevoir** (de haut en bas). La grille ci-dessous sert à **lire** une étape (pendant l'histoire).

---

Raconter le projet comme une **histoire** (« le guichetier fait X, que se passe-t-il ? ») sans s'attacher à la syntaxe, et se poser **5 questions à chaque étape**. Ces 5 questions viennent des erreurs réellement faites (aléa de la remise, récit de l'histoire « réserver »).

---

## La grille

| | Question à chaque étape | L'erreur qui l'a fait naître |
|---|---|---|
| 💾 | **Mémoire ou base ?** Cette étape écrit-elle en base, ou prépare-t-elle seulement un objet Java ? | « il crée d'abord la réservation » : en fait rien n'est écrit avant la fin |
| 💥 | **Si ça casse ici, que reste-t-il ?** | « je ne sais pas » à « la place n°3 est prise, que reste-t-il en base ? » (réponse : rien) |
| 🖥️ / ⚙️ | **Aide ou décision ?** L'écran filtre (confort), le serveur vérifie (vérité). | — |
| 🔁 | **Une ligne ou l'ensemble ?** Faut-il compter sur toute la réservation AVANT de décider ? | la remise testée DANS la boucle des places, avec le nombre TOTAL de places |
| 🔗 | **Quel chemin entre les données ? Et la fois suivante ?** | la remise cherchée avec l'id de la PLACE ; le prix baissé dans TYPEPLACE qui se cumulait |

---

## 1. 💾 Mémoire ou base ?

Dans le projet, presque tout se **prépare en mémoire**, et l'écriture arrive **à la fin, en une fois**.

```
createObject (TON code)      = vérifier + calculer, sur l'objet Java       → rien en base
super.createObject (APJ)     = id (séquence) + INSERT mère + INSERT lignes → en base (pas encore validé)
commit                       = tout devient définitif
```
À repérer : une étape qui écrit **pendant** la préparation (ex. `updateToTableWithHisto`). Elle est en base, mais **dans la transaction** : un rollback l'annule.

## 2. 💥 Si ça casse ici, que reste-t-il ?

Imaginer l'arrêt brutal **à cet endroit précis**. Il faut savoir où la transaction commence et finit :
```
ouverture : dans l'APJ  (createObjectMultiple pour créer, validerObject pour viser)
   ... tout ce qui se passe ici est « tout ou rien » ...
fermeture : commit (tout est gardé)  ou  rollback (RIEN n'est gardé)
```
Conséquence pour un aléa : dans `createObject` ou `validerObject`, on peut refuser (`throw new Exception(...)`) **n'importe où**, sans rien avoir à « nettoyer ».

## 3. 🖥️ / ⚙️ Aide ou décision ?

| Côté écran (navigateur) | Côté serveur (`createObject`, `validerObject`) |
|---|---|
| **propose** : listes filtrées, champs cachés, bouton affiché selon l'état | **décide** : contrôles, prix, état, écritures |
| peut être contourné ou périmé (un autre guichet a vendu la place entre-temps) | voit l'état **réel** au moment d'enregistrer |
| une règle oubliée ici = gênant | une règle oubliée ici = **bug** |

Une règle d'aléa (« on ne peut pas… », « le prix est… ») va **toujours** côté serveur. Côté écran, c'est un bonus.

## 4. 🔁 Une ligne ou l'ensemble ?

**La question d'algorithme.**

| La règle porte sur… | Mots-clés | Où décider |
|---|---|---|
| **une ligne** | « cette place », « chaque place » | **dans** la boucle des lignes |
| **l'ensemble** | « nombre de », « au moins », « exactement », « total », « plus de » | **compter d'abord** dans une boucle AVANT, **puis** décider |

Schéma type d'une règle « ensemble » :
```
1. COMPTER    : parcourir toutes les lignes, remplir un compteur (ou une table type → nombre)
2. DÉCIDER    : comparer le compteur à la règle
3. APPLIQUER  : dans la boucle des lignes, utiliser la décision
```

## 5. 🔗 Quel chemin ? Et la fois suivante ?

**Le chemin** : pour aller d'une donnée à une autre, dire les étapes **à voix haute** avant de coder.
```
place       → son type (PLACE.idtypeplace)   → la remise (REMISE.catres)
séance      → son film (SEANCE.idfilm)       → sa salle (FILM.idsalle)
réservation → sa facture (FACTURE.idreservation)
```
Si on ne peut pas dire le chemin, on cherchera avec le mauvais id.

**La fois suivante** : si l'étape **modifie** quelque chose qui reste (un prix de référence, un compteur, un état), se demander :
- que voit **la réservation suivante** ? (cumul ?)
- que se passe-t-il si **deux guichets** le font **en même temps** ? (verrou `for update` ?)

Modifier une table de **référence** (TYPEPLACE, REMISE…) touche **tous** les clients futurs.

---

## Avant d'écrire une seule ligne d'aléa

1. **La règle en une phrase**, avec des mots précis.
2. **Un exemple chiffré à la main** : 2 ou 3 cas, avec le résultat attendu.
3. **La grille** sur l'endroit où la règle s'insère : 💾 💥 🖥️/⚙️ 🔁 🔗.
4. **L'algorithme en français** (compter / décider / appliquer).
5. **Seulement alors**, le code, puis un test qui compare au résultat de l'étape 2.
