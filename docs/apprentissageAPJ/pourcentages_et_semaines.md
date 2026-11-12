# Rappel — Pourcentages et calculs par semaine (avec des dates)

Un aide-mémoire court, avec des exemples du cinéma. Tous les exemples SQL et Java ont été **vérifiés** le 12/11/2026 dans la base `cinema` (Oracle 11g) et en Java 8.

---

## 1. Les pourcentages

### 1.1 Les 4 formules à connaître

| Je veux… | Formule | Exemple cinéma |
|---|---|---|
| **la part** d'un tout, en % | `part / total × 100` | 9 places vendues sur 12 → 9 / 12 × 100 = **75 %** (taux de remplissage) |
| **appliquer** un % à un montant | `montant × % / 100` | 20 % de 15 000 → 15 000 × 20 / 100 = **3 000** |
| **augmenter** de x % | `montant × (1 + x / 100)` | 10 000 + 15 % → 10 000 × 1,15 = **11 500** |
| **réduire** de x % (remise) | `montant × (1 − x / 100)` | 20 000 − 25 % → 20 000 × 0,75 = **15 000** |

### 1.2 L'évolution entre deux valeurs (« de combien ça a changé ? »)

> **évolution % = (nouvelle − ancienne) / ancienne × 100**

| Semaine 1 | Semaine 2 | Calcul | Évolution |
|---|---|---|---|
| 40 000 | 50 000 | (50 000 − 40 000) / 40 000 × 100 | **+25 %** |
| 50 000 | 40 000 | (40 000 − 50 000) / 50 000 × 100 | **−20 %** |

⚠ On divise toujours par l'**ancienne** valeur. C'est pour ça que +25 % puis −20 % font revenir au point de départ, et pas +25 % puis −25 %.

⚠ **Si l'ancienne valeur vaut 0**, l'évolution n'existe pas (division par zéro) : il faut le traiter à part (« nouveau », ou « — »).

### 1.3 Pourcentage ou « points de pourcentage » ?
Un taux de remplissage passe de **40 %** à **50 %** :
- il a gagné **10 points** (50 − 40) ;
- il a augmenté de **25 %** ((50 − 40) / 40 × 100).

Ce n'est pas la même chose : écrire « +10 points » pour la différence de deux pourcentages.

### 1.4 Le piège en Java : la division entière

```java
int vendues = 2, capacite = 3;
double t1 = vendues / capacite * 100;          // = 0      ← 2/3 entre ENTIERS vaut 0, puis 0 × 100
double t2 = vendues * 100.0 / capacite;        // = 66.666...  ← un 100.0 suffit à passer en décimal
double t3 = Math.round(vendues * 100.0 / capacite * 10) / 10.0;   // = 66.7  (1 décimale)
```
Vérifié : `2/3*100` donne **0** en Java. Dès qu'un des nombres est un `double` (`100.0`), le calcul se fait en décimal. Nos montants sont des `double`, mais les **compteurs** (`count`, `length`) sont des `int`.

**Multiplier avant de diviser** (`× 100` en premier) garde plus de précision.

### 1.5 En SQL (Oracle)

```sql
-- Taux de remplissage d'une séance : places réservées / places de la salle × 100
SELECT se.id,
       COUNT(d.id)                                         AS vendues,
       (SELECT COUNT(*) FROM place p WHERE p.idsalle = f.idsalle) AS capacite,
       ROUND(COUNT(d.id) * 100 / (SELECT COUNT(*) FROM place p WHERE p.idsalle = f.idsalle), 1) AS taux
FROM seance se
JOIN film f ON f.id = se.idfilm
LEFT JOIN reservation r ON r.idseance = se.id AND r.etat <> 0
LEFT JOIN reservationdetail d ON d.idreservation = r.id
GROUP BY se.id, f.idsalle;
```
- En Oracle, **pas de piège de division entière** : `2/3*100` vaut 66,666… (vérifié). `ROUND(x, 1)` arrondit à 1 décimale → **66,7**.
- Si la salle n'a **aucune place**, la division par 0 donne une erreur (`ORA-01476`). On se protège avec `NULLIF(capacite, 0)` : `x / NULLIF(capacite, 0)` vaut alors `NULL` au lieu de planter.

