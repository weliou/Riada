-- -----------------------------------------------------
-- Script: 05_Triggers.sql (Version V5 - Standardisée DBA)
-- -----------------------------------------------------
USE riada_db;

DELIMITER $$

-- =====================================================
-- TRIGGERS V2 (FACTURATION)
-- =====================================================

-- TRIGGER 1: Mettre à jour la facture après un paiement
DROP TRIGGER IF EXISTS trg_after_paiement_insert$$
CREATE TRIGGER trg_after_paiement_insert
AFTER INSERT ON paiements
FOR EACH ROW
BEGIN
    DECLARE v_montant_ttc DECIMAL(7,2);
    DECLARE v_montant_paye_precedent DECIMAL(7,2);
    DECLARE v_solde_calcule DECIMAL(7,2);
    
    IF NEW.statut_paiement = 'Réussi' THEN
        SELECT montant_ttc, montant_deja_paye 
        INTO v_montant_ttc, v_montant_paye_precedent
        FROM factures
        WHERE id = NEW.facture_id;

        SET v_solde_calcule = v_montant_ttc - (v_montant_paye_precedent + NEW.montant_paye);
        
        -- Vérification avec une tolérance pour les erreurs d'arrondi
        IF v_solde_calcule <= 0.01 THEN 
            UPDATE factures
            SET montant_deja_paye = montant_deja_paye + NEW.montant_paye,
                statut_facture = 'Payée',
                date_paiement_complet = NOW()
            WHERE id = NEW.facture_id;
        ELSE
            UPDATE factures
            SET montant_deja_paye = montant_deja_paye + NEW.montant_paye,
                statut_facture = 'Partiellement payée'
            WHERE id = NEW.facture_id;
        END IF;
    
    ELSEIF NEW.statut_paiement = 'Échoué' THEN
        -- Ne pas mettre à jour si la facture est déjà marquée comme payée
        UPDATE factures
        SET statut_facture = 'Impayée'
        WHERE id = NEW.facture_id
          AND statut_facture <> 'Payée';
    END IF;
END$$

-- TRIGGER 2: Générer un numéro de facture unique
DROP TRIGGER IF EXISTS trg_before_facture_insert$$
CREATE TRIGGER trg_before_facture_insert
BEFORE INSERT ON factures
FOR EACH ROW
BEGIN
    DECLARE v_annee INT;
    DECLARE v_dernier_numero INT;
    DECLARE v_nouveau_numero VARCHAR(50);
    
    IF NEW.numero_facture IS NULL OR NEW.numero_facture = '' THEN
        SET v_annee = YEAR(NEW.date_emission);
        
        -- Recherche performante (utilise l'index UNIQUE sur numero_facture)
        SELECT COALESCE(MAX(CAST(SUBSTRING(numero_facture, 10) AS UNSIGNED)), 0) 
        INTO v_dernier_numero
        FROM factures
        WHERE numero_facture LIKE CONCAT('FAC-', v_annee, '-%');
        
        SET v_nouveau_numero = CONCAT('FAC-', v_annee, '-', LPAD(v_dernier_numero + 1, 5, '0'));
        SET NEW.numero_facture = v_nouveau_numero;
    END IF;
END$$

-- =====================================================
-- TRIGGERS V3 (PASS DUO)
-- =====================================================

-- -----------------------------------------------------
-- TRIGGER 3: Limiter le nombre d'invités (CORRIGÉ V4)
-- -----------------------------------------------------
DROP TRIGGER IF EXISTS trg_before_invite_insert_limite$$

CREATE TRIGGER trg_before_invite_insert_limite
BEFORE INSERT ON invites
FOR EACH ROW
BEGIN
    DECLARE v_nb_invites_permanents INT;
    
    -- [CORRECTION] Ne vérifier la limite QUE si le NOUVEL invité est 'Actif'
    IF NEW.membre_parrain_id IS NOT NULL AND NEW.statut = 'Actif' THEN
    
        -- Cette requête doit être optimisée par un index composite
        SELECT COUNT(*) INTO v_nb_invites_permanents
        FROM invites
        WHERE membre_parrain_id = NEW.membre_parrain_id
          AND statut = 'Actif';
        
        -- Si le membre a déjà 1 (ou plus) invité Actif, on bloque.
        IF v_nb_invites_permanents >= 1 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ce membre a déjà atteint sa limite d''invités actifs.';
        END IF;
    END IF;
    -- Si NEW.statut = 'Banni', le trigger ne bloque pas l'insertion.
END$$

DELIMITER ;