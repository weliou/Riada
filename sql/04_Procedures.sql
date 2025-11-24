-- -----------------------------------------------------
-- Script: 04_Procedures.sql (Version V5 - Optimisée DBA)
-- Objectif: Corriger la règle métier (10 min) et optimiser les lookups.
-- -----------------------------------------------------
USE riada_db;

DELIMITER $$

-- -----------------------------------------------------
-- PROCÉDURE 1: sp_CheckAccess (Membres)
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_CheckAccess$$

CREATE PROCEDURE sp_CheckAccess(
    IN p_membre_id INT UNSIGNED,
    IN p_club_id INT UNSIGNED,
    OUT p_decision ENUM('Accepté', 'Refusé')
)
main_logic: BEGIN
    DECLARE v_contrat_id INT UNSIGNED;
    DECLARE v_statut_contrat ENUM('Actif', 'Gelé', 'Expiré', 'Résilié');
    DECLARE v_club_rattachement_id INT UNSIGNED;
    DECLARE v_acces_limite BOOLEAN;
    DECLARE v_membre_existe INT DEFAULT 0;
    DECLARE v_club_existe INT DEFAULT 0;
    DECLARE v_impayes_en_retard INT DEFAULT 0;

    -- Décision par défaut
    SET p_decision = 'Refusé';
    
    -- [CORRECTION #4] Vérifier que le club existe (évite violation FK au log)
    -- Important pour que le INSERT final ne échoue jamais.
    SELECT COUNT(*) INTO v_club_existe FROM clubs WHERE id = p_club_id;
    IF v_club_existe = 0 THEN
        -- Si le club n'existe pas, on ne peut pas logger (violation FK sur club_id).
        -- On sort silencieusement. L'accès est 'Refusé' par défaut.
        LEAVE main_logic; 
    END IF;
    
    -- Vérifie si le membre est connu de la base de données
    SELECT COUNT(*) INTO v_membre_existe FROM membres WHERE id = p_membre_id;
    
    -- On ne vérifie la logique (contrat, paiement) que si le membre existe
    IF v_membre_existe = 1 THEN
    
        -- Cherche le dernier contrat ACTIF du membre
        SELECT 
            c.id, 
            c.statut, 
            c.club_rattachement_id, 
            a.acces_club_limite 
        INTO 
            v_contrat_id, v_statut_contrat, v_club_rattachement_id, v_acces_limite
        FROM 
            contrats_adhesion AS c
        INNER JOIN 
            abonnements AS a ON c.abonnement_id = a.id
        WHERE 
            c.membre_id = p_membre_id
            AND c.statut = 'Actif'
            AND (c.date_fin IS NULL OR c.date_fin >= CURDATE()) 
        ORDER BY 
            c.date_debut DESC
        LIMIT 1;

        -- Si un contrat actif est trouvé...
        IF v_contrat_id IS NOT NULL THEN
            -- VÉRIF 1: Accès limité à un autre club ?
            IF v_acces_limite = TRUE AND v_club_rattachement_id != p_club_id THEN
                SET p_decision = 'Refusé';
            ELSE
                -- VÉRIF 2: Y a-t-il des factures en retard ?
                -- Cette requête est optimisée par l'index 'idx_facture_check_v2'
                SELECT 
                    COUNT(f.id) INTO v_impayes_en_retard
                FROM 
                    factures AS f
                WHERE 
                    f.contrat_id = v_contrat_id
                    AND f.statut_facture IN ('Impayée', 'Partiellement payée')
                    AND f.date_echeance < CURDATE(); 

                IF v_impayes_en_retard > 0 THEN
                    SET p_decision = 'Refusé'; -- Bloqué pour impayé
                ELSE
                    SET p_decision = 'Accepté'; -- OK
                END IF;
            END IF;
        END IF; -- (Pas de contrat actif trouvé, p_decision reste 'Refusé')
    END IF; -- (Membre n'existe pas, p_decision reste 'Refusé')

    -- [CORRECTION #3] Log Toujours p_membre_id (même 999)
    -- Ceci fonctionne car la FK sur membre_id (Table 11) a été supprimée (Script 02).
    INSERT INTO journal_acces 
        (membre_id, club_id, date_passage, statut_acces)
    VALUES
        (p_membre_id, p_club_id, NOW(), p_decision);
        
END main_logic$$


-- -----------------------------------------------------
-- PROCÉDURE 2: sp_CheckAccessInvite (Pass Duo V3) - CORRIGÉE V5
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_CheckAccessInvite$$

CREATE PROCEDURE sp_CheckAccessInvite(
    IN p_invite_id INT UNSIGNED,
    IN p_membre_accompagnateur_id INT UNSIGNED,
    IN p_club_id INT UNSIGNED,
    OUT p_decision ENUM('Autorisé', 'Refusé')
)
main_invite_logic: BEGIN
    DECLARE v_raison_refus VARCHAR(255) DEFAULT 'Raison inconnue';
    DECLARE v_membre_a_pass_duo BOOLEAN DEFAULT FALSE;
    DECLARE v_membre_journal_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_invite_statut ENUM('Actif', 'Banni');
    DECLARE v_invite_age INT;
    DECLARE v_club_existe INT DEFAULT 0;
    DECLARE v_contrat_id_membre INT UNSIGNED; 
    DECLARE v_impayes_en_retard INT DEFAULT 0;

    -- Décision par défaut
    SET p_decision = 'Refusé';

    -- [CORRECTION #4] Vérifier que le club existe (évite violation FK au log)
    SELECT COUNT(*) INTO v_club_existe FROM clubs WHERE id = p_club_id;
    IF v_club_existe = 0 THEN
        SET v_raison_refus = 'Club ID inconnu';
        LEAVE main_invite_logic; -- Sortie. Le log final gérera.
    END IF;

    -- VÉRIFICATION 1 (Invité Existe/Banni)
    SELECT statut, TIMESTAMPDIFF(YEAR, date_naissance, CURDATE())
    INTO v_invite_statut, v_invite_age
    FROM invites
    WHERE id = p_invite_id;
    
    IF v_invite_statut IS NULL THEN
        SET v_raison_refus = 'Invité non enregistré';
        LEAVE main_invite_logic;
    END IF;
    IF v_invite_statut = 'Banni' THEN
        SET v_raison_refus = 'Invité banni';
        LEAVE main_invite_logic;
    END IF;

    -- VÉRIFICATION 2 (Âge)
    IF v_invite_age < 16 THEN
        SET v_raison_refus = 'Invité mineur non autorisé (minimum 16 ans)';
        LEAVE main_invite_logic;
    END IF;

    -- VÉRIFICATION 3 (Pass Duo + récupération contrat_id)
    SELECT ca.id, a.acces_duo_permis
    INTO v_contrat_id_membre, v_membre_a_pass_duo
    FROM contrats_adhesion ca
    INNER JOIN abonnements a ON ca.abonnement_id = a.id
    WHERE ca.membre_id = p_membre_accompagnateur_id
      AND ca.statut = 'Actif'
      AND (ca.date_fin IS NULL OR ca.date_fin >= CURDATE())
    ORDER BY ca.date_debut DESC 
    LIMIT 1;
    
    IF NOT v_membre_a_pass_duo THEN
        SET v_raison_refus = 'Le membre n''a pas l''option Pass Duo active'; 
        LEAVE main_invite_logic;
    END IF;

    -- [CORRECTION #1] VÉRIFICATION 4: Le membre a-t-il des IMPAYÉS ?
    -- Optimisé par 'idx_facture_check_v2'
    SELECT COUNT(f.id) INTO v_impayes_en_retard
    FROM factures AS f
    WHERE f.contrat_id = v_contrat_id_membre -- On utilise le contrat du membre
      AND f.statut_facture IN ('Impayée', 'Partiellement payée')
      AND f.date_echeance < CURDATE();

    IF v_impayes_en_retard > 0 THEN
        SET v_raison_refus = 'Membre accompagnateur en impayé (accès invité refusé)';
        LEAVE main_invite_logic;
    END IF;
    
    -- [CORRECTION LOGIQUE V5] VÉRIFICATION 5 (Présence)
    -- Règle métier assouplie de 10 à 30 minutes (cf. note V4)
    -- Optimisé par 'idx_journal_invite_check'
    SELECT id INTO v_membre_journal_id
    FROM journal_acces
    WHERE membre_id = p_membre_accompagnateur_id
      AND club_id = p_club_id
      AND statut_acces = 'Accepté'
      -- Règle métier: Doit avoir scanné il y a moins de 30 mins
      AND date_passage >= NOW() - INTERVAL 30 MINUTE 
    ORDER BY date_passage DESC
    LIMIT 1;
    
    IF v_membre_journal_id IS NULL THEN
        SET v_raison_refus = 'Membre accompagnateur absent (Scan < 30 min requis)';
        LEAVE main_invite_logic;
    END IF;
    
    -- SUCCÈS
    SET p_decision = 'Autorisé';
    SET v_raison_refus = NULL;
    
    -- [OPTIMISATION V5] L'INSERT est mutualisé ici.
    -- Un seul INSERT est exécuté à la fin de la procédure.
    INSERT INTO journal_acces_invites 
        (invite_id, membre_accompagnateur_id, club_id, date_passage, statut_acces, raison_refus)
    VALUES 
        (p_invite_id, p_membre_accompagnateur_id, p_club_id, NOW(), p_decision, v_raison_refus);
        
END main_invite_logic$$

DELIMITER ;