## 2. Les dates et les semaines

### 2.1 Ce qu'il faut savoir sur une `DATE` Oracle
- Une `DATE` contient **le jour ET l'heure** (même si l'heure est 00:00). `TRUNC(date)` remet l'heure à 00:00.
- **Date + nombre = date + jours** : `DATE '2026-11-16' + 7` → 23/11/2026.
- **Date − date = nombre de jours** : `DATE '2026-11-30' − DATE '2026-11-16'` → **14** (vérifié).

Dans le cinéma, `SEANCE.daty` ne garde que le jour ; l'heure est à part, dans `heure` (`"18:00"`).

### 2.2 La semaine d'une date (semaine ISO : du lundi au dimanche)

| Je veux… | SQL Oracle | Résultat vérifié |
|---|---|---|
| le **lundi** de la semaine d'une date | `TRUNC(daty, 'IW')` | jeudi 19/11 → **16/11** ; dimanche 22/11 → **16/11** |
| le **numéro** de semaine ISO | `TO_CHAR(daty, 'IW')` | 16/11 et 22/11 → **47** ; 23/11 → **48** |
| l'**année** de cette semaine | `TO_CHAR(daty, 'IYYY')` | 2026 |
| le **jour** : 0 = lundi … 6 = dimanche | `daty - TRUNC(daty, 'IW')` | 16/11 → **0** ; 22/11 → **6** |
| le **nom** du jour, en français | `TO_CHAR(daty, 'DY', 'NLS_DATE_LANGUAGE=FRENCH')` | **LUN.** |
| le **prochain** lundi | `NEXT_DAY(daty, 'MONDAY')` | après le 12/11 → **16/11** |

`'IW'` = **I**SO **W**eek : la semaine commence **toujours le lundi**, quel que soit le réglage du serveur. C'est elle qu'il faut utiliser.

### 2.3 ⚠ Les deux pièges des jours de la semaine

| Piège | Ce qui se passe (vérifié) | Solution |
|---|---|---|
| `TO_CHAR(daty, 'D')` (numéro du jour) | un lundi donne **2**, parce que la base est réglée en `AMERICA` (la semaine y commence le **dimanche**). Sur une base réglée en `FRANCE`, il donnerait 1. **Le résultat dépend du serveur.** | `daty - TRUNC(daty, 'IW')` : 0 = lundi, **toujours** |
| `TO_CHAR(daty, 'DAY')` (nom complet) | « `LUNDI   ` » est **complété par des espaces** jusqu'à la longueur du jour le plus long : `= 'LUNDI'` est **faux** | `'DY'` (abrégé), ou `TRIM(TO_CHAR(daty, 'DAY'))`, ou mieux : le calcul 0 à 6 |

### 2.4 Grouper par semaine

```sql
-- Le nombre de séances par semaine
SELECT TRUNC(daty, 'IW') AS lundi, COUNT(*) AS seances
FROM seance
GROUP BY TRUNC(daty, 'IW')
ORDER BY lundi;
```
Résultat réel sur le programme du 16 au 30/11 :
```
16/11  18      (semaine 47 : du 16 au 22)
23/11  18      (semaine 48 : du 23 au 29)
30/11   5      (semaine 49 : seulement le lundi 30 est dans le programme)
```
**On groupe par le lundi** (`TRUNC(…, 'IW')`) plutôt que par le numéro de semaine : c'est une vraie date, qu'on peut trier et afficher, et qui ne se mélange pas d'une année à l'autre (la semaine 1 existe chaque année).

