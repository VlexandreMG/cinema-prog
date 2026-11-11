# Cinéma — Popcorn : de « Continuer » jusqu'à la base (le parcours complet)

Ce document suit **pas à pas** ce qui se passe entre le clic sur « Continuer vers le paiement » et l'affichage de la fiche de la vente : ce que le navigateur envoie, quel code s'exécute, quelles requêtes partent vers Oracle, ce qui est écrit en base, et comment on passe d'une page à l'autre.

Toutes les traces viennent d'un **vrai paiement fait dans WildFly le 12/11/2026** : les requêtes SQL ont été lues dans `server.log` (avec `apj.debug=true`), et les lignes en base avec SQL*Plus.

Pages : [popcorn-saisie.jsp](../../cinema-war/web/pages/popcorn/popcorn-saisie.jsp) → [popcorn-paiement.jsp](../../cinema-war/web/pages/popcorn/popcorn-paiement.jsp) → [popcorn-fiche.jsp](../../cinema-war/web/pages/popcorn/popcorn-fiche.jsp)
La page de saisie est décrite dans [05_popcorn_saisie.md](05_popcorn_saisie.md).

---

## 0. Vue d'ensemble

```
 popcorn-saisie.jsp            popcorn-paiement.jsp                          popcorn-fiche.jsp
 ┌──────────────────┐   A    ┌──────────────────────────┐   C     ┌────────┐  D   ┌──────────────────┐
 │ client, paquet,  │──────► │ B. récapitulatif         │───────► │ SERVEUR│────► │ Vente TOY000006  │
 │ ☑ jouets         │ POST   │    + montant reçu        │ POST    │ INSERT │ GET  │ monnaie : 3 000  │
 │ [Continuer]      │        │ [Modifier]      [Payer]  │ acte=   │ en base│      │ jouets, prix payé│
 └──────────────────┘        └──────────────────────────┘ payer   └────────┘      └──────────────────┘
                                  │ Modifier (GET) : retour à la saisie avec le même choix
```

| Étape | Déclencheur | Méthode HTTP | Écrit en base ? |
|---|---|---|---|
| **A** | clic « Continuer vers le paiement » | POST | non (lectures seulement) |
| **B** | la page de paiement s'affiche (récapitulatif) | — | non |
| **C** | clic « Payer » | POST avec `acte=payer` | **oui** : la vente et ses lignes |
| **D** | redirection automatique vers la fiche | GET | non |

Exemple suivi dans tout le document : **Rakoto Jean** achète **Mini Groot** (Collector, 5 000) et **Yoyo** (Classique, 2 000) dans le paquet **Grand caramel**, et donne **10 000 Ar**.

---

## A. Clic sur « Continuer vers le paiement »

### A.1 Dans le navigateur

Le bouton, dans `popcorn-saisie.jsp` :
```html
<form method="post" action="module.jsp?but=popcorn/popcorn-saisie.jsp">
    …
    <button type="submit" formaction="module.jsp?but=popcorn/popcorn-paiement.jsp">Continuer vers le paiement</button>
</form>
```

1. **Vérification par le navigateur** : les listes `idclient` et `idpopcorn` ont `required`. Si l'une est vide, le navigateur bloque l'envoi et affiche un message. Rien ne part au serveur.
2. **`formaction`** remplace l'adresse du formulaire pour **ce bouton seulement** : le formulaire part vers `popcorn-paiement.jsp`, et non vers la saisie.
3. **Ce qui est envoyé** : tous les champs du formulaire qui ont un `name`, en POST. Les cases **non cochées** ne sont pas envoyées.

```
POST /cinema/pages/module.jsp?but=popcorn/popcorn-paiement.jsp
Corps : idclient=CLI000002 & idpopcorn=POP000008 & idjouet=JOT000013 & idjouet=JOT000015
```
Le nom `idjouet` apparaît **deux fois** : c'est comme ça qu'un formulaire envoie plusieurs cases cochées.

### A.2 Sur le serveur : `module.jsp` puis la page

1. `module.jsp` vérifie la session (`security-login.jsp`), affiche l'en-tête et le menu, puis **inclut** la page donnée par `but` : `popcorn/popcorn-paiement.jsp`.
2. `popcorn-paiement.jsp` s'exécute **du début** :

