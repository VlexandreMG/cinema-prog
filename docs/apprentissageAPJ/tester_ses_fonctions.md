# Tuto — Tester ses fonctions sans passer par l'écran

Comment écrire et lancer un petit programme qui **appelle directement tes fonctions métier** (`reserver`, `genererFacture`, `acheterFilm`…) et affiche le résultat, **sans déployer** et **sans rien laisser en base**.

C'est la méthode utilisée pour tous les tests de ce projet : le bug du `etat = 0`, le compteur de factures, la caisse, l'erreur `"20.00"` de l'aléa…

Voir aussi [fonctions_metier.md](fonctions_metier.md) §8.

---

## 1. Pourquoi tester sans l'écran ?

| Par l'écran | Par un programme de test |
|---|---|
| il faut `ant`, attendre le redéploiement, se connecter, cliquer | une commande, quelques secondes |
| l'erreur passe dans une alerte qui disparaît | le message s'affiche dans le terminal |
| chaque essai **enregistre vraiment** en base | tout est **annulé** à la fin (`rollback`) |
| on teste une seule situation à la fois | on enchaîne 10 cas d'un coup (17:00, 20:00, place prise…) |

## 2. Où mettre les tests

```
cinema-ejb/
├── src/java/        ← le code de l'application : compilé par ant ET déployé dans WildFly
└── test/            ← les tests : jamais compilés par ant, jamais déployés
    └── TestReservation.java
```

⚠ **Pas dans `cinema-ejb/src/java/`.** Ant compile **tout** ce dossier dans `cinema-ejb.jar` :
- le test partirait **en production**, dans WildFly ;
- un test qui ne compile pas **bloquerait tout le build**, et plus rien ne se déploierait.

✅ **Dans `cinema-ejb/test/`** : Ant ne le connaît pas. Le dossier est versionné par Git (les tests font partie du projet), mais les classes compilées vont dans `build-file/test/`, qui est ignoré par Git.

## 3. Le modèle d'un test

```java
import java.sql.Connection;
import reservation.*;

/**
 * Teste la réservation. Rien n'est gardé en base : tout est annulé à la fin.
 * Lancer : voir docs/apprentissageAPJ/tester_ses_fonctions.md §4
 */
public class TestReservation {

    public static void main(String[] args) throws Exception {
        Connection c = new utilitaire.UtilDB().GetConn();
        c.setAutoCommit(false);                          // ① rien ne sera validé...
        try {
            // ② retrouver les données PAR LEUR NOM, jamais par un id écrit en dur
            String client = (String) bean.CGenUtil.rechercherSimple(
                    "select min(id) from CLIENT", c);
            String seance = (String) bean.CGenUtil.rechercherSimple(
                    "select min(id) from SEANCE where heure = '17:00' and daty > sysdate", c);
            String place = ReservationService.listerPlacesLibres(seance, c)[0].getId();

            // ③ appeler la fonction testée, en passant la connexion c
            Reservation r = ReservationService.reserver(client, seance, new String[]{place}, "990001", c);

            // ④ afficher ce qu'on veut vérifier
            System.out.println("OK " + r.getId() + " total = " + r.getMontanttotal());

        } catch (Exception e) {
            System.out.println("ECHEC : " + e.getMessage());   // ⑤ le message de l'erreur
            e.printStackTrace();                               //    et OÙ elle est née
        } finally {
            c.rollback();                                      // ⑥ ...et tout est annulé
            c.close();
        }
    }
}
```

| Repère | Pourquoi |
|---|---|
| ① `setAutoCommit(false)` | toutes les écritures restent **en attente** jusqu'au `commit`… qui n'arrivera jamais |
| ② ids **cherchés**, pas écrits en dur | les ids dépendent des séquences (`CAI000002`, `DIS000002`…) : un id écrit en dur casse dès qu'on recharge la base |
| ③ on passe **`c`** | la fonction travaille dans **notre** transaction, donc tout sera annulé. Avec `null`, elle ouvrirait sa propre connexion et ferait **un vrai `commit`** |
| ④ `System.out.println` | on affiche les valeurs à contrôler : id, total, nombre de lignes… |
| ⑤ `e.getMessage()` + `e.printStackTrace()` | le message, puis la **pile d'appels** : le fichier et la ligne où l'erreur est née |
| ⑥ `rollback` dans `finally` | exécuté **dans tous les cas**, même après une erreur : la base est toujours remise comme avant |

`"990001"` est l'id du compte `cinema` : il doit être **numérique**, car il est écrit dans `HISTORIQUE`.

## 4. Le lancer

