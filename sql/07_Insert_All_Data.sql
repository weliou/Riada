-- -----------------------------------------------------
-- Script: 07_Insert_All_Data.sql (Version V4 - Standardisée DBA)
-- Objectif: Remplir les tables avec TOUS les scénarios de test
-- -----------------------------------------------------
USE riada_db;

-- =====================================================
-- 1. TABLE clubs 
-- =====================================================
INSERT IGNORE INTO clubs (id, nom_club, adresse_rue, adresse_ville, adresse_code_postal, date_ouverture) 
VALUES
(1, 'Riada Bruxelles Nord', 'Rue du Progrès 1', 'Bruxelles', '1000', '2020-01-10'),
(2, 'Riada Liège Sud', 'Boulevard d''Avroy 50', 'Liège', '4000', '2023-05-20');

-- =====================================================
-- 2. Catalogues (Abonnements, Options, Cours)
-- =====================================================
INSERT IGNORE INTO abonnements (id, nom_offre, prix_base, duree_engagement_mois, frais_inscription, acces_club_limite, acces_duo_permis)
VALUES 
(1, 'Basic Annuel', 19.99, 12, 19.99, TRUE, FALSE),
(2, 'Comfort Annuel', 24.99, 12, 19.99, FALSE, FALSE),
(3, 'Premium Annuel', 29.99, 12, 19.99, FALSE, TRUE); -- Marie a accès au Pass Duo

INSERT IGNORE INTO options_services (id, nom_option, prix_mensuel)
VALUES 
(1, 'Yanga Sportswater', 5.99), 
(2, 'Massages Pro', 9.99),
(3, 'Coaching 1 fois/mois', 49.99);

INSERT IGNORE INTO cours (id, nom_cours, description_cours, niveau_difficulte, duree_minutes, capacite_max, calories_estimees, type_activite)
VALUES 
(1, 'Yoga Flow', 'Cours de relaxation et étirements.', 'Tous niveaux', 60, 15, 150, 'Souplesse'),
(2, 'Body Pump', 'Renforcement musculaire intense.', 'Intermédiaire', 45, 30, 400, 'Musculation'),
(3, 'HIIT Express', 'Intervalles de haute intensité.', 'Avancé', 30, 25, 550, 'Cardio');

-- =====================================================
-- 3. Entités Pilier (Employés, Membres)
-- =====================================================
INSERT IGNORE INTO employes (id, nom, prenom, email, club_id, role, date_embauche)
VALUES 
(1, 'Martin', 'Alice', 'alice.martin@riada.db', 1, 'Manager', '2019-05-01'),
(2, 'Dubois', 'Thomas', 'thomas.dubois@riada.db', 1, 'Instructeur', '2021-08-10'),
(3, 'Lefevre', 'Marc', 'marc.lefevre@riada.db', 2, 'Technicien', '2022-03-25'),
(4, 'Bernard', 'Louise', 'louise.bernard@riada.db', 2, 'Instructeur', '2023-11-15');

INSERT IGNORE INTO membres (id, nom, prenom, email, sexe, date_naissance, nationalite, telephone_mobile, adresse_rue, adresse_ville, adresse_code_postal, date_consentement_rgpd)
VALUES 
(1, 'Dupont', 'Marie', 'marie.dupont@email.com', 'Femme', '1995-03-12', 'Belge', '+32470112233', 'Rue de la Loi 10', 'Bruxelles', '1000', NOW()),
(2, 'Durand', 'Pierre', 'pierre.durand@email.com', 'Homme', '1988-11-20', 'Française', '+33612345678', 'Av. des Ardennes 5', 'Liège', '4000', NOW()),
(3, 'Leroy', 'Sophie', 'sophie.leroy@email.com', 'Femme', '1990-01-01', 'Belge', '+32470998877', 'Rue Neuve 2', 'Bruxelles', '1000', NOW());

-- =====================================================
-- 4. Relations N-N (Abonnement Options)
-- =====================================================
INSERT IGNORE INTO abonnement_options (abonnement_id, option_id)
VALUES (3, 1), (3, 2); 