```java
String idclient  = request.getParameter("idclient");          // "CLI000002"
String idpopcorn = request.getParameter("idpopcorn");         // "POP000008"
String[] idjouets = request.getParameterValues("idjouet");    // {"JOT000013", "JOT000015"}
if (… vide …) throw new Exception("…");                       // contrôle serveur : on ne fait pas confiance au navigateur
double total = ToyService.calculerMontant(idjouets, null);    // 7 000, calculé avec les prix EN BASE
// pas de "acte" → on n'enregistre rien, on affiche le récapitulatif
Client  client  = (Client)  CinemaUtil.parId(new Client(),  idclient,  null);
Popcorn popcorn = (Popcorn) CinemaUtil.parId(new Popcorn(), idpopcorn, null);
JouetLib[] jouets = ToyService.chargerElements(idjouets, null);
```

### A.3 Les requêtes SQL réelles (lues dans `server.log`)

```sql
select * from utilisateur where 1<2                                         -- module.jsp : l'en-tête
select * from MENUDYNAMIQUE where 1<2 order by niveau,rang asc              -- module.jsp : le menu
select * from JOUET_LIB where 1<2 and id in ('JOT000013','JOT000015')       -- calculerMontant → chargerElements
select * from CLIENT where 1<2 and id = 'CLI000002'                         -- parId(Client)
select * from POPCORN where 1<2 and id = 'POP000008'                        -- parId(Popcorn)
select * from JOUET_LIB where 1<2 and id in ('JOT000013','JOT000015')       -- chargerElements pour le tableau
```
**Aucun `INSERT`** : l'étape A ne fait que lire.

`JOUET_LIB` est lue deux fois (une pour le total, une pour le tableau). C'est volontaire : deux fonctions simples et réutilisables, plutôt qu'une fonction qui ferait les deux. Le coût est négligeable.

---

## B. La page de récapitulatif

### B.1 Ce qui s'affiche (réel)
```
Vérifier et payer
Client             Rakoto Jean
Paquet de popcorn  Grand caramel
Jouets (2)         Mini Groot   Collector   5 000
                   Yoyo         Classique   2 000
                   Total                    7 000
Paiement           Montant à payer [ 7 000 ]  (lecture seule)
                   Montant reçu    [ 7000  ]  (nombre, min = 7000)
[Modifier]                                    [Payer]
```

### B.2 Le formulaire « Payer » : ce qu'il renverra

```html
<form method="post" action="module.jsp?but=popcorn/popcorn-paiement.jsp">   ← la MÊME page
    <input type="hidden" name="acte"      value="payer">        ← le signal « enregistre »
    <input type="hidden" name="idclient"  value="CLI000002">    ┐
    <input type="hidden" name="idpopcorn" value="POP000008">    │ le choix, recopié
    <input type="hidden" name="idjouet"   value="JOT000013">    │ en champs cachés
    <input type="hidden" name="idjouet"   value="JOT000015">    ┘
    <input type="number" name="montantrecu" min="7000" value="7000" required>
    <button type="submit">Payer</button>
</form>
```

| Élément | Pourquoi |
|---|---|
| champs **cachés** | le serveur ne se souvient de rien entre deux demandes : le choix doit **repartir** avec le formulaire |
| `acte=payer` | la même page sait faire deux choses ; ce paramètre lui dit laquelle |
| `method="post"` | une écriture en base se fait **toujours** en POST. Un GET peut être rejoué par un lien, un favori, un rafraîchissement |
| `min` + `required` | le navigateur refuse un montant vide ou trop petit. Le serveur revérifie quand même (C.2) |

### B.3 Le lien « Modifier »
```
module.jsp?but=popcorn/popcorn-saisie.jsp&idclient=CLI000002&idpopcorn=POP000008&idjouet=JOT000013&idjouet=JOT000015
```
Un simple lien (GET) qui renvoie le choix à la saisie : elle relit les paramètres et remet les `selected` et `checked`. La saisie accepte donc indifféremment GET et POST.

---

## C. Clic sur « Payer » : l'enregistrement en base ⭐

