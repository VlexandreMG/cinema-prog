-- ============================================================
-- Cinema : VIDER toutes les donnees METIER (pour repartir d'une base propre)
-- A executer dans le compte Oracle CINEMA, puis charger les donnees de test.
--
-- ATTENTION : IRREVERSIBLE apres le COMMIT final. Pour essayer sans rien perdre :
-- executer tout SAUF la ligne COMMIT, regarder les comptages, puis taper ROLLBACK.
--
-- CE QUI EST VIDE (donnees metier) :
--   reservations, factures, mouvements de caisse, achats, ventes de popcorn,
--   et tout le catalogue : clients, films, seances, salles, places, types de place,
--   paquets de popcorn, jouets, types de jouet, distributeurs.
--
-- CE QUI EST GARDE :
--   - le SOCLE (UTILISATEUR, PARAMCRYPT, ROLES, MENUDYNAMIQUE, USERMENU, CONFIGURATION,
--     MASOCIETE, HISTORIQUE...) : sinon plus de connexion ni de menu ;
--   - UNE ligne de CAISSE « Guichet principal » (la plus ancienne) : CaisseService.caissePrincipale
--     en a besoin pour chaque paiement. Ses mouvements sont effaces : son solde repart a 0.
--     Les caisses en DOUBLE (meme nom, creees en relancant 01_tables_metier.sql) sont supprimees ;
--   - les SEQUENCES : elles ne reviennent pas a 1, les prochains ids continuent.
--     C'est normal : un id doit etre unique, pas forcement continu.
--
-- COMPTEURFACTURE est remis a 0 : la prochaine facture sera 0001.
--
-- L'ORDRE COMPTE : on efface les tables ENFANTS (qui pointent vers une autre par une
-- cle etrangere) AVANT leurs PARENTS, sinon Oracle refuse (ORA-02292).
--
-- Dans SQL*Plus, un commentaire doit etre SUR SA PROPRE LIGNE : « DELETE ...; -- texte »
-- empeche le ; d'etre vu, et l'instruction n'est pas executee (piege 4.10 de la fiche APJ).
-- ============================================================

-- ---------- 1. L'argent et les documents (les « feuilles » de l'arbre) ----------
-- MOUVEMENTCAISSE -> CAISSE (gardee)
DELETE FROM MOUVEMENTCAISSE;
-- ACHAT -> FILM, DISTRIBUTEUR
DELETE FROM ACHAT;
-- FACTUREDETAIL -> FACTURE
DELETE FROM FACTUREDETAIL;
-- FACTURE -> RESERVATION, CLIENT
DELETE FROM FACTURE;
-- RESERVATIONDETAIL -> RESERVATION, PLACE
DELETE FROM RESERVATIONDETAIL;
-- RESERVATION -> SEANCE, CLIENT
DELETE FROM RESERVATION;
-- TOYDETAIL -> TOY, JOUET
DELETE FROM TOYDETAIL;
-- TOY -> POPCORN, CLIENT
DELETE FROM TOY;

-- ---------- 2. Le catalogue du popcorn ----------
-- JOUET -> POPCORN, TYPEJOUET
DELETE FROM JOUET;
DELETE FROM POPCORN;
DELETE FROM TYPEJOUET;

-- ---------- 3. Le catalogue du cinema ----------
-- SEANCE -> FILM
DELETE FROM SEANCE;
-- FILM -> SALLE
DELETE FROM FILM;
-- PLACE -> SALLE, TYPEPLACE
DELETE FROM PLACE;
DELETE FROM SALLE;
DELETE FROM TYPEPLACE;
DELETE FROM CLIENT;
DELETE FROM DISTRIBUTEUR;

-- ---------- 4. Une seule caisse, et le compteur de factures a zero ----------
-- Supprime les caisses en double : on garde la plus ancienne (le plus petit id)
DELETE FROM CAISSE WHERE id <> (SELECT MIN(id) FROM CAISSE);
UPDATE COMPTEURFACTURE SET dernier = 0 WHERE id = 1;

-- ---------- 5. Verification : tout doit valoir 0, sauf CAISSE = 1 ----------
SELECT 'MOUVEMENTCAISSE' AS table_, COUNT(*) AS lignes FROM MOUVEMENTCAISSE
UNION ALL SELECT 'ACHAT', COUNT(*) FROM ACHAT
UNION ALL SELECT 'FACTURE', COUNT(*) FROM FACTURE
UNION ALL SELECT 'FACTUREDETAIL', COUNT(*) FROM FACTUREDETAIL
UNION ALL SELECT 'RESERVATION', COUNT(*) FROM RESERVATION
UNION ALL SELECT 'RESERVATIONDETAIL', COUNT(*) FROM RESERVATIONDETAIL
UNION ALL SELECT 'TOY', COUNT(*) FROM TOY
UNION ALL SELECT 'TOYDETAIL', COUNT(*) FROM TOYDETAIL
UNION ALL SELECT 'JOUET', COUNT(*) FROM JOUET
UNION ALL SELECT 'POPCORN', COUNT(*) FROM POPCORN
UNION ALL SELECT 'TYPEJOUET', COUNT(*) FROM TYPEJOUET
UNION ALL SELECT 'SEANCE', COUNT(*) FROM SEANCE
UNION ALL SELECT 'FILM', COUNT(*) FROM FILM
UNION ALL SELECT 'PLACE', COUNT(*) FROM PLACE
UNION ALL SELECT 'SALLE', COUNT(*) FROM SALLE
UNION ALL SELECT 'TYPEPLACE', COUNT(*) FROM TYPEPLACE
UNION ALL SELECT 'CLIENT', COUNT(*) FROM CLIENT
UNION ALL SELECT 'DISTRIBUTEUR', COUNT(*) FROM DISTRIBUTEUR
UNION ALL SELECT 'CAISSE (gardee)', COUNT(*) FROM CAISSE
UNION ALL SELECT 'COMPTEURFACTURE dernier', dernier FROM COMPTEURFACTURE;

COMMIT;
