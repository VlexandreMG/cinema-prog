-- ============================================================
-- Cinema : les remises entre types de place (table REMISE)
-- A executer apres 06_places.sql (les types de place doivent exister,
-- avec ces libelles exacts : Standard, Confort, VIP).
--
-- Une ligne = « si une reservation contient EXACTEMENT <nombre> places du type <catres>,
--              le prix du type <catrem> baisse de <valeur> % dans TYPEPLACE ».
--   catres : le type de place RESERVE  (id de TYPEPLACE)
--   catrem : le type de place REMISE   (id de TYPEPLACE)
--   valeur : un POURCENTAGE (20 = -20 %)
--
-- Les types sont retrouves PAR LEUR LIBELLE, jamais par un id ecrit en dur.
-- Les valeurs ci-dessous sont des EXEMPLES : a adapter au sujet.
-- Commentaires sur leur propre ligne (piege SQL*Plus).
-- ============================================================

-- 2 places Standard reservees : -20 % sur le Confort
INSERT INTO REMISE (id, nombre, valeur, catres, catrem) VALUES ('REM' || LPAD(GETSEQREMISE, 6, '0'), 2, 20, (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'), (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));

-- 3 places Standard reservees : -10 % sur le VIP
INSERT INTO REMISE (id, nombre, valeur, catres, catrem) VALUES ('REM' || LPAD(GETSEQREMISE, 6, '0'), 3, 10, (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'), (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));

-- 2 places Confort reservees : -15 % sur le VIP
INSERT INTO REMISE (id, nombre, valeur, catres, catrem) VALUES ('REM' || LPAD(GETSEQREMISE, 6, '0'), 2, 15, (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'), (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));

COMMIT;

-- Verification : chaque remise avec le libelle de ses deux types
-- SELECT r.id, r.nombre, rs.libelle AS reserve, r.valeur || ' %' AS remise, rm.libelle AS remise_sur
-- FROM REMISE r JOIN TYPEPLACE rs ON rs.id = r.catres JOIN TYPEPLACE rm ON rm.id = r.catrem;