-- =====================================================
-- 5. Contrats d'Adhésion (Table Parente)
-- =====================================================
INSERT IGNORE INTO contrats_adhesion (id, membre_id, abonnement_id, club_rattachement_id, date_debut, date_fin, statut, type_contrat)
VALUES 
    (1, 1, 3, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'Actif', 'Durée Déterminée'), -- Marie (Premium)
    (2, 2, 1, 2, DATE_SUB(CURDATE(), INTERVAL 2 MONTH), DATE_ADD(CURDATE(), INTERVAL 1 MONTH), 'Actif', 'Durée Déterminée'), -- Pierre (Basic)
    (3, 3, 1, 1, DATE_SUB(CURDATE(), INTERVAL 1 YEAR), DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 'Expiré', 'Durée Déterminée'); -- Sophie (Expiré)

-- =====================================================
-- 6. Relations N-N (Options Contrat)
-- =====================================================
INSERT IGNORE INTO options_contrat (id, contrat_id, option_id, date_ajout)
VALUES (1, 1, 3, CURDATE()); -- Marie (Contrat 1) ajoute l'option Coaching (3)

-- =====================================================
-- 7. [LOGIQUE V2] Factures (Les "Dettes")
-- =====================================================
INSERT IGNORE INTO factures (id, contrat_id, numero_facture, date_emission, date_echeance, periode_debut, periode_fin, montant_ht, statut_facture)
VALUES (1, 1, 'FAC-2025-00001', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 15 DAY), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 MONTH), 66.10, 'Émise');

INSERT IGNORE INTO lignes_factures (facture_id, libelle, type_ligne, abonnement_id, quantite, prix_unitaire_ht)
VALUES
(1, 'Abonnement Premium Annuel', 'Abonnement', 3, 1, 24.79),
(1, 'Option Coaching 1 fois/mois', 'Option', NULL, 1, 41.31);

INSERT IGNORE INTO factures (id, contrat_id, numero_facture, date_emission, date_echeance, periode_debut, periode_fin, montant_ht, statut_facture)
VALUES (2, 2, 'FAC-2025-00002', DATE_SUB(CURDATE(), INTERVAL 1 MONTH), DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_SUB(CURDATE(), INTERVAL 1 MONTH), CURDATE(), 16.52, 'Impayée');

INSERT IGNORE INTO lignes_factures (facture_id, libelle, type_ligne, abonnement_id, quantite, prix_unitaire_ht)
VALUES (2, 'Abonnement Basic Annuel', 'Abonnement', 1, 1, 16.52);

-- =====================================================
-- 8. [LOGIQUE V2] Paiements (Les "Règlements")
-- =====================================================
INSERT IGNORE INTO paiements (facture_id, date_paiement, montant_paye, statut_paiement, type_paiement, reference_transaction)
VALUES (1, CURDATE(), 79.98, 'Réussi', 'Carte Bancaire', 'txn_marie_123');

INSERT IGNORE INTO paiements (facture_id, date_paiement, montant_paye, statut_paiement, type_paiement, code_erreur)
VALUES (2, DATE_SUB(CURDATE(), INTERVAL 14 DAY), 19.99, 'Échoué', 'SEPA/Domiciliation', 'ERR_INSUFFISANT');

