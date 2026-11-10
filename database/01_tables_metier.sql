-- Active: 1794266528165@@@443@EE@CINEMA
-- ============================================================
-- Cinema : tables metier du scenario 1 (reservation)
-- A executer dans le compte Oracle CINEMA (sqlplus cinema/cinema).
-- Ordre : d'abord les tables referencees, puis celles qui les referencent.
-- Rappel APJ : preparePk attend une FONCTION (GETSEQxxx), pas une sequence.
-- ============================================================

-- ---------- Tables ----------

CREATE TABLE SALLE (
  id   VARCHAR2(100) PRIMARY KEY,
  nom  VARCHAR2(100) NOT NULL
);

CREATE TABLE TYPEPLACE (
  id       VARCHAR2(100) PRIMARY KEY,
  libelle  VARCHAR2(100) NOT NULL,
  prix     NUMBER(15,2)  NOT NULL CHECK (prix > 0)
);

CREATE TABLE PLACE (
  id           VARCHAR2(100) PRIMARY KEY,
  idsalle      VARCHAR2(100) NOT NULL REFERENCES SALLE(id),
  numero       VARCHAR2(20)  NOT NULL,
  idtypeplace  VARCHAR2(100) NOT NULL REFERENCES TYPEPLACE(id),
  CONSTRAINT uq_place_salle_numero UNIQUE (idsalle, numero)
);

CREATE TABLE FILM (
  id       VARCHAR2(100) PRIMARY KEY,
  titre    VARCHAR2(200) NOT NULL,
  duree    NUMBER(4)     NOT NULL CHECK (duree > 0),
  idsalle  VARCHAR2(100) NOT NULL REFERENCES SALLE(id)
);

CREATE TABLE SEANCE (
  id      VARCHAR2(100) PRIMARY KEY,
  idfilm  VARCHAR2(100) NOT NULL REFERENCES FILM(id),
  daty    DATE          NOT NULL,
  heure   VARCHAR2(5)   NOT NULL
);

CREATE TABLE CLIENT (
  id       VARCHAR2(100) PRIMARY KEY,
  nom      VARCHAR2(200) NOT NULL,
  contact  VARCHAR2(200)
);

CREATE TABLE RESERVATION (
  id            VARCHAR2(100) PRIMARY KEY,
  idclient      VARCHAR2(100) NOT NULL REFERENCES CLIENT(id),
  idseance      VARCHAR2(100) NOT NULL REFERENCES SEANCE(id),
  daty          DATE          NOT NULL,
  montanttotal  NUMBER(15,2)  DEFAULT 0,
  etat          NUMBER        DEFAULT 1
);

CREATE TABLE RESERVATIONDETAIL (
  id             VARCHAR2(100) PRIMARY KEY,
  idreservation  VARCHAR2(100) NOT NULL REFERENCES RESERVATION(id),
  idplace        VARCHAR2(100) NOT NULL REFERENCES PLACE(id),
  prix           NUMBER(15,2)  NOT NULL
);

-- ---------- Sequences + fonctions (une par table) ----------

CREATE SEQUENCE SEQ_SALLE;
CREATE OR REPLACE FUNCTION GETSEQSALLE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_SALLE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_TYPEPLACE;
CREATE OR REPLACE FUNCTION GETSEQTYPEPLACE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_TYPEPLACE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_PLACE;
CREATE OR REPLACE FUNCTION GETSEQPLACE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_PLACE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_FILM;
CREATE OR REPLACE FUNCTION GETSEQFILM RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_FILM.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_SEANCE;
CREATE OR REPLACE FUNCTION GETSEQSEANCE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_SEANCE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_CLIENT;
CREATE OR REPLACE FUNCTION GETSEQCLIENT RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_CLIENT.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_RESERVATION;
CREATE OR REPLACE FUNCTION GETSEQRESERVATION RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_RESERVATION.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_RESERVATIONDETAIL;
CREATE OR REPLACE FUNCTION GETSEQRESERVATIONDETAIL RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_RESERVATIONDETAIL.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

COMMIT;

-- ---------- Vues (lecture pour les ecrans) ----------

-- Une place avec le nom de sa salle, son type et son prix (classe salle.PlaceLib)
CREATE OR REPLACE VIEW PLACE_LIB AS
SELECT p.id, p.idsalle, s.nom AS salle, p.numero,
       p.idtypeplace, t.libelle AS typeplace, t.prix
FROM PLACE p
JOIN SALLE s     ON s.id = p.idsalle
JOIN TYPEPLACE t ON t.id = p.idtypeplace;

-- Une reservation avec le nom du client, le film, la salle et la seance (classe reservation.ReservationLib)
CREATE OR REPLACE VIEW RESERVATION_LIB AS
SELECT r.id, r.idclient, c.nom AS client,
       r.idseance, se.daty AS dateseance, se.heure,
       f.id AS idfilm, f.titre AS film, sa.nom AS salle,
       r.daty, r.montanttotal, r.etat
FROM RESERVATION r
JOIN CLIENT c  ON c.id  = r.idclient
JOIN SEANCE se ON se.id = r.idseance
JOIN FILM f    ON f.id  = se.idfilm
JOIN SALLE sa  ON sa.id = f.idsalle;

-- Une place reservee avec son numero et son type ; prix = prix paye (classe reservation.ReservationDetailLib)
CREATE OR REPLACE VIEW RESERVATIONDETAIL_LIB AS
SELECT d.id, d.idreservation, d.idplace, p.numero, t.libelle AS typeplace, d.prix
FROM RESERVATIONDETAIL d
JOIN PLACE p     ON p.id = d.idplace
JOIN TYPEPLACE t ON t.id = p.idtypeplace;
