-- -----------------------------------------------------
-- Script: 02_Create_Tables_V5.0_Structure.sql
-- Objectif: Créer la structure des 19 tables (sans index secondaires ni FK)
--           Optimisé pour le chargement de données en masse.
-- -----------------------------------------------------
USE riada_db;

-- =====================================================
-- TABLE 1 : clubs
-- =====================================================
CREATE TABLE IF NOT EXISTS clubs (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nom_club VARCHAR(150) NOT NULL COMMENT 'Nom commercial du club',
    adresse_rue VARCHAR(255) NOT NULL,
    adresse_ville VARCHAR(100) NOT NULL,
    adresse_code_postal VARCHAR(10) NOT NULL,
    pays VARCHAR(50) DEFAULT 'Belgique',
    est_ouvert_24_7 BOOLEAN DEFAULT TRUE COMMENT 'Indique si le club a un accès 24/7',
    date_ouverture DATE NOT NULL,
    statut_operationnel ENUM('Ouvert', 'Fermé Temporairement', 'Fermé Définitivement') DEFAULT 'Ouvert'
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 2: membres
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS membres (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    sexe ENUM('Homme', 'Femme', 'Non précisé') DEFAULT 'Non précisé',
    date_naissance DATE NOT NULL COMMENT 'Pour tarifs et statistiques âge',
    nationalite VARCHAR(50) DEFAULT 'Belge',
    telephone_mobile VARCHAR(20) NOT NULL,
    adresse_rue VARCHAR(255) NOT NULL,
    adresse_ville VARCHAR(100) NOT NULL,
    adresse_code_postal VARCHAR(10) NOT NULL,
    objectif_principal ENUM('Perte de poids', 'Prise de masse', 'Remise en forme', 'Maintien', 'Autre') COMMENT 'Objectif déclaré',
    source_acquisition ENUM('Publicité Web', 'Réseaux sociaux', 'Bouche-à-oreille', 'Autre') COMMENT 'Canal d''acquisition',
    certificat_medical_fourni BOOLEAN DEFAULT FALSE COMMENT 'Conformité légale',
    date_consentement_rgpd DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Preuve conformité',
    consentement_marketing BOOLEAN DEFAULT FALSE COMMENT 'Accepte usage données à fins marketing',
    derniere_visite DATE NULL COMMENT 'Pour statistiques inactivité/churn',
    nombre_visites_total INT DEFAULT 0
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 3: abonnements
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS abonnements (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nom_offre VARCHAR(100) NOT NULL UNIQUE,
    prix_base DECIMAL(7, 2) NOT NULL,
    duree_engagement_mois INT DEFAULT 12 COMMENT 'Durée minimale d''engagement',
    frais_inscription DECIMAL(5,2) DEFAULT 19.99 COMMENT 'Frais de démarrage',
    acces_club_limite BOOLEAN DEFAULT FALSE COMMENT 'Vrai si limité au club de rattachement (Basic)',
    acces_duo_permis BOOLEAN DEFAULT FALSE COMMENT 'Permet d''emmener un ami (Premium)'
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 4: contrats_adhesion
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS contrats_adhesion (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    membre_id INT UNSIGNED NULL, 
    abonnement_id INT UNSIGNED NOT NULL,
    club_rattachement_id INT UNSIGNED NOT NULL COMMENT 'Club d''inscription',
    date_debut DATE NOT NULL,
    date_fin DATE NULL,
    type_contrat ENUM('Durée Déterminée', 'Durée Indéterminée') NOT NULL DEFAULT 'Durée Déterminée',
    statut ENUM('Actif', 'Gelé', 'Expiré', 'Résilié') NOT NULL DEFAULT 'Actif',
    date_resiliation DATE NULL,
    motif_resiliation VARCHAR(255) NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 5: options_services
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS options_services (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nom_option VARCHAR(100) NOT NULL UNIQUE,
    prix_mensuel DECIMAL(7, 2) NOT NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 6: abonnement_options
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS abonnement_options (
    abonnement_id INT UNSIGNED NOT NULL,
    option_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (abonnement_id, option_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 7 : options_contrat
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS options_contrat (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    contrat_id INT UNSIGNED NOT NULL,
    option_id INT UNSIGNED NOT NULL,
    date_ajout DATE NOT NULL,
    date_retrait DATE NULL,
    UNIQUE KEY uk_contrat_option_actif (contrat_id, option_id)
) ENGINE=InnoDB;

-- =====================================================
-- TABLE 8 : factures
-- =====================================================
CREATE TABLE IF NOT EXISTS factures (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    contrat_id INT UNSIGNED NULL, 
    numero_facture VARCHAR(50) UNIQUE NOT NULL,
    date_emission DATE NOT NULL DEFAULT (CURRENT_DATE),
    date_echeance DATE NOT NULL,
    periode_debut DATE NOT NULL,
    periode_fin DATE NOT NULL,
    montant_ht DECIMAL(7,2) NOT NULL,
    taux_tva DECIMAL(4,2) DEFAULT 21.00,
    montant_tva DECIMAL(7,2) GENERATED ALWAYS AS (ROUND(montant_ht * taux_tva / 100, 2)) STORED,
    montant_ttc DECIMAL(7,2) GENERATED ALWAYS AS (ROUND(montant_ht + (montant_ht * taux_tva / 100), 2)) STORED,
    statut_facture ENUM('Brouillon', 'Émise', 'Payée', 'Partiellement payée', 'Impayée', 'Annulée') DEFAULT 'Émise',
    montant_deja_paye DECIMAL(7,2) DEFAULT 0.00,
    solde_restant DECIMAL(7,2) GENERATED ALWAYS AS (montant_ttc - montant_deja_paye) STORED,
    date_paiement_complet DATETIME NULL
) ENGINE=InnoDB;

-- =====================================================
-- TABLE 9 : lignes_factures
-- =====================================================
CREATE TABLE IF NOT EXISTS lignes_factures (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    facture_id INT UNSIGNED NOT NULL,
    libelle VARCHAR(255) NOT NULL,
    type_ligne ENUM('Abonnement', 'Option', 'Frais inscription', 'Pénalité', 'Avoir', 'Autre') NOT NULL,
    abonnement_id INT UNSIGNED NULL,
    option_id INT UNSIGNED NULL,
    quantite INT DEFAULT 1,
    prix_unitaire_ht DECIMAL(7,2) NOT NULL,
    taux_tva DECIMAL(4,2) DEFAULT 21.00,
    montant_ligne_ht DECIMAL(7,2) GENERATED ALWAYS AS (quantite * prix_unitaire_ht) STORED,
    montant_ligne_ttc DECIMAL(7,2) GENERATED ALWAYS AS (ROUND(quantite * prix_unitaire_ht * (1 + taux_tva/100), 2)) STORED
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 10: paiements
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS paiements (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    facture_id INT UNSIGNED NOT NULL, 
    date_paiement DATE NOT NULL,
    montant_paye DECIMAL(7, 2) NOT NULL,
    statut_paiement ENUM('Réussi', 'Échoué', 'Annulé', 'Remboursé') NOT NULL,
    type_paiement ENUM('SEPA/Domiciliation', 'Carte Bancaire', 'Espèces', 'Virement') NOT NULL DEFAULT 'SEPA/Domiciliation',
    reference_transaction VARCHAR(100) NULL,
    code_erreur VARCHAR(50) NULL,
    nombre_tentatives TINYINT DEFAULT 1
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 11: journal_acces
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_acces (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    membre_id INT UNSIGNED NULL, 
    club_id INT UNSIGNED NOT NULL,
    date_passage DATETIME NOT NULL,
    statut_acces ENUM('Accepté', 'Refusé') NOT NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 12: cours
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS cours (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nom_cours VARCHAR(100) NOT NULL UNIQUE,
    description_cours TEXT NULL,
    niveau_difficulte ENUM('Débutant', 'Intermédiaire', 'Avancé', 'Tous niveaux') DEFAULT 'Tous niveaux',
    duree_minutes SMALLINT UNSIGNED NOT NULL,
    capacite_max SMALLINT UNSIGNED NOT NULL DEFAULT 20,
    calories_estimees INT NULL,
    type_activite ENUM('Cardio', 'Musculation', 'Souplesse', 'Relaxation', 'Danse', 'Combat', 'Mixte')
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 13: employes
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS employes (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    club_id INT UNSIGNED NOT NULL,
    role ENUM('Instructeur', 'Manager', 'Accueil', 'Technicien', 'Stagiaire', 'Direction') NOT NULL,
    salaire_mensuel DECIMAL(7,2) NULL,
    qualifications TEXT NULL,
    date_embauche DATE NOT NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 14: sessions_cours
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS sessions_cours (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    cours_id INT UNSIGNED NOT NULL,
    instructeur_id INT UNSIGNED NOT NULL,
    club_id INT UNSIGNED NOT NULL,
    heure_debut DATETIME NOT NULL,
    duree_minutes SMALLINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 15: reservations
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS reservations (
    membre_id INT UNSIGNED NOT NULL,
    session_id INT UNSIGNED NOT NULL,
    date_reservation DATETIME DEFAULT CURRENT_TIMESTAMP,
    statut_reservation ENUM('Confirmée', 'Liste d''attente', 'Annulée') NOT NULL DEFAULT 'Confirmée',
    PRIMARY KEY (membre_id, session_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 16: equipements
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS equipements (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nom_equipement VARCHAR(100) NOT NULL, 
    type_equipement VARCHAR(50) NOT NULL,
    club_id INT UNSIGNED NOT NULL,
    marque VARCHAR(100) NULL,
    modele VARCHAR(100) NULL,
    annee_acquisition INT NOT NULL,
    statut_equipement ENUM('En service', 'En panne', 'En maintenance', 'Retiré') NOT NULL DEFAULT 'En service',
    cout_achat DECIMAL(10,2) NULL,
    compteur_heures_utilisation INT DEFAULT 0
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 17: maintenance
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS maintenance (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    equipement_id INT UNSIGNED NOT NULL,
    technicien_id INT UNSIGNED NULL,
    type_maintenance ENUM('Panne', 'Préventive', 'Installation') NOT NULL,
    statut_maintenance ENUM('Signalé', 'Assigné', 'En cours', 'Résolu') NOT NULL DEFAULT 'Signalé',
    priorite ENUM('Faible', 'Moyenne', 'Haute', 'Urgence') NOT NULL DEFAULT 'Moyenne',
    date_signalement DATETIME NOT NULL,
    date_resolution DATETIME NULL,
    description_probleme TEXT NULL,
    cout_reparation DECIMAL(7,2) DEFAULT 0.00
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 18: invites
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS invites (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    membre_parrain_id INT UNSIGNED NULL,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    date_naissance DATE NOT NULL,
    email VARCHAR(100) NULL,
    statut ENUM('Actif', 'Banni') NOT NULL DEFAULT 'Actif',
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- TABLE 19: journal_acces_invites
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_acces_invites (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    invite_id INT UNSIGNED NOT NULL,
    membre_accompagnateur_id INT UNSIGNED NULL, 
    club_id INT UNSIGNED NOT NULL,
    date_passage DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    statut_acces ENUM('Autorisé', 'Refusé') NOT NULL,
    raison_refus VARCHAR(255) NULL
) ENGINE=InnoDB;

SELECT '19 tables (V5.0 - Structure) créées.' AS Status;