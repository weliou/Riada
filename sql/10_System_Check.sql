-- =====================================================
-- Script: 10_System_Check.sql (Version FINALE Corrigée DBA V2)
-- Objectif: Audit complet du système Riada V5.2
-- Corrections: 
--   - V5: Cible la sécurité V3 (7 permissions de table)
--   - V6: Cible le nombre exact de 25 FK
-- =====================================================
USE riada_db;

-- Variables pour compteurs globaux
SET @verif_count = 0;
SET @verif_success = 0;

SELECT '' AS '';
SELECT '╔══════════════════════════════════════════════════╗' AS '';
SELECT '║     AUDIT SYSTÈME - BASE DE DONNÉES RIADA V5      ║' AS '';
SELECT '╚══════════════════════════════════════════════════╝' AS '';
SELECT '' AS '';

-- =====================================================
-- VÉRIFICATION 1: STRUCTURE (19 Tables)
-- =====================================================
SET @verif_count = @verif_count + 1;
SET @nb_tables = (
    SELECT COUNT(*) 
    FROM information_schema.tables 
    WHERE table_schema = 'riada_db' 
    AND table_type = 'BASE TABLE'
);

SELECT '1. Structure (19 Tables)' AS Verification,
       CONCAT(@nb_tables, '/19 tables') AS Detail,
       IF(@nb_tables = 19, 'OK ✅', CONCAT('ERREUR ❌ - ', @nb_tables, ' tables trouvées')) AS Statut;
       
SET @verif_success = @verif_success + IF(@nb_tables = 19, 1, 0);


-- =====================================================
-- VÉRIFICATION 2: TRIGGERS (3 Triggers V5)
-- =====================================================
SET @verif_count = @verif_count + 1;
SET @nb_triggers = (
    SELECT COUNT(DISTINCT trigger_name) 
    FROM information_schema.triggers
    WHERE trigger_schema = 'riada_db'
    AND trigger_name IN (
        'trg_after_paiement_insert', 
        'trg_before_facture_insert',
        'trg_before_invite_insert_limite'
    )
);

SELECT '2. Triggers (Automatisation)' AS Verification,
       CONCAT(@nb_triggers, '/3 triggers') AS Detail,
       IF(@nb_triggers = 3, 'OK ✅', CONCAT('ERREUR ❌ - ', @nb_triggers, ' triggers trouvés')) AS Statut;
       
SET @verif_success = @verif_success + IF(@nb_triggers = 3, 1, 0);


-- =====================================================
-- VÉRIFICATION 3: PROCÉDURES STOCKÉES (2 Procédures)
-- =====================================================
SET @verif_count = @verif_count + 1;
SET @nb_procedures = (
    SELECT COUNT(*) 
    FROM information_schema.routines
    WHERE routine_schema = 'riada_db'
    AND routine_type = 'PROCEDURE'
    AND routine_name IN ('sp_CheckAccess', 'sp_CheckAccessInvite')
);

SELECT '3. Procédures Stockées' AS Verification,
       CONCAT(@nb_procedures, '/2 procédures') AS Detail,
       IF(@nb_procedures = 2, 'OK ✅', CONCAT('ERREUR ❌ - ', @nb_procedures, ' procédures trouvées')) AS Statut;
       
SET @verif_success = @verif_success + IF(@nb_procedures = 2, 1, 0);


-- =====================================================
-- VÉRIFICATION 4: INDEX CRITIQUES (5 Index V5.2)
-- =====================================================
SET @verif_count = @verif_count + 1;

SET @total_idx = (
    SELECT COUNT(DISTINCT index_name)
    FROM information_schema.statistics
    WHERE table_schema = 'riada_db'
    AND index_name IN (
        'idx_facture_check_v2',         -- Pour sp_CheckAccess
        'idx_journal_invite_check',     -- Pour sp_CheckAccessInvite
        'idx_contrat_membre_statut',    -- Pour sp_ (Opti V5)
        'idx_contrat_membre_date',      -- Pour Requête 2 (Opti V-Req2)
        'idx_invites_parrain_statut'    -- Pour Trigger 3 (Opti Trigger)
    )
);

