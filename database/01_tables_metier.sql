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

-- Délire de popcorn -- 
CREATE TABLE POPCORN (
  id VARCHAR2(100) PRIMARY KEY,
  NOM VARCHAR2(100) NOT NULL
);

CREATE TABLE TYPEJOUET (
  id VARCHAR2(100) PRIMARY KEY,
  lib VARCHAR2(100) NOT NULL,
  prix NUMBER(15,2) NOT NULL
);

CREATE TABLE JOUET (
  id VARCHAR2(100) PRIMARY KEY,
  lib VARCHAR2(100) NOT NULL,
  idpopcorn VARCHAR2(100) REFERENCES POPCORN(id),
  idtypejouet VARCHAR2(100) REFERENCES TYPEJOUET(id)
);

CREATE TABLE TOY (
  id VARCHAR2(100) PRIMARY KEY,
  idclient VARCHAR2(100) NOT NULL REFERENCES CLIENT(id),
  idpopcorn VARCHAR2(100) NOT NULL REFERENCES POPCORN(id),   -- le paquet choisi
  montanttotal NUMBER(15,2) NOT NULL,
  etat NUMBER DEFAULT 1                                       -- 11 = validee (payee), 0 = annulee
);

CREATE TABLE TOYDETAIL (
  id VARCHAR2(100) PRIMARY KEY,
  idtoy VARCHAR2(100) NOT NULL REFERENCES TOY(id),
  idjouet VARCHAR2(100) NOT NULL REFERENCES JOUET(id),
  prix NUMBER(15,2) NOT NULL
);

-- ---------- Sequences + fonctions (une par table) ----------

-- Popcorn : une sequence + une fonction par table (chaque fonction lit SA sequence)
CREATE SEQUENCE SEQ_POP;
CREATE OR REPLACE FUNCTION GETSEQPOP RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_POP.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_TYPEJOUET;
CREATE OR REPLACE FUNCTION GETSEQTYPEJOUET RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_TYPEJOUET.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_JOUET;
CREATE OR REPLACE FUNCTION GETSEQJOUET RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_JOUET.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_TOY;
CREATE OR REPLACE FUNCTION GETSEQTOY RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_TOY.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_TOYDETAIL;
CREATE OR REPLACE FUNCTION GETSEQTOYDETAIL RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_TOYDETAIL.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

-- Reservation
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

-- Une vue qui permet de relier la jouet avec son prix 
-- Un jouet avec son paquet et son type (classe jouet.JouetLib) :
-- idpopcorn sert a filtrer "les jouets de CE paquet", typejouet et prix a les afficher.
CREATE OR REPLACE VIEW JOUET_LIB AS
SELECT j.id, j.lib, j.idpopcorn, p.nom, j.idtypejouet, tj.lib AS typejouet, tj.prix AS prix
FROM JOUET j
JOIN TYPEJOUET tj ON tj.id = j.idtypejouet
JOIN POPCORN p ON p.id = j.idpopcorn;

-- Une vente de jouets avec le nom du client et du paquet (classe toy.ToyLib) : pour la fiche
CREATE OR REPLACE VIEW TOY_LIB AS
SELECT t.id, t.idclient, c.nom AS client, t.idpopcorn, p.nom AS popcorn, t.montanttotal, t.etat
FROM TOY t
JOIN CLIENT c  ON c.id = t.idclient
JOIN POPCORN p ON p.id = t.idpopcorn;

-- Un jouet vendu avec son nom et son type ; prix = prix PAYE, recopie dans la ligne (classe toy.ToyDetailLib)
CREATE OR REPLACE VIEW TOYDETAIL_LIB AS
SELECT d.id, d.idtoy, d.idjouet, j.lib, tj.lib AS typejouet, d.prix
FROM TOYDETAIL d
JOIN JOUET j      ON j.id = d.idjouet
JOIN TYPEJOUET tj ON tj.id = j.idtypejouet;

-- ============================================================
-- Facture client (docs/conception/08_facture_client.md)
-- Une facture est FIGEE : client, objet et designations sont RECOPIES en texte.
-- ============================================================

CREATE TABLE FACTURE (
  id             VARCHAR2(100) PRIMARY KEY,                                     -- FAC000001 (technique)
  numero         VARCHAR2(20)  NOT NULL UNIQUE,                                 -- 0001/2026 (legal, continu)
  daty           DATE          NOT NULL,                                        -- date d'emission
  idclient       VARCHAR2(100) NOT NULL REFERENCES CLIENT(id),
  client         VARCHAR2(200) NOT NULL,                                        -- nom RECOPIE
  idreservation  VARCHAR2(100) NOT NULL UNIQUE REFERENCES RESERVATION(id),     -- une seule facture par reservation
  objet          VARCHAR2(300) NOT NULL,                                        -- "Dune 3 — 11/11/2026 18:00 — Salle 1"
  montanttotal   NUMBER(15,2)  NOT NULL,
  etat           NUMBER        DEFAULT 1                                        -- 11 = emise, 0 = annulee (plus tard)
);

CREATE TABLE FACTUREDETAIL (
  id           VARCHAR2(100) PRIMARY KEY,                                       -- FAD000001
  idfacture    VARCHAR2(100) NOT NULL REFERENCES FACTURE(id),
  designation  VARCHAR2(300) NOT NULL,                                          -- texte RECOPIE
  prix         NUMBER(15,2)  NOT NULL                                           -- prix PAYE, recopie
);

