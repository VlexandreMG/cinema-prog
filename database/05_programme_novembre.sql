-- ============================================================
-- Cinema : programme de diffusion du 16/11/2026 au 30/11/2026
-- A executer dans le compte CINEMA (base videe par 99_vider_donnees.sql).
--
-- Source : le tableau « Programme de diffusion ».
-- Gardes : nom du film, duree, salle, jour, heure.
-- IGNORES (pas encore dans notre base) : realisateur, genre, classification.
--
-- Les JOURS de la semaine sont convertis en DATES du 16 au 30/11/2026 :
--   Lundi 16, 23, 30 | Mardi 17, 24 | Mercredi 18, 25 | Jeudi 19, 26
--   Vendredi 20, 27  | Samedi 21, 28 | Dimanche 22, 29
-- Chaque creneau du tableau est donc repete a CHAQUE date de son jour.
--
-- Les ids passent par les fonctions GETSEQxxx ; les cles etrangeres retrouvent
-- leur parent PAR SON NOM (sous-requete). Commentaires sur leur propre ligne.
-- ============================================================

-- ---------- Salles (une salle par film) ----------
INSERT INTO SALLE (id, nom) VALUES ('SAL' || LPAD(GETSEQSALLE, 6, '0'), 'Salle A');
INSERT INTO SALLE (id, nom) VALUES ('SAL' || LPAD(GETSEQSALLE, 6, '0'), 'Salle B');
INSERT INTO SALLE (id, nom) VALUES ('SAL' || LPAD(GETSEQSALLE, 6, '0'), 'Salle C');

-- ---------- Films (titre, duree en minutes, salle) ----------
INSERT INTO FILM (id, titre, duree, idsalle) VALUES ('FLM' || LPAD(GETSEQFILM, 6, '0'), 'Les Gardiens du Baobab', 115, (SELECT id FROM SALLE WHERE nom = 'Salle A'));
INSERT INTO FILM (id, titre, duree, idsalle) VALUES ('FLM' || LPAD(GETSEQFILM, 6, '0'), 'Nuit sur Analamanga', 105, (SELECT id FROM SALLE WHERE nom = 'Salle B'));
INSERT INTO FILM (id, titre, duree, idsalle) VALUES ('FLM' || LPAD(GETSEQFILM, 6, '0'), 'Le Petit Lémurien', 90, (SELECT id FROM SALLE WHERE nom = 'Salle C'));

-- ---------- Seances : Les Gardiens du Baobab ----------
-- Lundi : 16, 23, 30/11 a 14h00, 20h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-16', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-16', '20:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-23', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-23', '20:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-30', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-30', '20:00');
-- Jeudi : 19, 26/11 a 14h00, 17h00, 20h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-19', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-19', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-19', '20:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-26', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-26', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-26', '20:00');
-- Dimanche : 22, 29/11 a 15h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-22', '15:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Les Gardiens du Baobab'), DATE '2026-11-29', '15:00');

-- ---------- Seances : Nuit sur Analamanga ----------
-- Lundi : 16, 23, 30/11 a 14h00, 17h00, 20h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-16', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-16', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-16', '20:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-23', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-23', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-23', '20:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-30', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-30', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-30', '20:00');
-- Mardi : 17, 24/11 a 18h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-17', '18:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-24', '18:00');
-- Vendredi : 20, 27/11 a 17h00, 20h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-20', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-20', '20:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-27', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Nuit sur Analamanga'), DATE '2026-11-27', '20:00');

-- ---------- Seances : Le Petit Lémurien ----------
-- Mardi : 17, 24/11 a 14h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-17', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-24', '14:00');
-- Mercredi : 18, 25/11 a 14h00, 17h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-18', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-18', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-25', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-25', '17:00');
-- Samedi : 21, 28/11 a 10h00, 14h00, 17h00
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-21', '10:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-21', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-21', '17:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-28', '10:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-28', '14:00');
INSERT INTO SEANCE (id, idfilm, daty, heure) VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), (SELECT id FROM FILM WHERE titre = 'Le Petit Lémurien'), DATE '2026-11-28', '17:00');

COMMIT;

-- ---------- Verification ----------
SELECT f.titre, s.nom AS salle, f.duree, COUNT(se.id) AS seances
FROM film f JOIN salle s ON s.id = f.idsalle LEFT JOIN seance se ON se.idfilm = f.id
GROUP BY f.titre, s.nom, f.duree ORDER BY s.nom;
-- attendu : Les Gardiens du Baobab / Salle A / 115 / 14 ; Nuit sur Analamanga / Salle B / 105 / 15 ; Le Petit Lémurien / Salle C / 90 / 12  (total 41)
