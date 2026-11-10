-- ============================================================
-- Cinema : tables du SOCLE APJ (connexion, menu, historique)
-- A executer dans le compte Oracle CINEMA, AVANT 01_tables_metier.sql.
--
-- Les tables sont recopiees depuis le schema ARBIOCHEMSTANDARD (meme instance Oracle).
-- On ne garde que ce dont ont besoin la connexion (testLogin.jsp), module.jsp,
-- l'en-tete, le menu et l'historique d'APJ. Voir docs/etape1/00_vue_ensemble.md.
-- ============================================================

-- ---------- 1. Copiees AVEC leurs donnees (referentiels) ----------

-- Les comptes et le parametre de chiffrage de leur mot de passe
CREATE TABLE UTILISATEUR   AS SELECT * FROM ARBIOCHEMSTANDARD.UTILISATEUR;
CREATE TABLE PARAMCRYPT    AS SELECT * FROM ARBIOCHEMSTANDARD.PARAMCRYPT;
CREATE TABLE ROLES         AS SELECT * FROM ARBIOCHEMSTANDARD.ROLES;
CREATE TABLE DIRECTION     AS SELECT * FROM ARBIOCHEMSTANDARD.DIRECTION;
CREATE TABLE CNAPS_USER    AS SELECT * FROM ARBIOCHEMSTANDARD.CNAPS_USER;
-- Parametres generaux d'APJ (pagination...) et la societe (logo, favicon)
CREATE TABLE CONFIGURATION AS SELECT * FROM ARBIOCHEMSTANDARD.CONFIGURATION;
CREATE TABLE MASOCIETE     AS SELECT * FROM ARBIOCHEMSTANDARD.MASOCIETE;

-- ---------- 2. Copiees VIDES (seulement la structure) ----------

CREATE TABLE ANNULATIONUTILISATEUR AS SELECT * FROM ARBIOCHEMSTANDARD.ANNULATIONUTILISATEUR WHERE 1 = 0;
CREATE TABLE ACTIONROLE            AS SELECT * FROM ARBIOCHEMSTANDARD.ACTIONROLE WHERE 1 = 0;
-- APJ ecrit une ligne d'historique a chaque insertion / modification
CREATE TABLE HISTORIQUE            AS SELECT * FROM ARBIOCHEMSTANDARD.HISTORIQUE WHERE 1 = 0;
-- Le menu : les entrees (MENUDYNAMIQUE) et qui a le droit de les voir (USERMENU)
CREATE TABLE MENUDYNAMIQUE         AS SELECT * FROM ARBIOCHEMSTANDARD.MENUDYNAMIQUE WHERE 1 = 0;
CREATE TABLE USERMENU              AS SELECT * FROM ARBIOCHEMSTANDARD.USERMENU WHERE 1 = 0;
-- La page d'accueil de chaque role (affichee juste apres la connexion)
CREATE TABLE USERHOMEPAGE          AS SELECT * FROM ARBIOCHEMSTANDARD.USERHOMEPAGE WHERE 1 = 0;

ALTER TABLE MENUDYNAMIQUE ADD CONSTRAINT pk_menudynamique PRIMARY KEY (id);
ALTER TABLE USERMENU      ADD CONSTRAINT pk_usermenu      PRIMARY KEY (id);
ALTER TABLE HISTORIQUE    ADD CONSTRAINT pk_historique    PRIMARY KEY (idhistorique);

-- ---------- 3. Vues lues par APJ ----------

-- APJ lit la liste des colonnes de chaque table ici (ListeColonneTable.getFromListe),
-- pour construire ses requetes. SANS ELLE, AUCUNE RECHERCHE NE MARCHE (ORA-00942).
CREATE OR REPLACE VIEW LISTECOLONNETABLE AS
SELECT 'a' AS owner, ua.TABLE_NAME, ua.COLUMN_NAME, ua.DATA_TYPE, ua.DATA_TYPE_MOD, ua.DATA_TYPE_OWNER,
       ua.DATA_LENGTH, ua.DATA_PRECISION, ua.DATA_SCALE, ua.NULLABLE, ua.COLUMN_ID, ua.DEFAULT_LENGTH,
       ua.DATA_DEFAULT, ua.NUM_DISTINCT, ua.LOW_VALUE, ua.HIGH_VALUE, ua.DENSITY, ua.NUM_NULLS,
       ua.NUM_BUCKETS, ua.LAST_ANALYZED, ua.SAMPLE_SIZE, ua.CHARACTER_SET_NAME, ua.CHAR_COL_DECL_LENGTH,
       ua.GLOBAL_STATS, ua.USER_STATS, ua.AVG_COL_LEN, ua.CHAR_LENGTH, ua.CHAR_USED, ua.V80_FMT_IMAGE,
       ua.DATA_UPGRADED, ua.HISTOGRAM
