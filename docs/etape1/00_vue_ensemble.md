# Cinéma — Étape 1 : se connecter et voir un menu vide

## Objectif de l'étape

Créer un projet APJ **vierge**, à partir du socle d'*async standard*, qui :
- se déploie sur le même WildFly, à l'adresse `localhost:8080/cinema` ;
- se connecte à sa propre base Oracle, l'utilisateur `cinema` ;
- permet de se connecter et affiche un **menu vide**.

## Où en est l'étape

| # | Sous-étape | État |
|---|---|---|
| 1 | Créer l'utilisateur Oracle `cinema` | ✅ fait |
| 2 | Créer la structure des dossiers | ✅ fait |
| 3 | Copier le front minimal (connexion + `module.jsp`) | à faire |
| 4 | Copier le Java minimal et alléger `UserEJBBean` | à faire |
| 5 | Adapter `build.xml` | à faire |
| 6 | Créer les tables du socle dans `cinema` | à faire |
| 7 | Déployer, se connecter, voir le menu vide | à faire |

---

## Sous-étape 1 : l'utilisateur Oracle `cinema`

Créé par la commande SQL suivante, exécutée en administrateur (`sqlplus / as sysdba`) :

```sql
CREATE USER cinema IDENTIFIED BY cinema
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SYNONYM, CREATE TYPE
  TO cinema;
```

| Ligne | Ce qu'elle fait |
|---|---|
| `CREATE USER cinema IDENTIFIED BY cinema` | crée le compte `cinema`, avec le mot de passe `cinema` |
| `DEFAULT TABLESPACE USERS` | indique où ses tables seront stockées, comme pour `arbiochemstandard` |
| `TEMPORARY TABLESPACE TEMP` | indique l'espace utilisé pour les tris et calculs temporaires |
| `QUOTA UNLIMITED ON USERS` | l'autorise à remplir cet espace ; sans ça, la création de tables échoue |
| `GRANT CREATE SESSION` | l'autorise à se connecter |
| `GRANT CREATE TABLE, VIEW, SEQUENCE, PROCEDURE, TRIGGER, SYNONYM, TYPE` | l'autorise à créer les objets dont le socle a besoin |

**Comment se connecter en administrateur dans le conteneur** (piège rencontré) :
- en `root` : `sqlplus` est trouvé, mais `root` n'est pas administrateur Oracle → `ORA-01031: insufficient privileges` ;
- en `oracle` : l'utilisateur a les droits (groupe `dba`), mais le chemin vers `sqlplus` n'est pas défini → `command not found`.

Commande qui fonctionne, depuis le terminal de la machine :

```bash
docker exec -it -u oracle oracle bash -c 'export ORACLE_HOME=/u01/app/oracle/product/11.2.0/EE ORACLE_SID=EE PATH=/u01/app/oracle/product/11.2.0/EE/bin:$PATH; sqlplus / as sysdba'
```

**Vérification** (programme JDBC jetable) :

```
connecte en CINEMA | tables=0 | privileges=202
```

Le compte se connecte et ne contient encore aucune table. Il a 202 privilèges : plus que les 8 demandés, sans doute parce qu'un rôle comme `DBA` lui a été donné. C'est suffisant pour un projet local.

---

## Sous-étape 2 : la structure des dossiers

Emplacement : `/home/balou/S5/MrTahina/cinema/`

| Dossier | Rôle |
|---|---|
| `build-file/lib/` | les bibliothèques `.jar` : le framework APJ (`apj-core.jar`, `apj-core2.jar`), le pilote Oracle, etc. |
| `cinema-ejb/src/conf/` | fichiers de configuration de l'EJB (`MANIFEST.MF`, `jboss.xml`) |
| `cinema-ejb/src/java/` | le code Java : `apj.properties` (connexion à la base), `user/` (actions de l'utilisateur), `utils/` (constantes), `resources/` (textes), puis les futurs modules métier |
| `cinema-war/src/java/servlet/` | les servlets propres au projet |
| `cinema-war/web/` | tout ce qui est servi au navigateur : `index.jsp`, `WEB-INF/`, `pages/`, CSS, JS, images |
| `cinema-war/web/pages/elements/` | les morceaux communs à toutes les pages : en-tête, menu, pied de page |
| `database/` | les scripts SQL qui créent les tables du socle dans `cinema` |
| `docs/` | `apprentissageAPJ/` (les leçons), `conception/` (la conception du cinéma), `etape1/`… (une documentation par étape) |

J'ai choisi des noms **`cinema-ejb`** et **`cinema-war`**, plutôt que de garder `arbiochem-*`, pour que rien ne rappelle l'ancien projet.

### Fichiers créés

| Fichier | Rôle |
|---|---|
| `README.md` | présente le projet et sa structure |
| `.gitignore` | dit à Git d'ignorer les dossiers produits par `ant` (`cinema_jar/`, `cinema_war/`, `ear/`) et les fichiers d'IDE : ils sont recréés à chaque build et n'ont pas à être versionnés |
| `.gitkeep` dans chaque dossier vide | Git ne versionne pas les dossiers vides ; ce fichier vide permet de les garder jusqu'à ce qu'ils soient remplis |

J'ai aussi initialisé un dépôt Git (`git init`, branche `main`), sans faire de commit.
