# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [5.0] - 2025-11-24

### ✨ Ajouté
- Documentation complète du projet (README.md)
- Script d'installation automatisé (install.sh)
- Fichier .gitignore adapté
- LICENSE MIT
- CHANGELOG pour le suivi des versions

### 🔧 Corrigé
- **Pass Duo**: Règle métier ajustée de 10 à 30 minutes pour la présence du membre accompagnateur
- **Trigger Invités**: Correction pour ne vérifier la limite QUE si le statut est 'Actif'
- **Performance**: Optimisation de l'index `idx_facture_check_v2` pour `sp_CheckAccess`
- **Performance**: Ajout de l'index `idx_journal_invite_check` pour `sp_CheckAccessInvite`

### 🎯 Optimisé
- Procédures stockées avec index composites ciblés
- Requêtes de fréquentation avec filtres temporels (30 jours)
- Audit système (10_System_Check.sql) ajusté aux 25 FK

---

## [4.1] - 2025-11

### 🔐 Sécurité
- Mise en place du principe de moindre privilège
- Utilisateur `portique_user` avec permissions EXECUTE uniquement
- Procédures en mode DEFINER pour isolation

### 🐛 Corrections
- Ajout de données de test pour cas limites
- Membre avec contrat gelé (Test 10)
- Invité banni (Test 11)
- Membre Premium impayé (Test 12 - Correction Faille V3)

---

## [4.0] - 2025-10

### ✨ Fonctionnalités Majeures
- **Pass Duo**: Système complet d'invités pour membres Premium
- Table `invites` avec gestion du statut (Actif/Banni)
- Table `journal_acces_invites` pour traçabilité
- Procédure `sp_CheckAccessInvite` avec 5 vérifications:
  1. Invité existe et non banni
  2. Âge minimum 16 ans
  3. Membre a l'option Pass Duo
  4. Membre sans impayés
  5. Membre présent dans le club (scan récent)

### 🔧 Modifications
- Trigger `trg_before_invite_insert_limite` pour limiter à 1 invité actif par membre
- Ajout de la colonne `acces_duo_permis` dans la table `abonnements`
- Extension des requêtes de fréquentation pour inclure les invités

---

## [3.0] - 2025-09

### 🔐 Sécurité Renforcée
- Création de l'utilisateur dédié `portique_user`
- Permissions restreintes (EXECUTE uniquement)
- Conformité au principe de moindre privilège
- Script `06_Security.sql` standardisé

### 📊 Rapports
- Requête avancée "Vue 360°" avec CTE
- Taux de défaut par club
- Optimisation des GROUP BY sur clés primaires

---

## [2.0] - 2025-08

### 💰 Facturation Automatisée
- Trigger `trg_after_paiement_insert`: Mise à jour automatique du statut des factures
- Trigger `trg_before_facture_insert`: Génération automatique des numéros de facture (FAC-YYYY-XXXXX)
- Colonnes calculées (GENERATED):
  - `montant_tva`
  - `montant_ttc`
  - `solde_restant`
  - `montant_ligne_ht`
  - `montant_ligne_ttc`

### 🔧 Améliorations
- Gestion des paiements partiels
- Statuts de facture enrichis (Brouillon, Émise, Payée, Partiellement payée, Impayée, Annulée)
- Tracking du `montant_deja_paye`
- Tolérance d'arrondi (0.01€) pour les calculs TTC

---

## [1.0] - 2025-07

### 🎉 Version Initiale
- Structure complète (19 tables)
- Gestion des clubs et membres
- Système d'abonnements (Basic, Comfort, Premium)
- Contrats d'adhésion
- Options modulaires
- Procédure `sp_CheckAccess` pour contrôle d'accès membres
- Vérifications:
  - Contrat actif
  - Date de fin non dépassée
  - Accès club limité (Basic)
  - Impayés en retard

### 📊 Fonctionnalités
- Journal d'accès complet
- Gestion des cours et réservations
- Suivi des équipements et maintenance
- Employés et instructeurs
- Index de performance
- 25 clés étrangères pour intégrité référentielle

---

## Format des Versions

- **[X.Y.Z]** - YYYY-MM-DD
  - **X (Majeur)**: Changements incompatibles avec les versions précédentes
  - **Y (Mineur)**: Ajout de fonctionnalités rétrocompatibles
  - **Z (Correctif)**: Corrections de bugs rétrocompatibles

### Types de Changements

- **✨ Ajouté**: Nouvelles fonctionnalités
- **🔧 Modifié**: Changements dans des fonctionnalités existantes
- **🐛 Corrigé**: Corrections de bugs
- **🗑️ Supprimé**: Fonctionnalités supprimées
- **🔐 Sécurité**: Corrections de vulnérabilités
- **🎯 Optimisé**: Améliorations de performance
- **📖 Documentation**: Modifications de documentation

---

## Prochaines Versions Prévues

### [5.1] - Prévu
- [ ] Dashboard web pour visualisation
- [ ] API REST pour intégration
- [ ] Export automatique des rapports (PDF)
- [ ] Notifications automatiques (emails/SMS)

### [6.0] - Prévu
- [ ] Multi-devises
- [ ] Gestion des promotions
- [ ] Programme de fidélité
- [ ] Analytics avancés (BI)

---

**Note**: Les dates sont au format YYYY-MM-DD (ISO 8601)