### C.1 Ce que le navigateur envoie
```
POST /cinema/pages/module.jsp?but=popcorn/popcorn-paiement.jsp
Corps : acte=payer & idclient=CLI000002 & idpopcorn=POP000008
        & idjouet=JOT000013 & idjouet=JOT000015 & montantrecu=10000
```

### C.2 Dans `popcorn-paiement.jsp` : la branche « payer »

```java
double total = ToyService.calculerMontant(idjouets, null);                        // ① 7 000, recalculé
if ("payer".equals(request.getParameter("acte")) && "POST".equalsIgnoreCase(request.getMethod())) {
    UserEJB u = (UserEJB) session.getAttribute("u");                              // ② l'utilisateur connecté
    double recu = Double.parseDouble(request.getParameter("montantrecu") …);      // ③ 10 000
    if (recu < total) throw new Exception("Montant reçu insuffisant : …");        // ④ contrôle serveur
    Toy vente = ToyService.creerToy(idclient, idpopcorn, idjouets,
                                    u.getUser().getTuppleID(), null);              // ⑤ → C.3
    // ⑥ → D : redirection
}
```
- **②** `u.getUser().getTuppleID()` vaut `"990001"`, l'id du compte `cinema`. Il doit être **numérique**, car il est écrit dans `HISTORIQUE.IDUTILISATEUR`.
- **④** le navigateur a déjà vérifié avec `min`, mais une requête peut être fabriquée à la main : le serveur ne fait **jamais** confiance au navigateur.

### C.3 Dans `ToyService.creerToy` : la transaction

```java
c = new UtilDB().GetConn();  c.setAutoCommit(false);   // ① une connexion, une TRANSACTION
Toy a = new Toy();  a.setIdclient("CLI000002");  a.setIdpopcorn("POP000008");   // ② la mère : seulement le choix
ToyDetail d1 = new ToyDetail();  d1.setIdjouet("JOT000013");                     // ③ une ligne par jouet :
ToyDetail d2 = new ToyDetail();  d2.setIdjouet("JOT000015");                     //    ni id, ni idtoy, ni prix
a.setFille(new ClassFille[]{ d1, d2 });                                          // ④ attacher les lignes
a.createObject("990001", c);                                                     // ⑤ → C.4
c.commit();                                                                      // ⑥ tout est écrit d'un coup
c.close();
```
`setAutoCommit(false)` : rien n'est **définitif** avant le `commit()`. Si quoi que ce soit échoue entre ① et ⑥, `rollback()` efface tout (C.7).

### C.4 Dans `Toy.createObject` : les règles (code de [Toy.java](../../cinema-ejb/src/java/toy/Toy.java))

| # | Ce qui se passe | SQL envoyé |
|---|---|---|
| ① | le client existe | `select * from CLIENT where 1<2 and id = 'CLI000002'` |
| ① | le paquet existe | `select * from POPCORN where 1<2 and id = 'POP000008'` |
| ① | **verrou** sur le paquet : une 2ᵉ vente du même paquet attend la fin de celle-ci | `select id from POPCORN where id = 'POP000008' for update` (*) |
| ③ | au moins un jouet : `this.getFille()` contient 2 lignes | — |
| ④ | jouet 1 : il existe, il n'est pas en double, il est dans **ce** paquet | `select * from JOUET where 1<2 and id = 'JOT000013'` |
| ④ | jouet 1 : pas déjà vendu (`estVendu`) | `select count(*) from TOYDETAIL d join TOY t … where d.idjouet = 'JOT000013' and t.etat <> 0` (*) → 0 |
| ④ | jouet 1 : prix de son type, **recopié** dans la ligne : `d1.setPrix(5000)` | `select * from TYPEJOUET where 1<2 and id = 'TPJ000008'` |
| ④ | jouet 2 : mêmes contrôles, `d2.setPrix(2000)` | `JOUET … 'JOT000015'`, `count(*) …` (*), `TYPEJOUET … 'TPJ000007'` |
| ⑤ | `etat = 11` (validée, car payée), `montanttotal = 7000` | — |
| ⑥ | `return super.createObject("990001", c)` → C.5 | |

(*) envoyé avec `CGenUtil.rechercherSimple`, qu'APJ **n'écrit pas** dans le log. Les autres lignes sont **copiées de `server.log`**.

### C.5 Dans APJ (`ClassMere.createObject`) : les `INSERT`