Les **recettes** par semaine, avec l'évolution par rapport à la semaine précédente :
```sql
SELECT lundi, recette,
       ROUND((recette - LAG(recette) OVER (ORDER BY lundi)) * 100
             / NULLIF(LAG(recette) OVER (ORDER BY lundi), 0), 1) AS evolution_pct
FROM (SELECT TRUNC(daty, 'IW') AS lundi, SUM(entree) AS recette
      FROM mouvementcaisse WHERE etat >= 11
      GROUP BY TRUNC(daty, 'IW'))
ORDER BY lundi;
```
`LAG(recette)` donne la recette de la **ligne précédente** (la semaine d'avant) ; la 1re semaine n'en a pas, donc son évolution vaut `NULL`.

### 2.5 Filtrer une période : attention à la dernière journée

```sql
-- Tout ce qui se passe du 16/11 au 22/11 INCLUS
WHERE daty >= DATE '2026-11-16' AND daty < DATE '2026-11-22' + 1
```
**Pourquoi `< fin + 1`, et pas `BETWEEN … AND DATE '2026-11-22'` ?** Parce qu'une `DATE` peut avoir une heure : `22/11 à 15:00` est **après** `22/11 à 00:00`, et serait **exclu** par `BETWEEN`. Avec `< 23/11`, toute la journée du 22 est incluse. (Pour `SEANCE.daty`, qui est à 00:00, les deux marchent ; pour `SYSDATE` ou une date avec heure, seul `< fin + 1` est sûr.)

La semaine **en cours** :
```sql
WHERE daty >= TRUNC(SYSDATE, 'IW') AND daty < TRUNC(SYSDATE, 'IW') + 7
```

### 2.6 Passer d'un jour de la semaine à des dates

C'est ce qu'on a fait pour le programme du 16 au 30/11 : « le lundi » → les dates 16, 23 et 30.

**Méthode** : partir de la première date de ce jour, puis ajouter **7 jours** tant qu'on reste dans la période.
```
premier lundi ≥ 16/11 : 16/11        (NEXT_DAY(DATE '2026-11-15', 'MONDAY'))
puis +7 : 23/11, puis +7 : 30/11, puis +7 : 07/12 → hors période, on s'arrête
```
Les autres jours, à partir d'un lundi : mardi = lundi + 1, … , dimanche = lundi + 6.

## 3. Les mêmes calculs en Java 8 (`java.time`)

APJ donne des `java.sql.Date`. On les convertit en `LocalDate` pour calculer :

```java
LocalDate d = seance.getDaty().toLocalDate();                       // 19/11/2026

d.getDayOfWeek();                                                    // THURSDAY
d.getDayOfWeek().getValue();                                         // 4   (1 = lundi … 7 = dimanche)
d.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));          // 2026-11-16  (lundi de la semaine)
d.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY));              // 2026-11-22  (dimanche de la semaine)
d.get(WeekFields.ISO.weekOfWeekBasedYear());                         // 47          (semaine ISO)
ChronoUnit.DAYS.between(LocalDate.of(2026, 11, 16),
                        LocalDate.of(2026, 11, 30));                 // 14
d.plusDays(7);                                                       // une semaine plus tard
java.sql.Date.valueOf(d);                                            // retour vers APJ
```
Imports : `java.time.*` et `java.time.temporal.*`.

Tous les lundis d'une période (vérifié : **16, 23, 30**) :
```java
for (LocalDate x = LocalDate.of(2026, 11, 16); !x.isAfter(LocalDate.of(2026, 11, 30)); x = x.plusDays(1)) {
    if (x.getDayOfWeek() == DayOfWeek.MONDAY) { /* … */ }
}
```

⚠ En Java, `getValue()` va de **1** (lundi) à **7** (dimanche) ; en SQL, `daty - TRUNC(daty, 'IW')` va de **0** (lundi) à **6** (dimanche). Même ordre, décalé de 1.

## 4. Récapitulatif

| Besoin | SQL Oracle | Java 8 |
|---|---|---|
| part en % | `ROUND(part * 100 / NULLIF(total, 0), 1)` | `part * 100.0 / total` (⚠ `100.0`) |
| évolution % | `(n - a) * 100 / NULLIF(a, 0)` | `(n - a) * 100.0 / a` (si `a != 0`) |
| lundi de la semaine | `TRUNC(d, 'IW')` | `d.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))` |
| n° de semaine | `TO_CHAR(d, 'IW')` | `d.get(WeekFields.ISO.weekOfWeekBasedYear())` |
| jour de la semaine | `d - TRUNC(d, 'IW')` (0 = lundi) | `d.getDayOfWeek().getValue()` (1 = lundi) |
| nb de jours entre deux dates | `fin - debut` | `ChronoUnit.DAYS.between(debut, fin)` |
| + n jours | `d + n` | `d.plusDays(n)` |
| période incluse | `d >= debut AND d < fin + 1` | `!d.isBefore(debut) && !d.isAfter(fin)` |

---

## 5. Calculer avec des dates : ce qui est permis, et ce qui ne l'est pas

### 5.1 « 2026-11-16 + 2026-11-15 » : impossible, et c'est normal

```sql
SELECT DATE '2026-11-16' + DATE '2026-11-15' FROM dual;
-- ORA-00975: date + date not allowed        (vérifié)
```

**Pourquoi ?** Une date est un **point** sur la ligne du temps, pas une quantité. Additionner deux points n'a pas de sens : « 16 novembre + 15 novembre » ne correspond à aucun jour.

```
   15/11      16/11                         30/11
 ────●──────────●─────────────────────────────●────▶  le temps
     └── 1 jour ─┘└───────── 14 jours ─────────┘
        (une DURÉE)            (une DURÉE)
```

Il faut distinguer **deux choses** :
| | Ce que c'est | Exemples |
|---|---|---|
| une **date** | un point dans le temps | 16/11/2026, 16/11/2026 à 18:00 |
| une **durée** | une distance entre deux points | 1 jour, 166 minutes, 2 semaines |

Et retenir **les trois seules opérations permises** :
| Opération | Donne | Exemple vérifié |
|---|---|---|
| date **−** date | une **durée** (en jours) | 16/11 − 15/11 = **1** |
| date **+** durée | une **date** | 16/11 + 1 = **17/11** |
| date **−** durée | une **date** | 16/11 − 1 = **15/11** |

**Si tu as besoin d'additionner deux dates**, c'est presque toujours qu'il faut en fait :
- calculer **l'écart** entre elles (date − date) ;
- ou trouver **le milieu** : `début + (fin − début) / 2` (vérifié : 16/11 + 14 / 2 = **23/11**) ;
- ou **combiner une date et une heure** (§5.3).

### 5.2 Ajouter ou retirer une durée (Oracle)

En Oracle, **le nombre ajouté à une date est un nombre de JOURS**. Pour des heures ou des minutes, on divise :
| Je veux ajouter… | SQL | Résultat vérifié (départ : 16/11 00:00) |
|---|---|---|
| 1 jour | `d + 1` | 17/11 00:00 |
| 1 semaine | `d + 7` | 23/11 00:00 |
| 1 heure | `d + 1/24` | 16/11 **01:00** |
| 90 minutes | `d + 90/1440` | 16/11 **01:30** (1 440 = minutes dans une journée) |
| 2 heures (écriture lisible) | `d + INTERVAL '2' HOUR` | 16/11 **02:00** |
| 1 mois | `ADD_MONTHS(d, 1)` | ⚠ 31/01 + 1 mois = **28/02** (le dernier jour du mois) |

Autres utiles :
| Je veux… | SQL | Vérifié |
|---|---|---|
| le 1er du mois | `TRUNC(d, 'MM')` | 16/11 → **01/11** |
| le dernier jour du mois | `LAST_DAY(d)` | 16/11 → **30/11** |
| l'écart en **mois** | `MONTHS_BETWEEN(fin, debut)` | 30/11 − 16/11 → 0,452 |
| l'écart en **minutes** | `(fin - debut) * 24 * 60` | 20:46 − 18:00 → **166** |

### 5.3 Une date + une heure : le cas de nos séances

`SEANCE.daty` (le jour) et `SEANCE.heure` (le texte `"18:30"`) sont **séparés**. Pour avoir le moment exact du début :
```sql
-- jour + (heures × 60 + minutes) / 1440
daty + (TO_NUMBER(SUBSTR(heure, 1, 2)) * 60 + TO_NUMBER(SUBSTR(heure, 4, 2))) / 1440
-- 16/11 + '18:30'  →  16/11/2026 18:30   (vérifié)

-- ou en passant par du texte
TO_DATE(TO_CHAR(daty, 'YYYY-MM-DD') || ' ' || heure, 'YYYY-MM-DD HH24:MI')
```
Et **la fin de la séance** = le début + la durée du film :
```sql
debut + duree / 1440
-- 16/11 18:00 + 166 minutes  →  16/11/2026 20:46   (vérifié)
```
C'est exactement ce que font `Seance.calculerDebut()` et `Seance.calculerFin()` en Java (en millisecondes).

**Deux séances se chevauchent** si chacune commence avant la fin de l'autre :
```
debut1 < fin2  ET  debut2 < fin1
```
C'est la règle de `Seance.createObject`. Des séances qui se **touchent** (l'une finit à 15:45, l'autre commence à 15:45) ne se chevauchent pas, parce que `<` est strict.

### 5.4 Écrire et lire une date : les formats

```sql
TO_DATE('2026-11-16 18:30', 'YYYY-MM-DD HH24:MI')   -- texte → date
TO_CHAR(DATE '2026-11-16', 'DD/MM/YYYY')            -- date → texte : '16/11/2026'
DATE '2026-11-16'                                   -- une date fixe, toujours au format AAAA-MM-JJ
```
| Code | Signifie | ⚠ |
|---|---|---|
| `YYYY` | l'année (2026) | |
| `MM` | le **mois** (11) | |
| `DD` | le jour (16) | |
| `HH24` | l'heure, de 0 à 23 | `HH` seul va de 1 à 12 : 18:30 deviendrait une erreur |
| `MI` | les **minutes** | ⚠ **`MI`, pas `MM`** : `HH24:MM` met le **mois** à la place des minutes. C'est l'erreur la plus fréquente |

Pour comparer, **comparer des dates, jamais du texte** : `'16/11/2026' < '02/12/2026'` est **faux** en texte, car « 1 » vient après « 0 », alors que le 16/11 est bien avant le 02/12.

### 5.5 Les mêmes calculs en Java 8

En Java non plus, on ne peut pas additionner deux dates : `LocalDate` n'a **pas** de méthode pour ça. On utilise des **durées** :
| Je veux… | Java 8 | Vérifié |
|---|---|---|
| lire `"2026-11-16"` | `LocalDate.parse("2026-11-16")` | 2026-11-16 |
| l'écrire en `16/11/2026` | `d.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))` | 16/11/2026 |
| écart en jours | `ChronoUnit.DAYS.between(debut, fin)` | 15/11 → 16/11 : **1** |
| + 1 jour / − 1 jour / + 2 semaines | `d.plusDays(1)` / `d.minusDays(1)` / `d.plusWeeks(2)` | 17/11 / 15/11 / 30/11 |
| + 1 mois | `d.plusMonths(1)` | ⚠ 31/01 → **28/02**, comme Oracle |
| l'écart en jours, mois, années | `Period.between(debut, fin)` | 16/11 → 30/11 : `P14D` (14 jours) |
| une date + une heure | `LocalDateTime.of(d, LocalTime.parse("18:00"))` | 2026-11-16T18:00 |
| + 166 minutes | `debut.plusMinutes(166)` | **20:46** |
| écart en minutes | `Duration.between(debut, fin).toMinutes()` | **166** |
| 1er / dernier jour du mois | `d.withDayOfMonth(1)` / `d.with(TemporalAdjusters.lastDayOfMonth())` | 01/11 / 30/11 |
| le milieu de deux dates | `debut.plusDays(ChronoUnit.DAYS.between(debut, fin) / 2)` | **23/11** |
| comparer | `d.isBefore(f)`, `d.isAfter(f)`, `d.equals(f)` | ⚠ **jamais `==`** entre deux dates |

Format Java : `yyyy` (année), **`MM` (mois)**, `dd` (jour), `HH` (heure 0-23), **`mm` (minutes)**. ⚠ La casse compte : en Java, `MM` = mois et `mm` = minutes. En Oracle, c'est `MM` et `MI`.

### 5.6 Résumé en une phrase

> **On ne peut pas additionner deux dates.** On soustrait deux dates pour avoir une **durée**, et on ajoute une **durée** à une date pour avoir une autre date. En Oracle, une durée s'exprime **en jours** (heures = `/24`, minutes = `/1440`).
