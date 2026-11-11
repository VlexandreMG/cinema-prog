# Aide-mémoire — Les conventions APJ du projet

Toutes les règles de nommage et d'organisation au même endroit. **APJ relie les choses par leur nom** : une table à une classe, une colonne à un attribut, un attribut à un getter, un getter à un champ d'écran. Un nom qui ne correspond pas ne provoque pas toujours une erreur claire : la valeur reste simplement vide.

Les erreurs relevées dans le challenge popcorn sont signalées par 🍿.

---

## 1. La chaîne des noms

```
Table Oracle      JOUET          colonne   idpopcorn
     │                                │
Classe Java       jouet.Jouet    attribut  private String idpopcorn;
     │                                │
Getter / setter                  getIdpopcorn() / setIdpopcorn(String)
     │                                │
Écran (input)                    <input name="idpopcorn">  (APJ)  ·  request.getParameter("idpopcorn")
```

**Le même nom à chaque maillon**, en minuscules collées pour les colonnes et les attributs.

## 2. Tables, colonnes, attributs

| Règle | Bon | Mauvais |
|---|---|---|
| table en MAJUSCULES, au singulier | `JOUET`, `TOYDETAIL` | |
| colonnes en minuscules collées, **identiques** aux attributs | colonne `lib` ↔ attribut `lib` | 🍿 colonne `lib` ↔ attribut `libelle` (→ `ORA-00904` à l'`INSERT`) |
| clé primaire : `id VARCHAR2(100)` | `id` | |
| clé étrangère : `id` + nom de la table visée | `idpopcorn`, `idtypejouet`, `idclient` | |
| la clé étrangère pointe vers **la bonne table** | `idpopcorn REFERENCES POPCORN(id)` | 🍿 `idpopcorn REFERENCES JOUET(id)` |
| une date s'appelle `daty` ; une heure `heure` (texte `"HH:mm"`) | `daty` | |
| une mère a une colonne `etat` | `etat NUMBER DEFAULT 1` | 🍿 `TOY` sans `etat` |
| types Java simples | `String`, `int`, `double`, `java.sql.Date` | `Integer`, `Double` |
| aucun attribut qui ne soit pas une colonne (même `static`) | | |

## 3. Getters et setters : la règle exacte

APJ fabrique le nom du getter ainsi : **`get` + l'attribut avec sa PREMIÈRE lettre en majuscule, et le reste inchangé**.

| Attribut | Getter / setter attendus | Faux 🍿 |
|---|---|---|
| `nom` | `getNom()` / `setNom(String)` | `getnom()` / `setnom(…)` |
| `idclient` | `getIdclient()` / `setIdclient(String)` | `getIdClient()` / `setIdClient(…)` |
| `montanttotal` | `getMontanttotal()` | `getMontantTotal()` |
| `idtypejouet` | `getIdtypejouet()` | `getIdTypeJouet()` |

⚠ Un getter mal nommé ne donne **pas d'erreur de compilation** : APJ ne trouve pas la méthode, et la valeur reste vide (`null` ou 0). C'est l'erreur la plus difficile à voir.

Une méthode de calcul ne commence **jamais** par `get` si ce n'est pas une colonne : `calculerFin()`, pas `getFin()`.

## 4. Classes et packages

| Règle | Exemple |
|---|---|
| un package par module, en minuscules | `salle`, `film`, `reservation`, `toy` |
| la 1re ligne du fichier = le **dossier** où il est | fichier `toy/Toy.java` → `package toy;` 🍿 (pas `package film;`) |
| la classe porte le nom de la table, en CamelCase | `TYPEJOUET` → `TypeJouet` |
| la vue `_LIB` → la classe `…Lib` | `PLACE_LIB` → `PlaceLib` |
| la fille → `<Mère>Detail` | `Reservation` / `ReservationDetail` |
| le service → `<Module>Service` | `ReservationService`, `ToyService` |
| les outils communs → `utils.CinemaUtil` | |

Dans les noms complets (`setNomClasseFille`, `setNomClasseMere`), on écrit **package + classe** : `"toy.ToyDetail"`.

## 5. Séquences, fonctions, préfixes

| Pour la table | Séquence | Fonction | Préfixe |
|---|---|---|---|
| `X` | `SEQ_X` | `GETSEQX` | 3 lettres, uniques dans le projet |

- La fonction lit **sa propre** séquence : `GETSEQJOUET` → `SEQ_JOUET.NEXTVAL`. 🍿 Les 5 fonctions du popcorn lisaient toutes `SEQ_SALLE`.
- Chaque `CREATE … FUNCTION … END;` est suivi d'un **`/` seul sur sa ligne**.
- `preparePk` reçoit le nom de la **fonction**, pas celui de la séquence.

Détails : [creer_une_sequence.md](creer_une_sequence.md).

## 6. Mère et fille : les mêmes noms partout

| Mère | Fille | Valeur |
|---|---|---|
| `setNomClasseFille(…)` | — | `"toy.ToyDetail"` |
| — | `setNomClasseMere(…)` + `getNomClasseMere()` | `"toy.Toy"` |
| `setLiaisonFille(…)` | `setLiaisonMere(…)` + `getLiaisonMere()` | **la même** colonne, dans la table fille : `"idtoy"` 🍿 (pas `"idreservation"`) |

Détails : [classes_mere_fille.md](classes_mere_fille.md).

## 7. Pages

| Règle | Exemple |
|---|---|
| dossier `cinema-war/web/pages/<module>/` | `pages/reservation/` |
| fichiers `<module>-liste.jsp`, `-saisie.jsp`, `-fiche.jsp`, `inc/<module>-details.jsp` | `reservation-fiche.jsp` |
| toujours appelée par `module.jsp?but=<module>/<fichier>.jsp` | `lien + "?but=reservation/reservation-fiche.jsp&id=" + id` |
| afficher → la vue `_LIB` ; écrire → la classe de base, via le service | |
| 1re ligne : `<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>` | |
| accents dans le HTML : `&eacute;` `&egrave;` `&agrave;` `&ccedil;` | `R&eacute;servation` |

Détails : [creer_une_page.md](creer_une_page.md).

## 8. États

| Valeur | Sens | Code |
|---|---|---|
| 1 | créé | `ConstanteEtat.getEtatCreer()` |
| 11 | validé | `ConstanteEtat.getEtatValider()` |
| 0 | annulé | `ConstanteEtat.getEtatAnnuler()` |

Une mère payée tout de suite est enregistrée **validée** : `this.setEtat(ConstanteEtat.getEtatValider())` dans `createObject`. Sinon `etat` vaut 0 (= annulé). Voir [createObject.md](createObject.md) §7.

## 9. Menu

`MENUDYNAMIQUE` (l'entrée) + `USERMENU` (qui la voit, `refuser='*'` = tout le monde). Les ids commencent par `MENCINEMA…` / `USMCINEMA…`, la rubrique « Cinéma » est `MENCINEMA`. Détails : [creer_une_page.md](creer_une_page.md) §7.

## 10. Copier un modèle sans se tromper

Les docs donnent des modèles avec des noms neutres (`Conteneur`, `Element`, `ElementLib`, `idconteneur`, `numero`…) ou ceux du scénario 1 (`SEQ_SALLE`, `idreservation`, `FLM`…). **Ces noms n'existent pas dans ton module** : chaque modèle copié doit être adapté. 🍿 C'est la cause de la plupart des erreurs du challenge.

Après chaque copier-coller :
1. ☐ **Rechercher dans le fichier** (Ctrl+F) les mots du modèle : `Element`, `Conteneur`, `numero`, `SALLE`, `reservation`, `FLM`, `film`… Il ne doit plus en rester.
2. ☐ Les noms de **colonnes** dans les filtres SQL existent dans **ta** table.
3. ☐ Le `package` est celui du dossier.
4. ☐ Chaque fonction `GETSEQ…` lit **sa** séquence.
5. ☐ **Compiler tout de suite** :
   ```bash
   cd /home/balou/S5/MrTahina/cinema
   JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant compile
   ```
   `BUILD SUCCESSFUL` en 2 secondes ; sinon l'erreur donne le fichier et la ligne. **Après chaque fichier**, pas à la fin. ⚠ Si la compilation échoue, `ant` ne peut plus déployer **tout** le projet, y compris les modules qui marchaient.