```
1. Pour la MÈRE (ClassMAPTable.createObject) :
   controler(c)                          → rien (pas redéfini dans Toy)
   construirePK(c)                       → GETSEQTOY → 6 → "TOY000006"
   INSERT dans HISTORIQUE                → "Insertion par 990001", objet toy.Toy
   INSERT dans TOY                       → la vente
2. Pour CHAQUE LIGNE (en lot, createObjectBatch) :
   idtoy = "TOY000006"                   → la liaison est remplie par APJ
   controler(c)                          → rien (pas redéfini dans ToyDetail)
   construirePK(c)                       → GETSEQTOYDETAIL → "TOD000009", puis "TOD000010"
   INSERT dans HISTORIQUE + INSERT dans TOYDETAIL
3. executeBatch()                        → envoie les INSERT des lignes d'un coup
```

Les requêtes réelles du log :
```sql
INSERT INTO TOY ( id , idclient , montanttotal , idpopcorn , etat )
  values ( 'TOY000006','CLI000002',7000.0,'POP000008',11 )
INSERT INTO historique ( idHistorique , dateHistorique , heure , objet , action , idUtilisateur , refObjet )
  values ( 'EX0000000072','12/11/2026','01:50:31','toy.Toy','Insertion par 990001', …, 'TOY000006' )
```
Les `INSERT` des **lignes** partent « en lot » (`executeBatch`) et ne sont pas écrits dans le log : on les vérifie dans la base (C.6).

**Ordre important :** la mère est insérée **avant** ses lignes, car `TOYDETAIL.idtoy` a une clé étrangère vers `TOY.id` : la vente doit exister avant ses lignes.

### C.6 Ce qui est écrit en base (lu après le paiement)

```
TOY         TOY000006 | CLI000002 | POP000008 | total=7000 | etat=11
TOYDETAIL   TOD000009 | TOY000006 | JOT000013 | prix=5000
            TOD000010 | TOY000006 | JOT000015 | prix=2000
HISTORIQUE  EX0000000072 | toy.Toy | Insertion par 990001 | TOY000006
            EX00000074   |         | Insertion par 990001 | TOD000009
            EX00000076   |         | Insertion par 990001 | TOD000010
```
Pour le vérifier toi-même :
```sql
SELECT * FROM toy ORDER BY id;
SELECT * FROM toydetail ORDER BY id;
SELECT idhistorique, objet, action, refobjet FROM historique WHERE refobjet LIKE 'TO%' ORDER BY idhistorique;
```

**Ce qui change pour les écrans :** Mini Groot et Yoyo sont maintenant dans une vente non annulée (`etat = 11`). `listerJouetsDisponibles` ne les propose plus : après ce paiement, la saisie du Grand caramel n'affiche plus que **Figurine Dune** et **Toupie** (testé).

### C.7 Et si une règle refuse ?

```
throw new Exception("Le jouet Mini Groot est déjà vendu.")      ← dans Toy.createObject
   ▼
creerToy : catch → c.rollback() → throw e                         ← rien n'est gardé en base
   ▼
popcorn-paiement.jsp : catch → <script>alert('…'); history.back();</script>
   ▼
le navigateur affiche le message, puis revient au récapitulatif
```
Testé :
| Cas | Message | En base |
|---|---|---|
| montant reçu 500 pour 2 000 | « Montant reçu insuffisant : il manque 1 500 Ar. » | rien (refusé **avant** `creerToy`) |
| repayer Mini Groot + Yoyo déjà vendus | « Le jouet Mini Groot est déjà vendu. » | rien (`rollback`) |

Seule trace d'un refus : un numéro de séquence peut avoir été consommé. C'est un « trou » normal ([creer_une_sequence.md](../apprentissageAPJ/creer_une_sequence.md) §7).

---

## D. La redirection vers la fiche

### D.1 Comment on passe à l'autre page

Après le `commit`, `popcorn-paiement.jsp` n'affiche **pas** de page. Elle renvoie seulement ce script :
```html
<script>
    document.location.replace("module.jsp?but=popcorn/popcorn-fiche.jsp&id=TOY000006&recu=10000.0");
</script>
```
puis s'arrête (`return;`). Le navigateur exécute le script et **demande la fiche** (GET).