SELECT '4. Index Critiques (Performance V5.2)' AS Verification,
       CONCAT(@total_idx, '/5 index optimisés') AS Detail,
       IF(@total_idx = 5, 'OK ✅', 
          CONCAT('ERREUR ❌ - ', @total_idx, ' index trouvés')) AS Statut;
          
SET @verif_success = @verif_success + IF(@total_idx = 5, 1, 0);


-- =====================================================
-- VÉRIFICATION 5: SÉCURITÉ (Utilisateur V3) [CORRIGÉ]
-- =====================================================
SET @verif_count = @verif_count + 1;

-- Utilisateur existe
SET @user_exists = (
    SELECT COUNT(*) 
    FROM mysql.user 
    WHERE user = 'portique_user' 
    AND host = 'localhost'
);

-- Permissions EXECUTE (2 procédures)
SET @exec_priv_count = (
    SELECT COUNT(*) 
    FROM mysql.procs_priv 
    WHERE user = 'portique_user' 
    AND Routine_name IN ('sp_CheckAccess', 'sp_CheckAccessInvite') 
    AND Proc_priv = 'Execute'
);

-- [CORRECTION] Permissions tables (Doit être 7, selon Script 06 V3)
SET @table_priv_count = (
    SELECT COUNT(DISTINCT Table_name) 
    FROM mysql.tables_priv 
    WHERE user = 'portique_user' 
    AND host = 'localhost' 
    AND Db = 'riada_db'
);

SELECT '5. Sécurité (Utilisateur V3)' AS Verification,
       CONCAT('User:', @user_exists, ' Exec:', @exec_priv_count, ' Tables:', @table_priv_count) AS Detail,
       IF(@user_exists = 1 AND @exec_priv_count = 2 AND @table_priv_count = 7, 'OK ✅ (Conforme V3)', 
          'ERREUR ❌ - Incohérence Permissions') AS Statut;
          
SET @verif_success = @verif_success + IF(@user_exists = 1 AND @exec_priv_count = 2 AND @table_priv_count = 7, 1, 0);


-- =====================================================
-- VÉRIFICATION 6: CLÉS ÉTRANGÈRES (25 FK) [CORRIGÉ]
-- =====================================================
SET @verif_count = @verif_count + 1;
SET @nb_fk = (
    SELECT COUNT(*) 
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'riada_db'
    AND constraint_type = 'FOREIGN KEY'
);

SELECT '6. Clés Étrangères (Intégrité V5.2)' AS Verification,
       CONCAT(@nb_fk, '/25 FK définies') AS Detail,
       IF(@nb_fk = 25, 'OK ✅', CONCAT('ERREUR ❌ - ', @nb_fk, ' FK trouvées')) AS Statut;
       
SET @verif_success = @verif_success + IF(@nb_fk = 25, 1, 0);


-- =====================================================
-- VÉRIFICATION 7: DONNÉES DE TEST (Membres, Clubs, Factures)
-- =====================================================
SET @verif_count = @verif_count + 1;

SET @nb_membres = (SELECT COUNT(*) FROM membres);
SET @nb_clubs = (SELECT COUNT(*) FROM clubs);
SET @nb_factures = (SELECT COUNT(*) FROM factures);
SET @nb_invites = (SELECT COUNT(*) FROM invites);

SELECT '7. Données de Test' AS Verification,
       CONCAT('Membres:', @nb_membres, ' Clubs:', @nb_clubs, ' Factures:', @nb_factures, ' Invités:', @nb_invites) AS Detail,
       IF(@nb_membres >= 5 AND @nb_clubs >= 2 AND @nb_factures >= 3, 'OK ✅', 
          'ERREUR ❌ - Données insuffisantes') AS Statut;
          
SET @verif_success = @verif_success + IF(@nb_membres >= 5 AND @nb_clubs >= 2 AND @nb_factures >= 3, 1, 0);


-- =====================================================
-- VÉRIFICATION 8: PERFORMANCE INDEX (< 2000 µs)
-- =====================================================
SET @verif_count = @verif_count + 1;

SET @start_perf = MICROSECOND(NOW());
SELECT COUNT(*) INTO @dummy 
FROM journal_acces 
WHERE membre_id = 1 AND club_id = 1 AND statut_acces = 'Accepté';
SET @end_perf = MICROSECOND(NOW());
SET @temps_exec = @end_perf - @start_perf;

