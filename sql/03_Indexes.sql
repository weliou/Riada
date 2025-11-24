-- -----------------------------------------------------
-- Script: 03_Indexes_And_Constraints_V5.0.sql
-- Objectif: Appliquer TOUS les index secondaires et
--           contraintes FK après le chargement des données.
-- -----------------------------------------------------
USE riada_db;

-- -----------------------------------------------------
-- PARTIE 1: CRÉATION DES INDEX DE PERFORMANCE
-- -----------------------------------------------------

-- Table 1: clubs
CREATE INDEX idx_clubs_ville ON clubs(adresse_ville);

-- Table 2: membres
CREATE INDEX idx_membres_ville ON membres(adresse_ville);
CREATE INDEX idx_membres_nom_prenom ON membres(nom, prenom);
CREATE INDEX idx_membres_derniere_visite ON membres(derniere_visite);

-- Table 4: contrats_adhesion
CREATE INDEX idx_contrat_membre_statut ON contrats_adhesion(membre_id, statut);
CREATE INDEX idx_contrat_membre_date ON contrats_adhesion(membre_id, date_debut DESC);

CREATE INDEX idx_contrat_club ON contrats_adhesion(club_rattachement_id);
CREATE INDEX idx_contrat_abonnement ON contrats_adhesion(abonnement_id);
CREATE INDEX idx_contrat_statut_date ON contrats_adhesion(statut, date_debut, date_fin);
CREATE INDEX idx_contrat_statut_abonnement ON contrats_adhesion(statut, abonnement_id); 

-- Table 6: abonnement_options
CREATE INDEX idx_ao_option ON abonnement_options(option_id);

-- Table 7: options_contrat
CREATE INDEX idx_oc_option ON options_contrat(option_id);

-- Table 8: factures
CREATE INDEX idx_facture_check_v2 ON factures(contrat_id, statut_facture, date_echeance); -- Patch V2 (le meilleur)
CREATE INDEX idx_factures_statut_echeance ON factures(statut_facture, date_echeance);
CREATE INDEX idx_factures_periode ON factures(periode_debut, periode_fin);

-- Table 9: lignes_factures
CREATE INDEX idx_lf_facture ON lignes_factures(facture_id);
CREATE INDEX idx_lf_abonnement ON lignes_factures(abonnement_id);
CREATE INDEX idx_lf_option ON lignes_factures(option_id);

-- Table 10: paiements
CREATE INDEX idx_paiements_facture ON paiements(facture_id);
CREATE INDEX idx_paiements_statut_type ON paiements(statut_paiement, type_paiement);

-- Table 11: journal_acces
CREATE INDEX idx_journal_date ON journal_acces(date_passage);
CREATE INDEX idx_journal_club ON journal_acces(club_id);
CREATE INDEX idx_journal_invite_check ON journal_acces(membre_id, club_id, statut_acces, date_passage); -- Patch V7 (le meilleur)

-- Table 12: cours
CREATE INDEX idx_cours_type_difficulce ON cours(type_activite, niveau_difficulte);

-- Table 13: employes
CREATE INDEX idx_employes_club ON employes(club_id);
CREATE INDEX idx_employes_role ON employes(role);

-- Table 14: sessions_cours
CREATE INDEX idx_sc_cours ON sessions_cours(cours_id);
CREATE INDEX idx_sc_instructeur ON sessions_cours(instructeur_id);
CREATE INDEX idx_sc_club ON sessions_cours(club_id);
CREATE INDEX idx_sc_heure_debut ON sessions_cours(heure_debut);

-- Table 15: reservations
CREATE INDEX idx_res_session ON reservations(session_id);
CREATE INDEX idx_res_date ON reservations(date_reservation);

-- Table 16: equipements
CREATE INDEX idx_equipements_club ON equipements(club_id);
CREATE INDEX idx_equipements_statut ON equipements(statut_equipement);

-- Table 17: maintenance
CREATE INDEX idx_maint_equipement ON maintenance(equipement_id);
CREATE INDEX idx_maint_technicien ON maintenance(technicien_id);
CREATE INDEX idx_maint_statut_priorite ON maintenance(statut_maintenance, priorite);