**Pourquoi `replace`, et pas un simple lien ?** `replace` remplace la page de paiement **dans l'historique** du navigateur. Si l'utilisateur appuie sur « Précédent » ou rafraîchit, il ne renvoie **pas** le POST « Payer », donc pas de seconde vente. C'est la même technique qu'`apresMultiple.jsp` dans akoho.

**Pourquoi pas `response.sendRedirect(...)` ?** La page est incluse dans `module.jsp`, qui a déjà commencé à écrire l'en-tête : il est trop tard pour une redirection HTTP. Le script est la solution du socle.

### D.2 La fiche

```java
String id = request.getParameter("id");                    // "TOY000006"
ToyLib vente = ToyService.chargerToy(id, null);            // vue TOY_LIB : client et paquet en clair
ToyDetailLib[] lignes = ToyService.listerLignes(id, null); // vue TOYDETAIL_LIB : jouet, type, PRIX PAYÉ
Double recu = Double.valueOf(request.getParameter("recu")); // 10000 → monnaie = 10000 - 7000
```
Affichage réel :
```
Vente TOY000006
Paiement enregistré. Reçu : 10 000 Ar — monnaie à rendre : 3 000 Ar.
Client Rakoto Jean        Paquet de popcorn Grand caramel
Mini Groot  Collector  5 000
Yoyo        Classique  2 000
Total payé             7 000            [Nouvelle vente]
```
- **Le prix affiché est le prix payé** (`TOYDETAIL.prix`, recopié au paiement), pas le prix actuel du type : si le Collector passe à 8 000 demain, cette fiche affichera toujours 5 000.
- **`recu` n'est pas enregistré** : il ne sert qu'à afficher la monnaie juste après le paiement. Une fiche ouverte plus tard, sans `recu`, n'affiche pas ce bandeau.

---

## E. Les protections, récapitulées

| Risque | Protection | Où |
|---|---|---|
| client ou paquet vide | `required` (navigateur) + contrôle serveur | saisie, paiement |
| montant trop petit | `min` (navigateur) + `recu < total` (serveur) | paiement |
| prix ou total trafiqué dans la page | le total et les prix sont **recalculés en base** | `calculerMontant`, `Toy.createObject` |
| jouet d'un autre paquet | contrôle dans `createObject` | `Toy.createObject` ④ |
| jouet déjà vendu | `estVendu` + `listerJouetsDisponibles` | `Toy.createObject` ④, saisie |
| deux ventes du même jouet au même instant | verrou `for update` sur le paquet | `Toy.createObject` ① |
| double clic / rafraîchissement après « Payer » | `document.location.replace` ; et un 2ᵉ envoi est refusé (« déjà vendu ») | paiement |
| erreur au milieu de l'enregistrement | transaction : `rollback` | `creerToy` |

## F. Les fichiers

| Fichier | Rôle dans ce parcours |
|---|---|
| [popcorn-saisie.jsp](../../cinema-war/web/pages/popcorn/popcorn-saisie.jsp) | A : le bouton « Continuer » (`formaction`) |
| [popcorn-paiement.jsp](../../cinema-war/web/pages/popcorn/popcorn-paiement.jsp) | **nouveau** — B : récapitulatif ; C : « Payer » ; D : redirection |
| [popcorn-fiche.jsp](../../cinema-war/web/pages/popcorn/popcorn-fiche.jsp) | **nouveau** — D : la fiche de la vente (détail : [07_popcorn_fiche.md](07_popcorn_fiche.md)) |
| [ToyService.java](../../cinema-ejb/src/java/toy/ToyService.java) | `calculerMontant`, `chargerElements`, `creerToy` ; **nouveaux** : `chargerToy`, `listerLignes` |
| [Toy.java](../../cinema-ejb/src/java/toy/Toy.java) | `createObject` : toutes les règles ; `estVendu` |
| [ToyLib.java](../../cinema-ejb/src/java/toy/ToyLib.java), [ToyDetailLib.java](../../cinema-ejb/src/java/toy/ToyDetailLib.java) | **nouveaux** : lisent les vues de la fiche |
| [01_tables_metier.sql](../../database/01_tables_metier.sql) | **nouvelles** vues `TOY_LIB`, `TOYDETAIL_LIB` (créées aussi en base) |

