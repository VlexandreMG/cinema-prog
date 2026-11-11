# Aide-mémoire — Les fonctions de `CinemaUtil` et les fonctions APJ

Une phrase par fonction, un exemple, et où elle sert dans le projet. Pour les détails, suis les liens vers les autres tutos.

---

## 1. `utils.CinemaUtil` : les outils du projet cinéma

Fichier : [utils/CinemaUtil.java](../../cinema-ejb/src/java/utils/CinemaUtil.java). Ces fonctions ne viennent pas d'APJ : elles ont été écrites pour le cinéma.

| Fonction | En une phrase | Exemple | Utilisée dans |
|---|---|---|---|
| `parId(modele, id, c)` | Charge **un** enregistrement par son id, et lance une exception (« Film introuvable : … ») s'il n'existe pas ou si l'id est vide. | `Film f = (Film) CinemaUtil.parId(new Film(), "FLM000001", c);` | les contrôles de `createObject`, `salleDuFilm`, les pages |
| `echapper(valeur)` | Double les apostrophes d'un texte, pour pouvoir le coller dans une requête SQL sans la casser. | `" and id = '" + CinemaUtil.echapper(id) + "'"` | tous les filtres `CGenUtil.rechercher` |
| `html(texte)` | Protège un texte (`<`, `>`, `&`, `"`, `'`) avant de l'écrire dans une page HTML, pour qu'un nom bizarre ne casse pas l'affichage. | `<%= CinemaUtil.html(client.getNom()) %>` | les 3 pages de réservation |
| `montant(valeur)` | Écrit un nombre avec une espace entre les milliers et sans décimales. | `CinemaUtil.montant(38000)` → `"38 000"` | les pages (prix, total, monnaie) |
| `date(d)` | Écrit une date SQL au format `jj/mm/aaaa`, ou une chaîne vide si elle est `null`. | `CinemaUtil.date(seance.getDaty())` → `"11/11/2026"` | les pages (séance, date de réservation) |
| `minutesDepuisMinuit(heure)` | Transforme une heure `"HH:mm"` en nombre de minutes depuis minuit, et refuse un format invalide. | `minutesDepuisMinuit("18:30")` → `1110` | `Seance.calculerDebut` (chevauchements, séances à venir) |

**Pourquoi une classe à part ?** Ce sont des petits outils sans lien avec une table. Les mettre dans une classe métier ajouterait des méthodes inutiles, et APJ risquerait de prendre un `getXxx` pour une colonne (voir [creer_une_classe_apj.md](creer_une_classe_apj.md) §3). Ils sont donc tous `static` et regroupés dans `utils`.

---

## 2. Les fonctions APJ utilisées dans le projet

### 2.1 Décrire une classe (dans `ClassMAPTable`)

| Fonction | En une phrase | Exemple |
|---|---|---|
| `setNomTable("X")` | Dit quelle table (ou vue) la classe lit et écrit ; elle ne lance aucune requête. | `this.setNomTable("SALLE");` |
| `getTuppleID()` | **À écrire** : renvoie la valeur de la clé de l'objet. | `return id;` |
| `getAttributIDName()` | **À écrire** : renvoie le nom de l'attribut clé. | `return "id";` |
| `construirePK(c)` | **À écrire** : fabrique l'id ; APJ l'appelle dans `createObject` si l'id est vide. | voir ci-dessous |
| `preparePk(prefixe, fonction)` | Retient le préfixe de l'id et le nom de la **fonction** Oracle à appeler, sans rien exécuter. | `this.preparePk("SAL", "GETSEQSALLE");` |
| `makePK(c)` | Exécute `select GETSEQSALLE from dual`, complète le nombre à 6 chiffres et renvoie l'id complet. | `this.setId(makePK(c));` → `SAL000001` |

Détails : [creer_une_classe_apj.md](creer_une_classe_apj.md) §3, [creer_une_sequence.md](creer_une_sequence.md).

### 2.2 Enregistrer

