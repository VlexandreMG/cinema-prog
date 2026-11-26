# Chercher des exemples APJ dans KoloTV

`/home/balou/S5/MrTahina/KoloTV` : un projet APJ complet. Les commandes se lancent depuis `/home/balou/S5/MrTahina`.

## La commande de base

```bash
grep -rn --include=*.java --include=*.jsp "MOT" KoloTV/
```
`-r` tous les dossiers · `-n` numéro de ligne · `--include` seulement Java et JSP.

## Les classes métier (EJB)

```bash
# Les classes qui surchargent createObject / validerObject
grep -rn "public ClassMAPTable createObject" KoloTV/kolotv-ejb/src/java
grep -rn "public Object validerObject"       KoloTV/kolotv-ejb/src/java

# Les classes mère / fille
grep -rln "extends ClassMere"  KoloTV/kolotv-ejb/src/java
grep -rln "extends ClassFille" KoloTV/kolotv-ejb/src/java
grep -rn  "setLiaisonFille"    KoloTV/kolotv-ejb/src/java

# Les mises à jour en base
grep -rn "updateToTableWithHisto" KoloTV/kolotv-ejb/src/java

# Les recherches en base
grep -rn "CGenUtil.rechercher" KoloTV/kolotv-ejb/src/java | head -20
```

## Les pages (affichage)

```bash
# Les pages qui utilisent une classe d'affichage APJ
grep -rln "PageInsertMultiple" KoloTV/kolotv-war/web/pages
grep -rln "PageInsert("        KoloTV/kolotv-war/web/pages
grep -rln "PageConsulte"       KoloTV/kolotv-war/web/pages
grep -rln "PageRecherche"      KoloTV/kolotv-war/web/pages

# Des fonctions APJ précises
grep -rn "changerEnChamp"          KoloTV/kolotv-war/web/pages | head -20
grep -rn "setLien("                KoloTV/kolotv-war/web/pages | head -20

# Les actions de la page "après" (insert, valider, annuler...)
grep -n "acte.compareToIgnoreCase" KoloTV/kolotv-war/web/pages/apresMultiple.jsp
```

## Les fichiers d'un module

```bash
ls KoloTV/kolotv-war/web/pages/reservation/       # les pages
ls KoloTV/kolotv-ejb/src/java/reservation/        # les classes
```

## Les options utiles

| Option | Effet |
|---|---|
| `grep -rln …` | seulement les **noms** de fichiers |
| `grep -rn -i …` | sans tenir compte des majuscules |
| `grep -rn -A10 …` | affiche aussi les 10 lignes **après** chaque résultat |
| `grep -rn -B5 …` | affiche aussi les 5 lignes **avant** chaque résultat |
| `… \| head -20` | seulement les 20 premiers résultats |

Exemple : voir en entier les `validerObject` de KoloTV, avec le code autour :
```bash
grep -rn -A15 "public Object validerObject" KoloTV/kolotv-ejb/src/java | head -60
```
