# Cinéma

Projet vierge construit sur le framework **APJ**, à partir du socle d'*async standard*.

- Serveur : WildFly 10.1, adresse prévue `http://localhost:8080/cinema`
- Base : Oracle 11g (conteneur Docker `oracle`), utilisateur `cinema`
- Construction et déploiement : `ant`, depuis ce dossier

Objectif de l'étape 1 : **se connecter et voir un menu vide**.

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
