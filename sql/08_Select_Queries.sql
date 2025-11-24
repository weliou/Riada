-- -----------------------------------------------------
-- Script: 08_Select_Queries.sql (Version V4 - Optimisée DBA)
-- Objectif: Requêtes d'analyse complexes (JOIN, GROUP BY, Reporting V4)
-- -----------------------------------------------------
USE riada_db;

-- -----------------------------------------------------
-- REQUÊTE 1: Lister les membres avec contrat ACTIF
-- -----------------------------------------------------
-- Objectif: Annuaire simple des membres actifs.
-- Optimisation: Cette requête est couverte par les index:
-- 1. idx_contrat_membre_statut (pour le WHERE et le JOIN)
-- 2. idx_contrat_abonnement (pour le JOIN)
-- 3. idx_contrat_club (pour le JOIN)
-- 4. idx_membres_nom_prenom (pour l'ORDER BY)
-- -----------------------------------------------------
SELECT
    m.nom AS nom_membre,
    m.prenom AS prenom_membre,
    a.nom_offre AS abonnement,
    c.statut AS statut_contrat_actif, 
    cl.nom_club AS club_rattachement
FROM
    membres AS m
INNER JOIN
    contrats_adhesion AS c ON m.id = c.membre_id
INNER JOIN
    abonnements AS a ON c.abonnement_id = a.id
INNER JOIN
    clubs AS cl ON c.club_rattachement_id = cl.id
WHERE
    c.statut = 'Actif'
ORDER BY
    m.nom;

-- -----------------------------------------------------
-- REQUÊTE 2: Statut Complet de TOUS les membres
-- -----------------------------------------------------
-- Objectif: Dashboard "Vue 360" de tous les membres, 
--           y compris ceux n'ayant jamais eu de contrat.
-- Optimisation: Utilisation d'un CTE (MySQL 8+) avec ROW_NUMBER()
--           pour isoler le "dernier contrat" de chaque membre.
-- -----------------------------------------------------
WITH ContratRecent AS (
    SELECT 
        -- [OPTIMISATION] Éviter SELECT * dans les CTE
        c.id,
        c.membre_id,
        c.abonnement_id,
        c.club_rattachement_id,
        c.statut,
        c.date_debut,
        ROW_NUMBER() OVER(
            PARTITION BY c.membre_id 
            ORDER BY c.date_debut DESC, c.id DESC
        ) AS rn
    FROM 
        contrats_adhesion AS c
)
SELECT
    m.nom AS nom_membre,
    m.prenom AS prenom_membre,
    -- Utilisation de COALESCE pour gérer les LEFT JOIN (membres sans contrat)
    COALESCE(a.nom_offre, 'Sans Abonnement') AS offre_actuelle, 
    COALESCE(c_recent.statut, 'Inconnu/Jamais Adhéré') AS statut_contrat_logique,
    COALESCE(cl.nom_club, 'N/A') AS club_rattachement
FROM
    membres AS m
LEFT JOIN
    ContratRecent AS c_recent ON m.id = c_recent.membre_id AND c_recent.rn = 1
LEFT JOIN
    abonnements AS a ON c_recent.abonnement_id = a.id
LEFT JOIN
    clubs AS cl ON c_recent.club_rattachement_id = cl.id
ORDER BY
    m.nom;

-- -----------------------------------------------------
-- REQUÊTE 3: Taux de Défaut par Club
-- -----------------------------------------------------
-- Objectif: Reporting financier sur la santé des paiements par club.
-- Optimisation: Cette requête est couverte par les index:
-- 1. idx_facture_check_v2 (couvre le JOIN contrat_id et le WHERE statut_facture)
-- 2. idx_contrat_club (couvre le JOIN vers clubs)
-- -----------------------------------------------------
SELECT
    cl.nom_club,
    COUNT(f.id) AS total_factures_emises,
    -- Utilisation de SUM(CASE) pour un comptage conditionnel performant
    SUM(CASE WHEN f.statut_facture IN ('Impayée', 'Partiellement payée') THEN 1 ELSE 0 END) AS nombre_factures_en_souffrance,
    -- Calcul du ratio en évitant la division par zéro (implicite par COUNT)
    TRUNCATE(
        (SUM(CASE WHEN f.statut_facture IN ('Impayée', 'Partiellement payée') THEN 1 ELSE 0 END) / COUNT(f.id)) * 100
    , 2) AS taux_defaut_pourcent
FROM
    factures AS f
INNER JOIN
    contrats_adhesion AS c ON f.contrat_id = c.id
INNER JOIN
    clubs AS cl ON c.club_rattachement_id = cl.id
WHERE
    -- Exclut les factures non pertinentes pour le calcul du défaut
    f.statut_facture NOT IN ('Brouillon', 'Annulée')
GROUP BY
    cl.id, cl.nom_club -- GROUP BY sur l'ID (PK) est plus performant
ORDER BY
    taux_defaut_pourcent DESC;

-- -----------------------------------------------------
-- REQUÊTE 4: [CORRIGÉE V4] Fréquentation (Membres + Invités) - 30 Jours
-- -----------------------------------------------------
-- Objectif: Analyser l'affluence récente (30 derniers jours).
-- [OPTIMISATION V3] (Basée sur votre Bug Report #7)
-- Ajout d'un filtre WHERE sur date_passage. Sans cela,
-- la requête scanne des millions de lignes et est inutilisable.
-- -----------------------------------------------------

-- Partie 1: Logs des Membres
(SELECT
    cl.nom_club,
    'Membre' AS type_visiteur,
    ja.statut_acces,
    COUNT(ja.id) AS nombre_passages
FROM
    journal_acces AS ja
INNER JOIN
    clubs AS cl ON ja.club_id = cl.id
WHERE
    -- Filtre de date critique pour la performance
    ja.date_passage >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY
    cl.id, cl.nom_club, ja.statut_acces
)

UNION ALL

-- Partie 2: Logs des Invités
(SELECT
    cl.nom_club,
    'Invité (Pass Duo)' AS type_visiteur,
    jai.statut_acces, -- 'Autorisé' ou 'Refusé'
    COUNT(jai.id) AS nombre_passages
FROM
    journal_acces_invites AS jai
INNER JOIN
    clubs AS cl ON jai.club_id = cl.id
WHERE
    -- Filtre de date critique pour la performance
    jai.date_passage >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY
    cl.id, cl.nom_club, jai.statut_acces
)

ORDER BY
    nom_club, type_visiteur, nombre_passages DESC;