| Fonction | En une phrase | Exemple |
|---|---|---|
| `createObject(u, c)` | Enregistre l'objet : `controler`, puis l'id si vide, puis `INSERT` + ligne d'historique (et les lignes, pour une mère). C'est **la** méthode qu'on redéfinit pour mettre ses contrôles. | `return super.createObject(u, c);` |
| `controler(c)` | Ne fait rien par défaut ; on la redéfinit pour contrôler, surtout dans une **fille** (c'est elle qui est appelée pour chaque ligne). | `throw new Exception("…")` |

Détails : [createObject.md](createObject.md).

### 2.3 Mères et filles (`ClassMere` / `ClassFille`)

| Fonction | En une phrase | Exemple |
|---|---|---|
| `setNomClasseFille("pkg.Classe")` | Dans la mère : donne le nom complet de la classe de ses lignes. | `"reservation.ReservationDetail"` |
| `setLiaisonFille("col")` | Dans la mère : donne la colonne des lignes qui contient l'id de la mère. | `"idreservation"` |
| `setNomClasseMere("pkg.Classe")` | Dans la fille : donne le nom complet de la classe mère. | `"reservation.Reservation"` |
| `setLiaisonMere("col")` | Dans la fille : la même colonne de liaison, vue de la fille. | `"idreservation"` |
| `setFille(lignes)` | Attache des lignes à la mère, en mémoire, avant `createObject`. | `r.setFille(lignes);` |
| `getFille()` | Renvoie les lignes **en mémoire** (`null` si aucune n'est attachée) ; elle **ne lit pas** la base. | `(ReservationDetail[]) this.getFille()` |
| `getFille(nomTable, c, filtre)` | **Recharge** les lignes de la mère depuis la base. | `r.getFille(null, c, "")` |

Détails : [classes_mere_fille.md](classes_mere_fille.md).

### 2.4 Lire en base (`bean.CGenUtil`)

| Fonction | En une phrase | Exemple |
|---|---|---|
| `CGenUtil.rechercher(modele, null, null, c, filtre)` | Exécute `select * from <table du modèle> where 1<2 <filtre>` et renvoie un tableau d'objets **du type du modèle**. | `(Film[]) CGenUtil.rechercher(new Film(), null, null, c, " order by titre asc")` |
| `CGenUtil.rechercherSimple(sql, c)` | Exécute une requête qui renvoie **une seule valeur** (un `count`, une somme…), et la renvoie comme un `Object` à convertir en `Number`. | `((Number) CGenUtil.rechercherSimple("select count(*) from …", c)).intValue()` |

À retenir sur `rechercher` :
- le filtre commence par `" and "` et peut finir par `" order by …"` ;
- **jamais** la version à 2 arguments (`ORA-00903`) ;
- chaque attribut **non vide** du modèle est ajouté au `where`. Un modèle vide (`new Film()`) ne filtre donc rien ;
- si `c` vaut `null`, APJ ouvre et ferme une connexion lui-même.

Détails : [creer_une_classe_apj.md](creer_une_classe_apj.md) §5, [fonctions_metier.md](fonctions_metier.md) §3.

### 2.5 Connexion, date, état (`utilitaire`, `constante`)

| Fonction | En une phrase | Exemple |
|---|---|---|
| `new UtilDB().GetConn()` | Ouvre une connexion à la base décrite dans `apj.properties` (ici le compte `cinema`). | `c = new UtilDB().GetConn(); c.setAutoCommit(false);` |
| `Utilitaire.dateDuJourSql()` | Renvoie la date du jour, au format `java.sql.Date`. | `this.setDaty(Utilitaire.dateDuJourSql());` |
| `ConstanteEtat.getEtatValider()` | Renvoie la valeur de l'état « validé » (11). | `this.setEtat(ConstanteEtat.getEtatValider());` |
| `ConstanteEtat.getEtatCreer()` / `getEtatAnnuler()` | Renvoient l'état « créé » (1) et l'état « annulé » (0). | |
| `Utilitaire.cryptWord(mot, niveau, croissante)` | Chiffre un mot de passe comme APJ le fait à la connexion. | `cryptWord("cinema", 4, 1)` → `8ejai6` (voir [l'étape 1](../etape1/00_vue_ensemble.md), sous-étape 6) |

### 2.6 La session, dans une JSP

| Code | En une phrase |
|---|---|
| `(UserEJB) session.getAttribute("u")` | L'utilisateur connecté, mis en session par `testLogin.jsp`. |
| `u.getUser().getTuppleID()` | Son id (`990001` pour le compte `cinema`), à passer comme `u` à `createObject` : il doit être **numérique**, car il est écrit dans `HISTORIQUE`. |
| `(String) session.getAttribute("lien")` | `"module.jsp"` : la base de tous les liens (`lien + "?but=…"`). |

---

## 3. Qui fait quoi : la vue d'ensemble

```
Page JSP ──► Service (ReservationService)      ──► Classe métier (Reservation)        ──► APJ
             - UtilDB.GetConn / commit / rollback  - createObject : contrôles, calculs     - createObject : id, INSERT, historique
             - CGenUtil.rechercher (lectures)      - construirePK : preparePk + makePK     - rechercher : SELECT
             - setFille + createObject             - CinemaUtil.parId pour vérifier         - makePK : séquence
CinemaUtil : parId, echapper (SQL) · html, montant, date (affichage) · minutesDepuisMinuit (heures)
```
