-- ============================================================
-- Cinema : jeu de donnees de test (apres 00_socle.sql et 01_tables_metier.sql)
-- Les ids passent par les fonctions GETSEQxxx, pour que les prochaines
-- insertions faites par APJ ne reprennent pas les memes numeros.
-- Les seances sont datees a partir d'aujourd'hui (trunc(sysdate) + n) : elles restent a venir.
-- ============================================================

DECLARE
    v_standard VARCHAR2(100) := 'TPL' || LPAD(GETSEQTYPEPLACE, 6, '0');
    v_vip      VARCHAR2(100) := 'TPL' || LPAD(GETSEQTYPEPLACE, 6, '0');
    v_salle1   VARCHAR2(100) := 'SAL' || LPAD(GETSEQSALLE, 6, '0');
    v_salle2   VARCHAR2(100) := 'SAL' || LPAD(GETSEQSALLE, 6, '0');
    v_dune     VARCHAR2(100) := 'FLM' || LPAD(GETSEQFILM, 6, '0');
    v_coco     VARCHAR2(100) := 'FLM' || LPAD(GETSEQFILM, 6, '0');
    v_tsara    VARCHAR2(100) := 'FLM' || LPAD(GETSEQFILM, 6, '0');
    v_rangees  VARCHAR2(10)  := 'ABCDE';

    PROCEDURE seance(p_film VARCHAR2, p_jours NUMBER, p_heure VARCHAR2) IS
    BEGIN
        INSERT INTO SEANCE (id, idfilm, daty, heure)
        VALUES ('SEA' || LPAD(GETSEQSEANCE, 6, '0'), p_film, TRUNC(SYSDATE) + p_jours, p_heure);
    END;
BEGIN
    -- Types de place
    INSERT INTO TYPEPLACE (id, libelle, prix) VALUES (v_standard, 'Standard', 15000);
    INSERT INTO TYPEPLACE (id, libelle, prix) VALUES (v_vip, 'VIP', 25000);

    -- Salles
    INSERT INTO SALLE (id, nom) VALUES (v_salle1, 'Salle 1');
    INSERT INTO SALLE (id, nom) VALUES (v_salle2, 'Salle 2');

    -- Salle 1 : rangees A a E, 8 places chacune ; la rangee E est VIP (40 places)
    FOR r IN 1 .. 5 LOOP
        FOR n IN 1 .. 8 LOOP
            INSERT INTO PLACE (id, idsalle, numero, idtypeplace)
            VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), v_salle1, SUBSTR(v_rangees, r, 1) || n,
                    CASE WHEN r = 5 THEN v_vip ELSE v_standard END);
        END LOOP;
    END LOOP;
    -- Salle 2 : rangees A a C, 6 places ; la rangee C est VIP (18 places)
    FOR r IN 1 .. 3 LOOP
        FOR n IN 1 .. 6 LOOP
            INSERT INTO PLACE (id, idsalle, numero, idtypeplace)
            VALUES ('PLC' || LPAD(GETSEQPLACE, 6, '0'), v_salle2, SUBSTR(v_rangees, r, 1) || n,
                    CASE WHEN r = 3 THEN v_vip ELSE v_standard END);
        END LOOP;
    END LOOP;

    -- Films (un film passe toujours dans la meme salle)
    INSERT INTO FILM (id, titre, duree, idsalle) VALUES (v_dune,  'Dune 3', 166, v_salle1);
    INSERT INTO FILM (id, titre, duree, idsalle) VALUES (v_coco,  'Coco', 105, v_salle1);
    INSERT INTO FILM (id, titre, duree, idsalle) VALUES (v_tsara, 'Tsara ny fiainana', 95, v_salle2);

    -- Seances (sans chevauchement dans une meme salle)
    seance(v_coco,  1, '14:00');   -- Salle 1, demain 14:00 -> 15:45
    seance(v_dune,  1, '18:00');   -- Salle 1, demain 18:00 -> 20:46
    seance(v_dune,  2, '18:00');   -- Salle 1, apres-demain
    seance(v_coco,  2, '21:30');
    seance(v_tsara, 1, '16:00');   -- Salle 2
    seance(v_tsara, 3, '19:00');

    -- Clients
    INSERT INTO CLIENT (id, nom, contact) VALUES ('CLI' || LPAD(GETSEQCLIENT, 6, '0'), 'Rakoto Jean', '034 11 222 33');
    INSERT INTO CLIENT (id, nom, contact) VALUES ('CLI' || LPAD(GETSEQCLIENT, 6, '0'), 'Rasoa Marie', '032 44 555 66');
    INSERT INTO CLIENT (id, nom, contact) VALUES ('CLI' || LPAD(GETSEQCLIENT, 6, '0'), 'Randria Paul', '033 77 888 99');

    COMMIT;
END;
/
