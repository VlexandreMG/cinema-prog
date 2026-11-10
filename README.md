# Cinéma

Projet vierge construit sur le framework **APJ**, à partir du socle d'*async standard*.

- Serveur : WildFly 10.1, adresse prévue `http://localhost:8080/cinema`
- Base : Oracle 11g (conteneur Docker `oracle`), utilisateur `cinema`
- Construction et déploiement : `ant`, depuis ce dossier

## Lancer le cinéma

```bash
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ant      # compile + déploie dans WildFly
cd /home/balou/S5/MrTahina/akoho.zip/wildfly-10.1.0.Final
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ./bin/standalone.sh
```
Ouvrir http://localhost:8080/cinema, compte **`cinema` / `cinema`**.

Base : `database/00_socle.sql`, puis `01_tables_metier.sql`, puis `02_donnees_test.sql`, dans le compte `cinema`.
Les jars de `build-file/lib/` ne sont pas versionnés : voir `docs/etape1/00_vue_ensemble.md`, sous-étape 5.

État : étape 1 terminée (connexion + menu), scénario 1 (réservation et paiement) en place. Voir `docs/conception/`.

## Structure

```
cinema/
├── build.xml              construction + déploiement (à venir)
├── build-file/lib/        bibliothèques (.jar), dont apj-core.jar et apj-core2.jar
├── cinema-ejb/            couche métier (Java)
│   └── src/
│       ├── conf/          MANIFEST.MF, jboss.xml
│       └── java/          apj.properties, user/, utils/, resources/, puis les modules métier
├── cinema-war/            couche écran (JSP)
│   ├── src/java/servlet/  servlets du projet
│   └── web/               index.jsp, WEB-INF/, pages/, CSS, JS, images
├── database/              scripts SQL du socle
└── docs/                  apprentissageAPJ/, conception/, etape1/...
```

La documentation détaillée de chaque étape se trouve dans `docs/`.