FROM USER_TAB_COLUMNS ua
UNION ALL
SELECT tc.OWNER, syn.SYNONYM_NAME AS table_name, tc.COLUMN_NAME, tc.DATA_TYPE, tc.DATA_TYPE_MOD,
       tc.DATA_TYPE_OWNER, tc.DATA_LENGTH, tc.DATA_PRECISION, tc.DATA_SCALE, tc.NULLABLE, tc.COLUMN_ID,
       tc.DEFAULT_LENGTH, tc.DATA_DEFAULT, tc.NUM_DISTINCT, tc.LOW_VALUE, tc.HIGH_VALUE, tc.DENSITY,
       tc.NUM_NULLS, tc.NUM_BUCKETS, tc.LAST_ANALYZED, tc.SAMPLE_SIZE, tc.CHARACTER_SET_NAME,
       tc.CHAR_COL_DECL_LENGTH, tc.GLOBAL_STATS, tc.USER_STATS, tc.AVG_COL_LEN, tc.CHAR_LENGTH,
       tc.CHAR_USED, tc.V80_FMT_IMAGE, tc.DATA_UPGRADED, tc.HISTOGRAM
FROM ALL_TAB_COLUMNS tc
JOIN USER_SYNONYMS syn ON syn.TABLE_NAME = tc.TABLE_NAME AND syn.TABLE_OWNER = tc.OWNER;

-- Lues a la connexion

CREATE OR REPLACE VIEW UTILISATEURVALIDE AS
SELECT u.REFUSER, u.LOGINUSER, u.PWDUSER, u.NOMUSER, u.ADRUSER, u.TELUSER, u.IDROLE, r.RANG
FROM utilisateur u, ROLES r, annulationutilisateur a
WHERE u.IDROLE = r.IDROLE
  AND u.refuser = a.REFUSER(+) AND a.REFUSER IS NULL;

CREATE OR REPLACE VIEW UTILISATEURVUE AS
SELECT u.refuser, u.LOGINUSER, u.PWDUSER, u.NOMUSER, d.LIBELLEDIR AS adruser,
       u.TELUSER, u.IDROLE, r.RANG
FROM utilisateur u
JOIN direction d ON u.ADRUSER = d.IDDIR
LEFT JOIN roles r ON r.IDROLE = u.IDROLE;

-- ---------- 4. Sequence de l'historique ----------

CREATE SEQUENCE SEQHISTORIQUE;
CREATE OR REPLACE FUNCTION GETSEQHISTORIQUE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQHISTORIQUE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

-- ---------- 5. Le compte du cinema ----------
-- Identifiant : cinema / mot de passe : cinema  (role dsi, direction DIR42)
-- Le mot de passe est stocke chiffre : Utilitaire.cryptWord("cinema", 4, 1) = '8ejai6'
-- (niveau 4, croissante 1, comme dans PARAMCRYPT).
-- Les comptes recopies du socle (dont "admin") marchent aussi, avec leurs mots de passe habituels.

INSERT INTO UTILISATEUR (refuser, loginuser, pwduser, nomuser, adruser, teluser, idrole)
VALUES (990001, 'cinema', '8ejai6', 'Gestionnaire cinema', 'DIR42', NULL, 'dsi');
INSERT INTO PARAMCRYPT (id, niveau, croissante, idutilisateur)
VALUES ('CRYCINEMA1', 4, 1, '990001');

-- ---------- 6. Le menu du cinema ----------
-- niveau 1 = rubrique (id_pere NULL), niveau 2 = page. USERMENU refuser='*' : visible par tous.

INSERT INTO MENUDYNAMIQUE (id, libelle, icone, href, rang, niveau, id_pere)
VALUES ('MENCINEMA', UNISTR('Cin\00E9ma'), 'theaters', '#', 1, 1, NULL);
INSERT INTO MENUDYNAMIQUE (id, libelle, icone, href, rang, niveau, id_pere)
VALUES ('MENCINEMARESA', UNISTR('R\00E9server'), 'event_seat',
        'module.jsp?but=reservation/reservation-saisie.jsp', 1, 2, 'MENCINEMA');

INSERT INTO USERMENU (id, refuser, idmenu, idrole, codeservice, codedir, interdit)
VALUES ('USMCINEMA', '*', 'MENCINEMA', NULL, NULL, NULL, 0);
INSERT INTO USERMENU (id, refuser, idmenu, idrole, codeservice, codedir, interdit)
VALUES ('USMCINEMARESA', '*', 'MENCINEMARESA', NULL, NULL, NULL, 0);

-- ---------- 7. La page d'accueil : l'ecran de reservation ----------
-- dsi = role du compte cinema, dg = role du compte admin recopie du socle.
-- Les autres roles arrivent sur accueil.jsp (valeur par defaut de UserEJBBean).

INSERT INTO USERHOMEPAGE (id, codeservice, urlpage, idrole, codedir)
VALUES ('UHPCINEMA1', NULL, 'reservation/reservation-saisie.jsp', 'dsi', NULL);
INSERT INTO USERHOMEPAGE (id, codeservice, urlpage, idrole, codedir)
VALUES ('UHPCINEMA2', NULL, 'reservation/reservation-saisie.jsp', 'dg', NULL);

COMMIT;
