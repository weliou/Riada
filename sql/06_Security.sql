-- -----------------------------------------------------
-- Script: 06_Security.sql (Version V4.1 - DBA FINAL)
-- Objectif: Créer un utilisateur sécurisé V4 (Moindre Privilège)
-- -----------------------------------------------------
USE riada_db;

-- -----------------------------------------------------
-- ETAPE 1: Créer l'utilisateur
-- -----------------------------------------------------
CREATE USER IF NOT EXISTS 'portique_user'@'localhost' 
IDENTIFIED BY 'RiadA-P0rt1qu3-K3y-@2025';

-- -----------------------------------------------------
-- ETAPE 2: Appliquer le VRAI Principe de Moindre Privilège
-- -----------------------------------------------------
-- L'utilisateur n'a besoin QUE d'exécuter les procédures.
-- Les procédures s'exécutent en tant que 'DEFINER' (root),
-- qui a déjà les droits SELECT (membres, factures, clubs...)
-- et INSERT (journal_acces...)

GRANT EXECUTE ON PROCEDURE riada_db.sp_CheckAccess 
TO 'portique_user'@'localhost';

GRANT EXECUTE ON PROCEDURE riada_db.sp_CheckAccessInvite 
TO 'portique_user'@'localhost';

-- -----------------------------------------------------
-- ETAPE 3: Activer les permissions
-- -----------------------------------------------------
FLUSH PRIVILEGES;