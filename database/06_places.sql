-- ============================================================
-- Cinema : les places des salles A, B et C (plan de salle)
-- A executer UNE SEULE FOIS, apres 05_programme_novembre.sql (les salles doivent exister).
-- Les types de place doivent deja exister, avec ces libelles exacts :
--   Standard 15 000 (rangees A et B), Confort 20 000 (rangee C), VIP 30 000 (rangee D).
--
-- Chaque salle : 4 rangees de 5 places = 20 places ; 60 places en tout.
-- Les cles etrangeres retrouvent leur parent PAR SON NOM :
--   (SELECT id FROM SALLE WHERE nom = 'Salle A') et (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard').
-- Commentaires sur leur propre ligne (piege SQL*Plus).
-- ============================================================

-- ---------- Salle A : A-B Standard, C Confort, D VIP ----------
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'A1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'A2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'A3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'A4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'A5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'B1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'B2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'B3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'B4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'B5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'C1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'C2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'C3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'C4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'C5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'D1', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'D2', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'D3', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'D4', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle A'), 'D5', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));

-- ---------- Salle B : A-B Standard, C Confort, D VIP ----------
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'A1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'A2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'A3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'A4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'A5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'B1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'B2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'B3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'B4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'B5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'C1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'C2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'C3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'C4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'C5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'D1', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'D2', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'D3', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'D4', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle B'), 'D5', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));

-- ---------- Salle C : A-B Standard, C Confort, D VIP ----------
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'A1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'A2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'A3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'A4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'A5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'B1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'B2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'B3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'B4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'B5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Standard'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'C1', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'C2', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'C3', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'C4', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'C5', (SELECT id FROM TYPEPLACE WHERE libelle = 'Confort'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'D1', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'D2', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'D3', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'D4', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));
INSERT INTO PLACE (id, idsalle, numero, idtypeplace) VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), (SELECT id FROM SALLE WHERE nom = 'Salle C'), 'D5', (SELECT id FROM TYPEPLACE WHERE libelle = 'VIP'));

COMMIT;

-- ---------- Verification : 20 places par salle (10 Standard, 5 Confort, 5 VIP) ----------
SELECT s.nom AS salle, t.libelle AS type, t.prix, COUNT(*) AS places
FROM place p JOIN salle s ON s.id = p.idsalle JOIN typeplace t ON t.id = p.idtypeplace
GROUP BY s.nom, t.libelle, t.prix ORDER BY s.nom, t.prix;