Depuis le dossier `cinema/` :
```bash
# 1. compiler l'application (le test appelle TON VRAI code)
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant compile

# 2. compiler le test
CP="build-file/cinema_jar:build-file/lib/*"
/usr/lib/jvm/java-8-openjdk-amd64/bin/javac -cp "$CP" -d build-file/test cinema-ejb/test/TestReservation.java

# 3. le lancer
/usr/lib/jvm/java-8-openjdk-amd64/bin/java -cp "build-file/test:$CP" TestReservation
```
- `build-file/cinema_jar` contient tes classes compilées **et** `apj.properties` : le test se connecte tout seul à la base `cinema`.
- `build-file/lib/*` : les jars d'APJ et le pilote Oracle.
- APJ écrit beaucoup de lignes `Requete select rechercher : …`. Pour ne garder que tes messages : `… TestReservation 2>&1 | grep -E "^(OK|ECHEC)"`.

## 5. Tester plusieurs cas d'un coup

Une boucle sur les situations à vérifier, avec **le résultat attendu** affiché à côté :
```java
for (String heure : new String[]{"17:00", "20:00"}) {
    String seance = (String) bean.CGenUtil.rechercherSimple(
            "select min(id) from SEANCE where heure = '" + heure + "' and daty > sysdate", c);
    String place = ReservationService.listerPlacesLibres(seance, c)[0].getId();
    try {
        Reservation r = ReservationService.reserver(client, seance, new String[]{place}, "990001", c);
        System.out.println(heure + " : OK total = " + r.getMontanttotal());
    } catch (Exception e) {
        System.out.println(heure + " : ECHEC " + e.getMessage());
    }
}
```
Exemple réel de sortie, pendant l'aléa de la promotion :
```
17:00 : ECHEC Heure invalide : '20.00'. Format attendu : HH:mm (ex. 18:00).
20:00 : ECHEC Heure invalide : '20.00'. Format attendu : HH:mm (ex. 18:00).
```
→ les **deux** séances échouent, avec le **même** message qui cite `'20.00'` : le problème n'est pas l'heure de la séance, mais la constante écrite dans le code.

**Tester aussi ce qui doit ÉCHOUER** : une place déjà prise, un montant trop grand, une séance passée… Un refus attendu qui **passe** est un bug.
```java
try {
    ReservationService.reserver(client, seance, new String[]{placeDejaPrise}, "990001", c);
    System.out.println("ERREUR : la place déjà prise a été acceptée");
} catch (Exception e) {
    System.out.println("refus OK : " + e.getMessage());
}
```

## 6. Vérifier aussi la base, dans le test

Les objets Java ne disent pas tout : regarde ce qui a **vraiment** été écrit, avec la même connexion `c` :
```java
Object n = bean.CGenUtil.rechercherSimple(
        "select count(*) || ' lignes, somme ' || sum(prix) from RESERVATIONDETAIL where idreservation = '"
        + r.getId() + "'", c);
System.out.println("en base : " + n);
```
Pour une promotion à 50 % sur deux places à 15 000, on attend : `2 lignes, somme 15000`, **et** un total de réservation de 15 000. Si le total vaut 15 000 mais que la somme des lignes vaut 30 000, la promotion n'est appliquée qu'au total.

## 7. Les pièges

| Symptôme | Cause | Solution |
|---|---|---|
| `package reservation does not exist` en compilant le test | **l'application ne compile pas** : quand `ant compile` échoue, `build-file/cinema_jar` reste **vide** | corriger d'abord l'erreur de compilation de l'application (`ant compile` doit dire `BUILD SUCCESSFUL`) |
| des données restent en base après le test | la fonction a reçu `null` au lieu de `c` : elle a ouvert **sa** connexion et fait un vrai `commit` | toujours passer `c` |
| `getFille(...)`, `listerLignes(...)` ne trouvent **rien** pendant le test | une lecture faite avec `null` : une autre connexion ne voit pas ce qui n'est pas encore validé | passer `c` à **toutes** les lectures du test |
| `Client introuvable : CLI000001` | id écrit en dur, qui n'existe plus après un rechargement de la base | chercher l'id par une requête (§3 ②) |
| `ORA-01722` dans `HISTORIQUE` | l'utilisateur passé n'est pas numérique | `"990001"` |
| le test passe mais l'écran plante | le serveur fait tourner une **ancienne** version (pas de `ant` depuis la correction), ou l'erreur est dans la **JSP** (non testée ici) | `ant`, attendre `cinema.war.deployed`, puis tester l'écran ; le test ne vérifie que le **métier** |

## 8. Checklist d'un bon test

1. ☐ Le fichier est dans `cinema-ejb/test/`, pas dans `src/java/`.
2. ☐ `setAutoCommit(false)` au début, `rollback()` dans un `finally`.
3. ☐ La connexion `c` est passée à **toutes** les fonctions.
4. ☐ Les ids sont **cherchés**, jamais écrits en dur.
5. ☐ Chaque cas affiche son **résultat** et ce qu'on **attendait**.
6. ☐ Les refus attendus sont testés aussi (`try` / `catch`).
7. ☐ `ant compile` passe **avant** de lancer le test.
