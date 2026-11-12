-- ============================================================
-- Cinema : les entrees de menu des fonctionnalites (apres 00_socle.sql)
-- Voir docs/apprentissageAPJ/menu_dynamique.md
--
-- APRES l'execution : REDEPLOYER (ant) puis se DECONNECTER / RECONNECTER.
-- (la liste des menus est gardee en memoire de l'application ET de la session)
--
-- Rubrique « Cinema » (MENCINEMA) :
--   rang 1 : Reserver           (00_socle.sql)
--   rang 2 : Vendre du popcorn  (pas encore)
--   rang 3 : Etat de la caisse  (pas encore)
--   rang 4 : Acheter un film
-- ============================================================

INSERT INTO MENUDYNAMIQUE (id, libelle, icone, href, rang, niveau, id_pere)
VALUES ('MENCINEMAACHAT', 'Acheter un film', 'shopping_cart',
        'module.jsp?but=achat/achat-saisie.jsp', 4, 2, 'MENCINEMA');

-- Visible par tout le monde
INSERT INTO USERMENU (id, refuser, idmenu, idrole, codeservice, codedir, interdit)
VALUES ('USMCINEMAACHAT', '*', 'MENCINEMAACHAT', NULL, NULL, NULL, 0);

COMMIT;
