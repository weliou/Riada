-- -----------------------------------------------------
-- Script: 01_Create_Database.sql
-- Objectif: Créer le schéma officiel du projet 'Riada'
-- -----------------------------------------------------

/*
ATTENTION : La ligne suivante supprime la base de données existante.
Elle est utile en développement, mais doit être retirée en production.
*/
DROP DATABASE IF EXISTS riada_db;

-- Crée la base de données si elle n'existe pas
CREATE DATABASE IF NOT EXISTS riada_db
    -- Utilisation du standard MySQL 8.0 (Unicode 9.0), 
    -- plus performant et précis que les anciens utf8mb4_unicode_ci
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

-- Définit la base de données créée comme schéma actif pour la session
USE riada_db;