-- =====================================================
-- 9. Journal d'Accès (Membres)
-- =====================================================
INSERT IGNORE INTO journal_acces (id, membre_id, club_id, date_passage, statut_acces)
VALUES 
    (1, 1, 1, NOW(), 'Accepté'), -- Scan de Marie (Nécessaire pour le Pass Duo)
    (2, 2, 1, DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Refusé'),
    (3, 3, 2, DATE_SUB(NOW(), INTERVAL 2 HOUR), 'Refusé'); 

-- =====================================================
-- 10. Sessions et Réservations
-- =====================================================
INSERT IGNORE INTO sessions_cours (id, cours_id, instructeur_id, club_id, heure_debut, duree_minutes)
VALUES 
(1, 1, 2, 1, DATE_ADD(NOW(), INTERVAL 1 DAY), 60),
(2, 2, 4, 2, DATE_ADD(NOW(), INTERVAL 1 DAY) + INTERVAL 1 HOUR, 45); 

INSERT IGNORE INTO reservations (membre_id, session_id, statut_reservation)
VALUES (1, 1, 'Confirmée'); 

-- =====================================================
-- 11. Maintenance
-- =====================================================
INSERT IGNORE INTO equipements (id, nom_equipement, type_equipement, club_id, annee_acquisition, statut_equipement)
VALUES 
(1, 'Tapis de course #1', 'Cardio', 1, 2024, 'En service'),
(2, 'Tapis de course #2', 'Cardio', 1, 2023, 'En panne');

INSERT IGNORE INTO maintenance (equipement_id, technicien_id, type_maintenance, statut_maintenance, date_signalement, description_probleme)
VALUES (2, 3, 'Panne', 'Assigné', NOW(), 'Le tapis ne démarre pas. Surchauffe.');

-- =====================================================
-- 12. [LOGIQUE V3] Invités (Pass Duo)
-- =====================================================
INSERT IGNORE INTO invites (id, membre_parrain_id, nom, prenom, date_naissance, email)
VALUES (1, 1, 'Dupont', 'Thomas', '1994-11-10', 'thomas.dupont.invite@email.com');

INSERT IGNORE INTO invites (id, membre_parrain_id, nom, prenom, date_naissance, email)
VALUES (2, 2, 'Durand', 'Luc', '1990-05-05', 'luc.durand.invite@email.com');

INSERT IGNORE INTO journal_acces_invites (invite_id, membre_accompagnateur_id, club_id, date_passage, statut_acces)
VALUES (1, 1, 1, DATE_ADD(NOW(), INTERVAL 5 MINUTE), 'Autorisé');

-- =====================================================
-- 13. [AJOUT V4] Données de test pour cas limites (Claude)
-- =====================================================

-- Membre 4: Contrat Gelé (pour Test 10)
INSERT IGNORE INTO membres (id, nom, prenom, email, sexe, date_naissance, nationalite, telephone_mobile, adresse_rue, adresse_ville, adresse_code_postal, date_consentement_rgpd)
VALUES (4, 'Lambert', 'Luc', 'luc.lambert@email.com', 'Homme', '1985-07-15', 'Belge', '+32471234567', 'Rue de Fer 10', 'Namur', '5000', NOW());

INSERT IGNORE INTO contrats_adhesion (id, membre_id, abonnement_id, club_rattachement_id, date_debut, statut, type_contrat)
VALUES (4, 4, 1, 2, CURDATE(), 'Gelé', 'Durée Déterminée');

-- Invité 3: Banni (pour Test 11)
INSERT IGNORE INTO invites (id, membre_parrain_id, nom, prenom, date_naissance, email, statut)
VALUES (3, 1, 'Martin', 'Anne', '1996-01-01', 'anne.martin.invite@email.com', 'Banni');

-- Membre 5: Premium mais Impayé (pour Test 12 - Faille V3)
INSERT IGNORE INTO membres (id, nom, prenom, email, sexe, date_naissance, nationalite, telephone_mobile, adresse_rue, adresse_ville, adresse_code_postal, date_consentement_rgpd)
VALUES (5, 'Lejeune', 'Jean', 'jean.lejeune@email.com', 'Homme', '1992-02-02', 'Belge', '+32472345678', 'Av. Louise 100', 'Bruxelles', '1050', NOW());

INSERT IGNORE INTO contrats_adhesion (id, membre_id, abonnement_id, club_rattachement_id, date_debut, statut, type_contrat)
VALUES (5, 5, 3, 1, CURDATE(), 'Actif', 'Durée Déterminée'); -- Premium (Pass Duo OK)

INSERT IGNORE INTO factures (id, contrat_id, numero_facture, date_emission, date_echeance, periode_debut, periode_fin, montant_ht, statut_facture)
VALUES (3, 5, 'FAC-2025-00003', DATE_SUB(CURDATE(), INTERVAL 1 MONTH), DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_SUB(CURDATE(), INTERVAL 1 MONTH), CURDATE(), 24.79, 'Impayée'); -- Facture en retard

INSERT IGNORE INTO lignes_factures (facture_id, libelle, type_ligne, abonnement_id, quantite, prix_unitaire_ht)
VALUES (3, 'Abonnement Premium Annuel', 'Abonnement', 3, 1, 24.79);