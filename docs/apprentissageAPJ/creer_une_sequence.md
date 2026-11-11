# Tuto — Créer une séquence pour APJ

Ce tuto explique comment APJ fabrique les ids comme `SAL000001` ou `RSV000004`, et comment créer ce qu'il faut dans Oracle pour une nouvelle table. Il complète le §2 de [creer_une_classe_apj.md](creer_une_classe_apj.md).

Exemple fil rouge : la table **SALLE** du scénario 1.

---

## 1. À quoi sert une séquence ?

Chaque ligne d'une table a besoin d'un **id unique** (sa clé primaire). Une **séquence** Oracle est un compteur : à chaque appel, elle donne le nombre suivant (1, 2, 3…). Elle ne donne jamais deux fois le même, même si deux utilisateurs enregistrent en même temps.

APJ transforme ce nombre en id texte :

```
séquence → 1   →   APJ   →   "SAL" + "000001"   =   SAL000001
```

## 2. Le trajet complet (vérifié dans `apj-core.jar`)

```
Salle.java                         Oracle
──────────                         ──────
construirePK(c)
  preparePk("SAL", "GETSEQSALLE")  ← retient le préfixe et le NOM DE LA FONCTION
  makePK(c)
    exécute : select GETSEQSALLE from dual ──► GETSEQSALLE()
                                                  SELECT SEQ_SALLE.NEXTVAL ...
                                                  RETURN 1
    complète à 6 chiffres : "000001"
    renvoie  : "SAL" + "000001"
  setId("SAL000001")
```

Trois objets travaillent ensemble :

| Objet | Où | Rôle | Exemple |
|---|---|---|---|
| le **préfixe** | Java (`preparePk`) | les lettres devant l'id | `SAL` |
| la **fonction** | Oracle | ce qu'APJ appelle | `GETSEQSALLE` |
| la **séquence** | Oracle | le compteur, utilisé par la fonction | `SEQ_SALLE` |

### Pourquoi une fonction, et pas directement la séquence ?

APJ exécute exactement `select <nom> from dual`. Avec le nom d'une séquence, ça donnerait `select SEQ_SALLE from dual`, qu'Oracle refuse (`ORA-00904`) : une séquence se lit avec `SEQ_SALLE.NEXTVAL`. La fonction sert d'intermédiaire. On l'appelle par son nom seul, et c'est elle qui fait le `NEXTVAL`.

## 3. Créer la séquence et la fonction

```sql
CREATE SEQUENCE SEQ_SALLE;

CREATE OR REPLACE FUNCTION GETSEQSALLE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_SALLE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/
```

| Morceau | Ce qu'il fait |
|---|---|
| `CREATE SEQUENCE SEQ_SALLE;` | crée le compteur ; il commence à 1 et avance de 1 |
| `CREATE OR REPLACE FUNCTION GETSEQSALLE RETURN NUMBER` | crée (ou remplace) une fonction sans paramètre qui renvoie un nombre |
| `IS r NUMBER;` | déclare une variable `r` |
| `SELECT SEQ_SALLE.NEXTVAL INTO r FROM DUAL;` | prend le nombre suivant du compteur et le met dans `r` |
| `RETURN r;` | renvoie ce nombre à APJ |
| `/` | **seul sur sa ligne** : dit à SQL*Plus d'exécuter le bloc PL/SQL. Sans lui, la fonction n'est pas créée. |

Et côté Java, dans la classe :

```java
@Override
public void construirePK(Connection c) throws Exception {
    this.preparePk("SAL", "GETSEQSALLE");   // préfixe + NOM DE LA FONCTION
    this.setId(makePK(c));
}
```

## 4. Les conventions de nommage du projet

| Pour la table | Séquence | Fonction | Préfixe |
|---|---|---|---|
| `SALLE` | `SEQ_SALLE` | `GETSEQSALLE` | `SAL` |
| `PLACE` | `SEQ_PLACE` | `GETSEQPLACE` | `PLC` |
| `RESERVATION` | `SEQ_RESERVATION` | `GETSEQRESERVATION` | `RSV` |
| `RESERVATIONDETAIL` | `SEQ_RESERVATIONDETAIL` | `GETSEQRESERVATIONDETAIL` | `RSD` |

- **Une séquence et une fonction par table.**
- **Préfixe de 3 lettres, différent pour chaque table** : en lisant `RSD000012`, on sait tout de suite de quelle table vient l'id.
- Le nom de la fonction dans `preparePk` doit être **exactement** celui créé dans Oracle. Majuscules et minuscules n'ont pas d'importance pour Oracle, mais une lettre en trop, si.

## 5. Utiliser la séquence dans un script SQL (données de test)