-- Le dernier numero de facture emis (0001, 0002...). UNE SEULE ligne (id = 1).
-- Le CALCUL est en Java (FactureService.prochainNumero) ; la base garde la valeur et tient le verrou (FOR UPDATE).
CREATE TABLE COMPTEURFACTURE (
  id       NUMBER(1) PRIMARY KEY CHECK (id = 1),   -- interdit une 2e ligne
  dernier  NUMBER    NOT NULL
);
INSERT INTO COMPTEURFACTURE (id, dernier) VALUES (1, 0);
COMMIT;

CREATE SEQUENCE SEQ_FACTURE;
CREATE OR REPLACE FUNCTION GETSEQFACTURE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_FACTURE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_FACTUREDETAIL;
CREATE OR REPLACE FUNCTION GETSEQFACTUREDETAIL RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_FACTUREDETAIL.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

-- ============================================================
-- Caisse (docs/conception/09_caisse.md)
-- La caisse ne stocke JAMAIS son solde : il se CALCULE en Java (CaisseService.solde)
-- a partir des mouvements (entrees - sorties). Un mouvement est FIGE.
-- ============================================================

CREATE TABLE CAISSE (
  id   VARCHAR2(100) PRIMARY KEY,                                    -- CAI000001
  nom  VARCHAR2(100) NOT NULL
);

CREATE TABLE MOUVEMENTCAISSE (
  id           VARCHAR2(100) PRIMARY KEY,                            -- MVC000001
  daty         DATE          NOT NULL,
  idcaisse     VARCHAR2(100) NOT NULL REFERENCES CAISSE(id),
  designation  VARCHAR2(300) NOT NULL,                               -- texte RECOPIE ("Facture n° 0003 — Rakoto Jean")
  entree       NUMBER(15,2)  DEFAULT 0 NOT NULL CHECK (entree >= 0),
  sortie       NUMBER(15,2)  DEFAULT 0 NOT NULL CHECK (sortie >= 0),
  idorigine    VARCHAR2(100) UNIQUE,                                 -- la facture (ou l'achat) : encaissee UNE fois
  etat         NUMBER        DEFAULT 1,                              -- 11 = valide, 0 = annule (plus tard)
  -- exactement UN des deux montants est rempli
  CONSTRAINT ck_mvt_un_sens CHECK ((entree > 0 AND sortie = 0) OR (entree = 0 AND sortie > 0))
);

CREATE SEQUENCE SEQ_CAISSE;
CREATE OR REPLACE FUNCTION GETSEQCAISSE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_CAISSE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_MOUVEMENTCAISSE;
CREATE OR REPLACE FUNCTION GETSEQMOUVEMENTCAISSE RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_MOUVEMENTCAISSE.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

-- L'unique caisse du cinema (pour l'instant)
INSERT INTO CAISSE (id, nom) VALUES ('CAI' || LPAD(GETSEQCAISSE, 6, '0'), 'Guichet principal');
COMMIT;

-- ============================================================
-- Achat de films (docs/conception/10_achat_film.md)
-- Un achat = un distributeur, un film (cree par l'achat), un montant.
-- Paye immediatement : l'achat et sa SORTIE de caisse sont dans la meme transaction.
-- ============================================================

CREATE TABLE DISTRIBUTEUR (
  id       VARCHAR2(100) PRIMARY KEY,                               -- DIS000001
  nom      VARCHAR2(100) NOT NULL,
  contact  VARCHAR2(200)
);

CREATE TABLE ACHAT (
  id              VARCHAR2(100) PRIMARY KEY,                        -- ACH000001
  daty            DATE          NOT NULL,
  iddistributeur  VARCHAR2(100) NOT NULL REFERENCES DISTRIBUTEUR(id),
  idfilm          VARCHAR2(100) NOT NULL UNIQUE REFERENCES FILM(id), -- un film n'est achete qu'UNE fois
  montant         NUMBER(15,2)  NOT NULL CHECK (montant > 0),
  etat            NUMBER        DEFAULT 1                           -- 11 = paye, 0 = annule (plus tard)
);

CREATE SEQUENCE SEQ_DISTRIBUTEUR;
CREATE OR REPLACE FUNCTION GETSEQDISTRIBUTEUR RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_DISTRIBUTEUR.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

CREATE SEQUENCE SEQ_ACHAT;
CREATE OR REPLACE FUNCTION GETSEQACHAT RETURN NUMBER IS r NUMBER;
BEGIN SELECT SEQ_ACHAT.NEXTVAL INTO r FROM DUAL; RETURN r; END;
/

-- Les distributeurs de depart
INSERT INTO DISTRIBUTEUR (id, nom, contact) VALUES ('DIS' || LPAD(GETSEQDISTRIBUTEUR, 6, '0'), 'Netflix', 'licensing@netflix.example');
INSERT INTO DISTRIBUTEUR (id, nom, contact) VALUES ('DIS' || LPAD(GETSEQDISTRIBUTEUR, 6, '0'), 'Disney',  'droits@disney.example');
INSERT INTO DISTRIBUTEUR (id, nom, contact) VALUES ('DIS' || LPAD(GETSEQDISTRIBUTEUR, 6, '0'), 'Warner',  'cinema@warner.example');
COMMIT;
