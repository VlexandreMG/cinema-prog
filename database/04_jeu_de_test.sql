-- ============================================================
-- Cinema : JEU DE TEST pour suivre le workflow complet
-- Ordre : 99_vider_donnees.sql  PUIS  ce script.
--
-- Ce script ne contient que le CATALOGUE (ce qu'un gestionnaire saisirait une fois).
-- Toutes les OPERATIONS (reservations, factures, caisse, achats, ventes de popcorn)
-- se font PAR L'APPLICATION : c'est ce qu'on veut tester.
--
-- Prix ronds pour calculer de tete :
--   places : Standard 10 000, VIP 20 000      jouets : Classique 1 000, Collector 3 000
-- La caisse part de 0 (videe par 99_vider_donnees.sql).
--
-- Les ids passent par les fonctions GETSEQxxx (comme APJ) : leurs numeros dependent des
-- sequences. Les cles etrangeres retrouvent donc leur parent PAR SON NOM, avec une
-- sous-requete : (SELECT id FROM SALLE WHERE nom = 'Salle 1').
--
-- Les seances sont datees par rapport a AUJOURD'HUI (TRUNC(SYSDATE) + n) :
-- le jeu reste valable quel que soit le jour ou on le charge.
--
-- Chaque commentaire est sur SA PROPRE LIGNE (piege SQL*Plus 4.10).
-- ============================================================

-- ---------- Types de place ----------
INSERT INTO TYPEPLACE (id, libelle, prix) VALUES ('TPL' || LPAD(GETSEQTYPEPLACE, 6, '0'), 'Standard', 10000);
INSERT INTO TYPEPLACE (id, libelle, prix) VALUES ('TPL' || LPAD(GETSEQTYPEPLACE, 6, '0'), 'VIP', 20000);

-- ---------- Salles ----------
INSERT INTO SALLE (id, nom) VALUES ('SAL' || LPAD(GETSEQSALLE, 6, '0'), 'Salle 1');
INSERT INTO SALLE (id, nom) VALUES ('SAL' || LPAD(GETSEQSALLE, 6, '0'), 'Salle 2');

-- ---------- Places de la Salle 1 : 12 places (A et B Standard, C VIP) ----------
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'A1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'A2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'A3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'A4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'B1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'B2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'B3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'B4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'C1', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'C2', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'C3', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 1'), 'C4', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));

-- ---------- Places de la Salle 2 : 8 places (A Standard, B VIP) ----------
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 2'), 'A1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 2'), 'A2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 2'), 'A3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 2'), 'A4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 2'), 'B1', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 2'), 'B2', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 2'), 'B3', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle 2'), 'B4', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));

-- ---------- Films (un film passe toujours dans la meme salle) ----------
INSERT INTO FILM (id, titre, duree, idsalle) VALUES ('FLM' || LPAD(GETSEQFILM, 6, '0'), 'Dune 3', 166, (SELECT id FROM SALLE WHERE nom = 'Salle 1'));
INSERT INTO FILM (id, titre, duree, idsalle) VALUES ('FLM' || LPAD(GETSEQFILM, 6, '0'), 'Coco', 105, (SELECT id FROM SALLE WHERE nom = 'Salle 1'));
INSERT INTO FILM (id, titre, duree, idsalle) VALUES ('FLM' || LPAD(GETSEQFILM, 6, '0'), 'Avatar 3', 190, (SELECT id FROM SALLE WHERE nom = 'Salle 2'));

-- ---------- Seances (a venir ; pas de chevauchement dans une meme salle) ----------
-- Salle 1, demain : Coco 14:00 -> 15:45, puis Dune 3 18:00 -> 20:46
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Coco'), TRUNC(SYSDATE) + 1, '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Dune 3'), TRUNC(SYSDATE) + 1, '18:00');
-- Salle 1, apres-demain : Dune 3 20:00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Dune 3'), TRUNC(SYSDATE) + 2, '20:00');
-- Salle 2, demain : Avatar 3 19:00 -> 22:10
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Avatar 3'), TRUNC(SYSDATE) + 1, '19:00');

-- ---------- Clients ----------
INSERT INTO CLIENT (id, nom, contact) VALUES ('CLI' || LPAD(GETSEQCLIENT, 6, '0'), 'Rakoto Jean', '034 11 222 33');
INSERT INTO CLIENT (id, nom, contact) VALUES ('CLI' || LPAD(GETSEQCLIENT, 6, '0'), 'Rasoa Marie', '032 44 555 66');
INSERT INTO CLIENT (id, nom, contact) VALUES ('CLI' || LPAD(GETSEQCLIENT, 6, '0'), 'Randria Paul', '033 77 888 99');

