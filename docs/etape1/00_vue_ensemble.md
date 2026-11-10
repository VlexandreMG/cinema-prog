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
| 3 | Copier le front minimal (connexion + `module.jsp`) | ✅ fait |
| 4 | Copier le Java minimal et alléger `UserEJBBean` | ✅ fait |
| 5 | Adapter `build.xml` | ✅ fait |
| 6 | Créer les tables du socle dans `cinema` | ✅ fait |
| 7 | Déployer, se connecter, voir le menu | ✅ fait (le menu n'est pas vide : il contient déjà « Cinéma › Réserver ») |

**En bref, pour lancer le cinéma :**
```bash
cd /home/balou/S5/MrTahina/cinema
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant          # compile + déploie
cd /home/balou/S5/MrTahina/akoho.zip/wildfly-10.1.0.Final
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ./bin/standalone.sh
```
Puis ouvrir **http://localhost:8080/cinema** et se connecter avec **`cinema` / `cinema`**.

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

---

## Sous-étape 3 : le front minimal (connexion + `module.jsp`)

**Source :** `akohoVierge/projet-standard - Copie/arbiochem-war/` (le socle d'async standard).
**Liste des fichiers gardés :** `akoho/mini-projet/arbiochem-war-a-garder.txt`, déjà préparée lors du mini-projet (« login + squelette de `module.jsp` »). 230 fichiers copiés vers `cinema-war/` :

| Fichiers | Rôle |
|---|---|
| `web/index.jsp` | la page de connexion |
| `web/pages/testLogin.jsp` | vérifie l'identifiant et le mot de passe, puis redirige vers `module.jsp` |
| `web/pages/module.jsp`, `security-login.jsp` | le cadre de toutes les pages : en-tête, menu, puis la page demandée par `?but=` |
| `web/pages/elements/` | en-tête, menu, pied de page, CSS et JS communs |
| `web/pages/accueil.jsp`, `deconnexion.jsp` | accueil et déconnexion |
| `web/WEB-INF/web.xml`, `WEB-INF/META-INF/apj/web-fragment.xml` | déclarations web (servlets d'APJ) |
| `web/assets/`, `bootstrap/`, `dist/`, `plugins/`, `apjplugins/` | styles, scripts et images |

**Retiré ou modifié :**
- **Le chatbot** (`pages/Chatbot/chat.jsp`, `moduleLeger.jsp`) n'est pas copié, et son `<jsp:include>` est retiré de `module.jsp`.
- **`testLogin.jsp`** : retrait de ce qui est propre à l'ancienne application (le chatbot, le point de vente `ConstanteAsync.MAGAGIN`, la recherche de direction dans `LOG_DIRECTION`). `dirlib` vaut toujours `%`.

**Ajouté :** `web/WEB-INF/jboss-deployment-structure.xml`, qui exclut le sous-système `pojo`. Repris du mini-projet, il évite un conflit avec l'autre application APJ déployée sur le même WildFly.

---

## Sous-étape 4 : le Java minimal et `UserEJBBean` allégé

### Le problème
`UserEJBBean` d'origine fait 4 153 lignes et touche à toute l'application (vente, paie, stock…). En le copiant tel quel, il faut **243 fichiers Java** pour qu'il compile.

### La méthode
1. **Lister les méthodes vraiment appelées :**
   - par les jars APJ, en cherchant les appels `user/UserEJB.*` dans `apj-core.jar` et `apj-core2.jar` avec `javap -c` : 13 méthodes (`getUser`, `getData`, `getDataPage…`, `updateObject`, `validerObject`, `getTraduction`…) ;
   - par les pages gardées : `testLogin`, `findConfiguration`, `findHomePageServices`, `getMaSociete`, `getCnapsUser`, `setLangue`, `ejbRemove`… ;
   - par ces méthodes elles-mêmes (`testeValide`, `testRangUser`, `getuVue`…), ajoutées tant que la compilation signalait un symbole manquant.
2. **Générer** `UserEJB` (interface) et `UserEJBBean` en ne gardant que ces méthodes, recopiées telles quelles, avec les attributs qu'elles utilisent.
3. **Réécrire `testLogin`** : il ne charge plus que l'utilisateur, son rôle, le `CNAPSUser`, la configuration, la page d'accueil, les droits et la société. Il ne charge plus le magasin, le personnel, les directions ni les caisses.
4. **Laisser `javac` trouver le reste :** compiler `UserEJBBean` avec, comme `-sourcepath`, tout le code d'origine. `javac` ne compile que ce qui est réellement utilisé.

### Le résultat : 6 fichiers au lieu de 243

| Fichier | Rôle |
|---|---|
| `user/UserEJB.java` | interface allégée (48 méthodes) |
| `user/UserEJBBean.java` | l'utilisateur connecté, allégé (58 méthodes) |
| `user/CreateObject.java`, `UpdateObject.java`, `ValiderObject.java` | aides utilisées par `createObject` / `updateObject` / `validerObject` |
| `societe/Societe.java` | la société (logo, favicon), lue dans `MASOCIETE` |

Plus la configuration :

| Fichier | Contenu |
|---|---|
| `apj.properties` | connexion Oracle : `jdbc:oracle:thin:@127.0.0.1:1521:EE`, compte `cinema` / `cinema`, `apj.debug=true` (les requêtes SQL s'affichent dans le log) |
| `project.properties`, `resources/text*.properties` | paramètres et textes de l'interface, copiés tels quels |

⚠ **Ne pas ajouter de méthode dans `UserEJB` sans la mettre dans `UserEJBBean`**, et ne pas en retirer une qu'appellent les jars APJ (liste ci-dessus) : sinon, erreur à l'exécution.

---

## Sous-étape 5 : `build.xml`

Réécrit à partir de celui d'arbiochem, avec les mêmes étapes :

```
clean → init → compile → buildEjbJar → compileWar → copieProperties → deploy
```

| Changement | Pourquoi |
|---|---|
| noms `cinema`, `cinema-ejb.jar`, `cinema.war` | le WAR `cinema.war` est servi à `/cinema` |
| `encoding="UTF-8"` (au lieu d'`iso-8859-1`), `source/target 1.8` | nos fichiers sont en UTF-8 ; WildFly 10 tourne en Java 8 |
| chemins `/` au lieu de `\` | Linux |
| déploiement dans `cinema.war` + `cinema.war.dodeploy` | WAR « éclaté », comme l'original |

**Les jars** (`build-file/lib/`, 128 fichiers, 233 Mo) sont copiés depuis `akohoVierge/projet-standard - Copie/build-file/lib/`. Ils sont ignorés par Git (`.gitignore`) : après un `git clone`, il faut les recopier.

```bash
cp "/home/balou/S5/MrTahina/akoho.zip/akoho/akohoVierge/projet-standard - Copie/build-file/lib/"*.jar build-file/lib/
```

**Commandes** (Ant doit utiliser le JDK 8) :
```bash
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant compile   # vérifier que ça compile
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant           # compiler + déployer
```

---

## Sous-étape 6 : les tables du socle

Script : [database/00_socle.sql](../../database/00_socle.sql), exécuté dans `cinema`, **avant** [01_tables_metier.sql](../../database/01_tables_metier.sql) puis [02_donnees_test.sql](../../database/02_donnees_test.sql).

Les tables sont **recopiées depuis `ARBIOCHEMSTANDARD`** (même instance Oracle ; `cinema` a le rôle DBA et peut les lire). Elles ont été trouvées en lisant le code décompilé d'APJ et en suivant les erreurs `ORA-00942` :

| Copiées avec leurs données | Copiées vides | Vues recréées |
|---|---|---|
| `UTILISATEUR`, `PARAMCRYPT`, `ROLES`, `DIRECTION`, `CNAPS_USER`, `CONFIGURATION`, `MASOCIETE` | `ANNULATIONUTILISATEUR`, `ACTIONROLE`, `HISTORIQUE`, `MENUDYNAMIQUE`, `USERMENU`, `USERHOMEPAGE` | `LISTECOLONNETABLE`, `UTILISATEURVALIDE`, `UTILISATEURVUE` |

Plus la séquence `SEQHISTORIQUE` et sa fonction `GETSEQHISTORIQUE` (APJ écrit une ligne d'historique à chaque insertion).

| Objet | Qui l'utilise |
|---|---|
| `LISTECOLONNETABLE` | **tout APJ** : `ListeColonneTable` y lit les colonnes de chaque table pour construire ses requêtes. Sans elle, aucune recherche ne marche. |
| `UTILISATEURVALIDE`, `UTILISATEURVUE`, `PARAMCRYPT` | la connexion (`UtilisateurUtil.testeValide`) |
| `MENUDYNAMIQUE`, `USERMENU` | le menu (`MenuDynamique.getElementMenu`) |
| `USERHOMEPAGE` | la page affichée après la connexion (`findHomePageServices`) |
| `MASOCIETE` | le logo et le favicon (en-tête, menu) |

**Ajouté par le script :**
- **le compte `cinema` / `cinema`** (rôle `dsi`). Le mot de passe est stocké chiffré : `Utilitaire.cryptWord("cinema", 4, 1)` = `8ejai6`, avec la ligne `PARAMCRYPT` correspondante. Les comptes recopiés du socle (dont `admin`) marchent aussi, avec leurs mots de passe habituels ;
- **le menu** « Cinéma › Réserver » (`MENUDYNAMIQUE` + `USERMENU`, avec `refuser='*'` : visible par tous) ;
- **la page d'accueil** des rôles `dsi` et `dg` : l'écran de réservation (`USERHOMEPAGE`).

### Pièges rencontrés
| Symptôme | Cause | Solution |
|---|---|---|
| `Erreur makewhere : ORA-00942` à la connexion | la vue `LISTECOLONNETABLE` manquait | la recréer |
| « Identifiant ou mot de passe invalide » avec `admin` | un `admin` existait déjà dans les comptes recopiés (et l'id 900001 avait déjà un `PARAMCRYPT`) | compte du cinéma nommé `cinema`, id 990001 |
| `Erreur makewhere : null` dans `findHomePageServices` | la table `USERHOMEPAGE` manquait | la créer |

---

## Sous-étape 7 : déployer, se connecter, voir le menu

```bash
cd /home/balou/S5/MrTahina/cinema
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant
cd /home/balou/S5/MrTahina/akoho.zip/wildfly-10.1.0.Final
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ./bin/standalone.sh
```
WildFly crée `deployments/cinema.war.deployed` quand le déploiement a réussi (`cinema.war.failed` sinon, avec l'erreur dedans). Il déploie aussi les autres applications du dossier (`prog-elia.war`).

Ouvrir **http://localhost:8080/cinema**, se connecter avec **`cinema` / `cinema`** : on arrive directement sur l'écran de réservation, avec le menu « Cinéma › Réserver ».

### Vérifié le 10/11/2026 (avec `curl`, dans le vrai serveur)
| Test | Résultat |
|---|---|
| page de connexion | 200 |
| connexion `cinema` / `cinema` | redirection vers `module.jsp?but=reservation/reservation-saisie.jsp` |
| menu | contient « Cinéma » et « Réserver » |
| choix du film *Dune 3* | salle « Salle 1 » remplie, 2 séances à venir |
| choix de la séance | 40 places libres |
| récapitulatif A1 + E8 | Standard 15 000 + VIP 25 000 = **40 000 Ar** |
| paiement avec 30 000 Ar | refusé : « il manque 10 000 Ar » |
| paiement avec 50 000 Ar | réservation `RSV000004` créée, fiche avec « monnaie rendue : 10 000 Ar » |
| réserver à nouveau A1 pour la même séance | refusé : « La place A1 est déjà réservée pour cette séance. » |
| places libres ensuite | 38 |

La réservation `RSV000004` (Rakoto Jean, A1 + E8, séance de Dune 3 du 11/11 à 18h00) est restée en base : c'est une donnée de démonstration.

### Bug trouvé et corrigé pendant ces tests
La réservation était enregistrée avec `etat = 0`, la valeur par défaut d'un `int`, qui veut dire « annulée ». Ses places restaient donc « libres », et une double réservation passait. `Reservation.createObject` enregistre maintenant la réservation **validée** (`etat = ConstanteEtat.getEtatValider()` = 11), puisqu'elle est payée tout de suite.

### Ce qui reste
- Les alertes JavaScript du socle d'origine ont des accents abîmés (« Ã©lÃ©ments ») : c'est dans les fichiers copiés (`elements/js.jsp`…), pas dans les pages du cinéma.
- Rien n'a encore été vérifié visuellement dans un navigateur : seulement le HTML renvoyé par le serveur.