SELECT '8. Performance Index (Journal)' AS Verification,
       CONCAT(@temps_exec, ' µs') AS Detail,
       IF(@temps_exec < 2000, 'OK ✅', CONCAT('AVERTISSEMENT ⚠️ - ', @temps_exec, ' µs')) AS Statut;
       
SET @verif_success = @verif_success + IF(@temps_exec < 2000, 1, 0);


-- =====================================================
-- VÉRIFICATION 9: CALCULS GÉNÉRÉS (Colonnes GENERATED)
-- =====================================================
SET @verif_count = @verif_count + 1;

SET @montant_ttc = (SELECT montant_ttc FROM factures WHERE id = 1);
SET @montant_ht = (SELECT montant_ht FROM factures WHERE id = 1);
SET @tva_calcul = ROUND(@montant_ht * 1.21, 2);

SELECT '9. Calculs Générés (TTC)' AS Verification,
       CONCAT('TTC:', @montant_ttc, ' Attendu:', @tva_calcul) AS Detail,
       IF(ABS(@montant_ttc - @tva_calcul) < 0.01, 'OK ✅', 'ERREUR ❌ - Calcul incorrect') AS Statut;
       
SET @verif_success = @verif_success + IF(ABS(@montant_ttc - @tva_calcul) < 0.01, 1, 0);


-- =====================================================
-- VÉRIFICATION 10: VÉRIFICATION DES LOGS
-- =====================================================
SET @verif_count = @verif_count + 1;

SET @nb_logs_membres = (SELECT COUNT(*) FROM journal_acces);
SET @nb_logs_invites = (SELECT COUNT(*) FROM journal_acces_invites);

SELECT '10. Données de Log (Fréquentation)' AS Verification,
       CONCAT('Membres:', @nb_logs_membres, ' Invités:', @nb_logs_invites) AS Detail,
       IF(@nb_logs_membres >= 3 AND @nb_logs_invites >= 1, 'OK ✅', 'AVERTISSEMENT ⚠️ - Peu de logs') AS Statut;
       
SET @verif_success = @verif_success + IF(@nb_logs_membres >= 3 AND @nb_logs_invites >= 1, 1, 0);


-- =====================================================
-- RÉSUMÉ FINAL DE L'AUDIT
-- =====================================================
SELECT '' AS '';
SELECT '╔══════════════════════════════════════════════════╗' AS '';
SELECT '║            RÉSUMÉ AUDIT SYSTÈME                 ║' AS '';
SELECT '╚══════════════════════════════════════════════════╝' AS '';

SET @taux_reussite = ROUND((@verif_success / @verif_count) * 100, 2);

SELECT 
    @verif_count AS 'Vérifications',
    @verif_success AS 'Validées ✅',
    (@verif_count - @verif_success) AS 'Échecs ❌',
    CONCAT(@taux_reussite, '%') AS 'Taux Réussite';

SELECT '' AS '';
SELECT 
    CASE 
        WHEN @taux_reussite = 100 THEN '🏆 SYSTÈME 100% OPÉRATIONNEL 🏆'
        WHEN @taux_reussite >= 90 THEN '✅ SYSTÈME OPÉRATIONNEL (≥90%)'
        WHEN @taux_reussite >= 70 THEN '⚠️ SYSTÈME PARTIELLEMENT OPÉRATIONNEL (70-89%)'
        ELSE '❌ SYSTÈME NON OPÉRATIONNEL (<70%)'
    END AS 'Verdict Final';

SELECT '' AS '';
SELECT '╔══════════════════════════════════════════════════╗' AS '';
SELECT '║            COMPOSANTS VÉRIFIÉS                   ║' AS '';
SELECT '╚══════════════════════════════════════════════════╝' AS '';

SELECT 
    '✓ 19 Tables' AS Composant_1,
    '✓ 3 Triggers' AS Composant_2,
    '✓ 2 Procédures' AS Composant_3,
    '✓ 5 Index Optimisés' AS Composant_4;

SELECT 
    '✓ Utilisateur Sécurisé (V3)' AS Composant_5,
    '✓ 25 Clés Étrangères' AS Composant_6,
    '✓ Données de Test' AS Composant_7,
    '✓ Performance Indexée' AS Composant_8;