-- ---------- Popcorn : types de jouet et paquets ----------
INSERT INTO TYPEJOUET (id, lib, prix) VALUES ('TPJ' || LPAD(GETSEQTYPEJOUET, 6, '0'), 'Classique', 1000);
INSERT INTO TYPEJOUET (id, lib, prix) VALUES ('TPJ' || LPAD(GETSEQTYPEJOUET, 6, '0'), 'Collector', 3000);
INSERT INTO POPCORN (id, nom) VALUES ('POP' || LPAD(GETSEQPOP, 6, '0'), 'Grand caramel');
INSERT INTO POPCORN (id, nom) VALUES ('POP' || LPAD(GETSEQPOP, 6, '0'), 'Petit sale');

-- ---------- Popcorn : les jouets ----------
INSERT INTO JOUET (id, lib, idpopcorn, idtypejouet) VALUES ('JOT' || LPAD(GETSEQJOUET, 6, '0'), 'Mini Groot', (SELECT id FROM POPCORN WHERE nom = 'Grand caramel'), (SELECT id FROM TYPEJOUET WHERE lib = 'Collector'));
INSERT INTO JOUET (id, lib, idpopcorn, idtypejouet) VALUES ('JOT' || LPAD(GETSEQJOUET, 6, '0'), 'Figurine Dune', (SELECT id FROM POPCORN WHERE nom = 'Grand caramel'), (SELECT id FROM TYPEJOUET WHERE lib = 'Collector'));
INSERT INTO JOUET (id, lib, idpopcorn, idtypejouet) VALUES ('JOT' || LPAD(GETSEQJOUET, 6, '0'), 'Toupie', (SELECT id FROM POPCORN WHERE nom = 'Grand caramel'), (SELECT id FROM TYPEJOUET WHERE lib = 'Classique'));
INSERT INTO JOUET (id, lib, idpopcorn, idtypejouet) VALUES ('JOT' || LPAD(GETSEQJOUET, 6, '0'), 'Yoyo', (SELECT id FROM POPCORN WHERE nom = 'Grand caramel'), (SELECT id FROM TYPEJOUET WHERE lib = 'Classique'));
INSERT INTO JOUET (id, lib, idpopcorn, idtypejouet) VALUES ('JOT' || LPAD(GETSEQJOUET, 6, '0'), 'Porte-cle Coco', (SELECT id FROM POPCORN WHERE nom = 'Petit sale'), (SELECT id FROM TYPEJOUET WHERE lib = 'Collector'));
INSERT INTO JOUET (id, lib, idpopcorn, idtypejouet) VALUES ('JOT' || LPAD(GETSEQJOUET, 6, '0'), 'Sifflet', (SELECT id FROM POPCORN WHERE nom = 'Petit sale'), (SELECT id FROM TYPEJOUET WHERE lib = 'Classique'));

-- ---------- Distributeurs ----------
INSERT INTO DISTRIBUTEUR (id, nom, contact) VALUES ('DIS' || LPAD(GETSEQDISTRIBUTEUR, 6, '0'), 'Netflix', 'licensing@netflix.example');
INSERT INTO DISTRIBUTEUR (id, nom, contact) VALUES ('DIS' || LPAD(GETSEQDISTRIBUTEUR, 6, '0'), 'Disney', 'droits@disney.example');
INSERT INTO DISTRIBUTEUR (id, nom, contact) VALUES ('DIS' || LPAD(GETSEQDISTRIBUTEUR, 6, '0'), 'Warner', 'cinema@warner.example');

COMMIT;

-- ---------- Verification du chargement ----------
SELECT 'TYPEPLACE (attendu 2)' AS table_, COUNT(*) AS lignes FROM TYPEPLACE
UNION ALL SELECT 'SALLE (attendu 2)', COUNT(*) FROM SALLE
UNION ALL SELECT 'PLACE (attendu 20)', COUNT(*) FROM PLACE
UNION ALL SELECT 'FILM (attendu 3)', COUNT(*) FROM FILM
UNION ALL SELECT 'SEANCE (attendu 4)', COUNT(*) FROM SEANCE
UNION ALL SELECT 'CLIENT (attendu 3)', COUNT(*) FROM CLIENT
UNION ALL SELECT 'TYPEJOUET (attendu 2)', COUNT(*) FROM TYPEJOUET
UNION ALL SELECT 'POPCORN (attendu 2)', COUNT(*) FROM POPCORN
UNION ALL SELECT 'JOUET (attendu 6)', COUNT(*) FROM JOUET
UNION ALL SELECT 'DISTRIBUTEUR (attendu 3)', COUNT(*) FROM DISTRIBUTEUR
UNION ALL SELECT 'CAISSE (attendu 1)', COUNT(*) FROM CAISSE
UNION ALL SELECT 'MOUVEMENTCAISSE (attendu 0)', COUNT(*) FROM MOUVEMENTCAISSE
UNION ALL SELECT 'COMPTEURFACTURE dernier (attendu 0)', dernier FROM COMPTEURFACTURE;