-- Table 18: invites
CREATE INDEX idx_invites_parrain_statut ON invites(membre_parrain_id, statut);
CREATE INDEX idx_invites_nom_prenom ON invites(nom, prenom);

-- Table 19: journal_acces_invites
CREATE INDEX idx_log_invite ON journal_acces_invites(invite_id);
CREATE INDEX idx_log_membre ON journal_acces_invites(membre_accompagnateur_id);
CREATE INDEX idx_log_club ON journal_acces_invites(club_id);
CREATE INDEX idx_log_date_passage ON journal_acces_invites(date_passage);


-- -----------------------------------------------------
-- PARTIE 2: CRÉATION DES CONTRAINTES (FOREIGN KEYS)
-- -----------------------------------------------------

ALTER TABLE contrats_adhesion
    ADD CONSTRAINT fk_ca_membres FOREIGN KEY (membre_id) REFERENCES membres(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_ca_abonnements FOREIGN KEY (abonnement_id) REFERENCES abonnements(id),
    ADD CONSTRAINT fk_ca_clubs FOREIGN KEY (club_rattachement_id) REFERENCES clubs(id);

ALTER TABLE abonnement_options
    ADD CONSTRAINT fk_ao_abonnements FOREIGN KEY (abonnement_id) REFERENCES abonnements(id),
    ADD CONSTRAINT fk_ao_options FOREIGN KEY (option_id) REFERENCES options_services(id);

ALTER TABLE options_contrat
    ADD CONSTRAINT fk_oc_contrats FOREIGN KEY (contrat_id) REFERENCES contrats_adhesion(id),
    ADD CONSTRAINT fk_oc_options FOREIGN KEY (option_id) REFERENCES options_services(id);

ALTER TABLE factures
    ADD CONSTRAINT fk_factures_contrats FOREIGN KEY (contrat_id) REFERENCES contrats_adhesion(id) ON DELETE SET NULL;

ALTER TABLE lignes_factures
    ADD CONSTRAINT fk_lf_factures FOREIGN KEY (facture_id) REFERENCES factures(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_lf_abonnements FOREIGN KEY (abonnement_id) REFERENCES abonnements(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_lf_options FOREIGN KEY (option_id) REFERENCES options_services(id) ON DELETE SET NULL;

ALTER TABLE paiements
    ADD CONSTRAINT fk_paiements_factures FOREIGN KEY (facture_id) REFERENCES factures(id) ON DELETE RESTRICT;

ALTER TABLE journal_acces
    ADD CONSTRAINT fk_ja_clubs FOREIGN KEY (club_id) REFERENCES clubs(id);

ALTER TABLE employes
    ADD CONSTRAINT fk_employes_clubs FOREIGN KEY (club_id) REFERENCES clubs(id);

ALTER TABLE sessions_cours
    ADD CONSTRAINT fk_sc_cours FOREIGN KEY (cours_id) REFERENCES cours(id),
    ADD CONSTRAINT fk_sc_employes FOREIGN KEY (instructeur_id) REFERENCES employes(id),
    ADD CONSTRAINT fk_sc_clubs FOREIGN KEY (club_id) REFERENCES clubs(id);

ALTER TABLE reservations
    ADD CONSTRAINT fk_res_membres FOREIGN KEY (membre_id) REFERENCES membres(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_res_sessions FOREIGN KEY (session_id) REFERENCES sessions_cours(id);

ALTER TABLE equipements
    ADD CONSTRAINT fk_equipements_clubs FOREIGN KEY (club_id) REFERENCES clubs(id);

ALTER TABLE maintenance
    ADD CONSTRAINT fk_maint_equipements FOREIGN KEY (equipement_id) REFERENCES equipements(id),
    ADD CONSTRAINT fk_maint_employes FOREIGN KEY (technicien_id) REFERENCES employes(id);

ALTER TABLE invites
    ADD CONSTRAINT fk_invites_membres FOREIGN KEY (membre_parrain_id) REFERENCES membres(id) ON DELETE SET NULL;

ALTER TABLE journal_acces_invites
    ADD CONSTRAINT fk_log_invites_membres FOREIGN KEY (membre_accompagnateur_id) REFERENCES membres(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_log_invites_clubs FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE RESTRICT;


SELECT 'Index V5.0 (Index + FK) appliqués.' AS Status;