## G. Rejouer les tests

### Dans le navigateur
| # | Action | Attendu |
|---|---|---|
| 1 | saisie : Rakoto Jean, Grand caramel, cocher 2 jouets, « Continuer » | récapitulatif avec les 2 jouets et le bon total |
| 2 | « Modifier » | retour à la saisie, mêmes choix cochés |
| 3 | montant reçu < total, « Payer » | le navigateur refuse (`min`) |
| 4 | montant reçu ≥ total, « Payer » | fiche `TOY…` avec la monnaie à rendre |
| 5 | « Précédent » du navigateur après la fiche | **pas** de seconde vente |
| 6 | nouvelle saisie du même paquet | les jouets vendus n'apparaissent plus |

### Avec `curl` (contourne `min`, pour tester le contrôle serveur)
```bash
B=http://localhost:8080/cinema; J=/tmp/ck.txt; M="$B/pages/module.jsp?but=popcorn/popcorn-paiement.jsp"
curl -s -c $J -b $J $B/ -o /dev/null
curl -s -c $J -b $J -X POST $B/pages/testLogin.jsp --data "identifiant=cinema&passe=cinema" -o /dev/null
CHOIX="idclient=CLI000002&idpopcorn=POP000008&idjouet=JOT000014"          # Toupie (2 000) : adapter les ids
curl -s -b $J -X POST "$M" --data "$CHOIX" | grep -o 'Total.\{0,80\}'                                # récapitulatif
curl -s -b $J -X POST "$M" --data "acte=payer&$CHOIX&montantrecu=500" | grep -o "alert('[^']*'); history.back"   # insuffisant
curl -s -b $J -X POST "$M" --data "acte=payer&$CHOIX&montantrecu=5000" | grep -o 'document.location.replace("[^"]*")'  # ⚠ VRAIE vente
curl -s -b $J -X POST "$M" --data "acte=payer&$CHOIX&montantrecu=5000" | grep -o "alert('[^']*'); history.back"   # déjà vendu
```

### Suivre les requêtes SQL d'un clic
```bash
LOG=/home/balou/S5/MrTahina/akoho.zip/wildfly-10.1.0.Final/standalone/log/server.log
N=$(wc -l < $LOG)          # avant le clic
# … cliquer dans le navigateur …
sed -n "$((N+1)),\$p" $LOG | grep -oE "Requete [^:]*: .*"
```

### Résultats du 12/11/2026
| Test | Résultat |
|---|---|
| A : Continuer avec Mini Groot + Yoyo | récapitulatif : Rakoto Jean, Grand caramel, 5 000 + 2 000 = 7 000 |
| C : payer 500 pour 2 000 | « Montant reçu insuffisant : il manque 1 500 Ar. » ; 0 vente en base |
| C : payer 10 000 pour 7 000 | `TOY000006` créée ; 2 lignes `TOD000009`, `TOD000010` ; 3 lignes d'historique |
| D : fiche | « monnaie à rendre : 3 000 Ar », prix payés 5 000 et 2 000 |
| repayer le même choix | « Le jouet Mini Groot est déjà vendu. » |
| saisie après la vente | Grand caramel : seulement Figurine Dune et Toupie |

⚠ La vente **`TOY000006` est restée en base** : c'est une donnée de démonstration. Mini Groot et Yoyo du Grand caramel sont donc vendus.

## H. Si ça ne marche pas

| Symptôme | Cause probable | Où regarder |
|---|---|---|
| « Cochez au moins un jouet » en arrivant au paiement | aucune case cochée, ou cases sans `name="idjouet"` | la saisie |
| alerte « … introuvable » | un id du choix n'existe pas (données supprimées, id modifié à la main) | `SELECT * FROM jouet_lib` |
| page blanche après « Payer » | exception non affichée | `server.log` : `Exception`, `ORA-` |
| `ORA-01722` | `u` n'est pas numérique (HISTORIQUE) | `u.getUser().getTuppleID()` |
| la vente est créée mais la fiche plante | vues `TOY_LIB` / `TOYDETAIL_LIB` absentes | relancer leur `CREATE OR REPLACE VIEW` |
| un jouet vendu réapparaît | la vente a `etat = 0` (annulée) | `SELECT id, etat FROM toy` |