Quand on insère des lignes **à la main** (jeu d'essai), on passe aussi par la fonction, en imitant le format d'APJ :

```sql
INSERT INTO SALLE (id, nom) VALUES ('SAL' || LPAD(GETSEQSALLE, 6, '0'), 'Salle 1');
```

`LPAD(x, 6, '0')` complète à gauche avec des zéros jusqu'à 6 caractères : `1` → `000001`, comme APJ.

**Pourquoi ne pas écrire directement `'SAL000001'` ?** Parce que la séquence, elle, n'aurait pas avancé. La première salle créée ensuite par l'application recevrait aussi `SAL000001`, et Oracle refuserait l'insertion (`ORA-00001`, clé en double). C'est ce que fait [02_donnees_test.sql](../../database/02_donnees_test.sql).

## 6. Vérifier

```sql
-- Les séquences du compte, et où elles en sont
SELECT sequence_name, last_number FROM user_sequences ORDER BY 1;

-- Les fonctions : STATUS doit être VALID
SELECT object_name, status FROM user_objects WHERE object_type = 'FUNCTION' ORDER BY 1;

-- Appeler la fonction comme APJ (⚠ cela CONSOMME un numéro)
SELECT GETSEQSALLE FROM dual;
```

⚠ **`last_number` n'est pas le dernier numéro donné.** Oracle réserve les numéros par paquets de 20 (le **cache**). `last_number` est le premier numéro **pas encore réservé**, donc souvent plus grand que le dernier id réellement utilisé. Pour connaître le dernier id, regarde la table : `SELECT max(id) FROM salle;`.

## 7. Les « trous » dans les ids sont normaux

Une séquence ne revient **jamais** en arrière. Un numéro peut donc être consommé sans qu'aucune ligne ne l'utilise :
- **une transaction annulée** : l'insertion est défaite, mais le numéro reste consommé ;
- **un test** `SELECT GETSEQSALLE FROM dual` ;
- **un redémarrage d'Oracle**, qui perd les numéros encore en cache.

Exemple réel dans notre base : les premiers tests de réservation ont été faits dans une transaction **annulée** à la fin. `RSV000001` à `RSV000003` ont été consommés, mais n'existent pas dans la table. La première vraie réservation a été `RSV000004`.

Ce n'est pas un bug : un id doit être **unique**, pas forcément **continu**. Ne jamais essayer de « boucher les trous ».

## 8. Les erreurs fréquentes

| Symptôme | Cause | Solution |
|---|---|---|
| Page blanche après « Valider », `ORA-00904 "GETSEQX"` dans le log | la fonction n'existe pas, ou son nom est mal écrit dans `preparePk` | créer la fonction (§3), ou corriger le nom |
| `ORA-00904` alors que la **séquence** existe | `preparePk` reçoit le nom de la séquence (`SEQ_X`) au lieu de celui de la fonction (`GETSEQX`) | passer le nom de la fonction |
| La fonction est créée mais `INVALID` | faute dans son code, ou la séquence n'existe pas encore | `SHOW ERRORS FUNCTION GETSEQX` dans SQL*Plus ; créer la séquence **avant** la fonction |
| Rien ne se passe après le `END;` | le `/` manque, ou n'est pas seul sur sa ligne | ajouter `/` sur sa propre ligne |
| `ORA-00955` : nom déjà utilisé | le script est relancé, et la séquence existe déjà | ne pas relancer le `CREATE SEQUENCE` (la fonction, avec `OR REPLACE`, peut l'être) |
| `ORA-00001` : contrainte unique violée sur `id` | des lignes ont été insérées avec des ids écrits à la main, et la séquence est « en retard » | faire avancer la séquence (§9) |

## 9. Remettre une séquence en avance

Cas typique : la table contient déjà `SAL000050` (insérée à la main), mais la séquence va redonner 3, 4, 5… et finira par retomber sur un id existant. Sous Oracle 11g, on recrée la séquence **après** le plus grand id existant :

```sql
-- 1. Le plus grand numéro utilisé (on retire le préfixe de 3 lettres)
SELECT max(to_number(substr(id, 4))) FROM salle;      -- par exemple 50

-- 2. Recréer la séquence pour qu'elle reparte au-dessus
DROP SEQUENCE SEQ_SALLE;
CREATE SEQUENCE SEQ_SALLE START WITH 51;
```

La fonction `GETSEQSALLE` devient `INVALID` au moment du `DROP`, puis Oracle la recompile tout seul au prochain appel. Pas besoin de la recréer.

## 10. Le modèle à copier pour une nouvelle table

Remplace `MATABLE` par le nom de ta table, et `MTB` par un préfixe de 3 lettres libre :

```sql
CREATE SEQUENCE SEQ_MATABLE;
CREATE OR REPLACE FUNCTION GETSEQMATABLE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_MATABLE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/
```

```java
this.preparePk("MTB", "GETSEQMATABLE");
this.setId(makePK(c));
```

Checklist :
1. ☐ La séquence `SEQ_MATABLE` est créée **avant** la fonction.
2. ☐ La fonction `GETSEQMATABLE` est `VALID` (`user_objects`).
3. ☐ `preparePk` reçoit le **nom de la fonction**, pas celui de la séquence.
4. ☐ Le préfixe n'est utilisé par aucune autre table.
5. ☐ Les données de test passent par `'MTB' || LPAD(GETSEQMATABLE, 6, '0')`.
