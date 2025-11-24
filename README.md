# 🏋️ Riada - Système de Gestion de Salles de Sport

![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue.svg)
![Version](https://img.shields.io/badge/Version-5.0-green.svg)
![License](https://img.shields.io/badge/License-Private-red.svg)

## 📋 Description

**Riada** est une base de données MySQL complète et optimisée pour la gestion d'un réseau de salles de sport. Elle gère l'ensemble des opérations : membres, abonnements, facturation, contrôle d'accès, cours collectifs, maintenance des équipements et système de Pass Duo.

## 🎯 Fonctionnalités Principales

### ✅ Gestion des Membres
- Profils complets avec historique
- Objectifs personnels et données RGPD
- Tracking de la dernière visite
- Système de parrainage

### 💳 Gestion des Abonnements
- 3 formules : Basic, Comfort, Premium
- Options modulaires (coaching, massages, etc.)
- Contrats à durée déterminée/indéterminée
- Gestion du gel et résiliation

### 💰 Facturation Automatisée
- Génération automatique des numéros de facture
- Calcul automatique TTC/TVA
- Gestion des paiements partiels
- Suivi des impayés
- Triggers pour mise à jour automatique

### 🚪 Contrôle d'Accès Intelligent
- Vérification en temps réel via procédures stockées
- Blocage automatique en cas d'impayé
- Restrictions selon l'abonnement
- Logs détaillés de tous les passages

### 👥 Pass Duo (Système d'Invités)
- 1 invité permanent par membre Premium
- Vérification d'âge (minimum 16 ans)
- Contrôle de présence du membre accompagnateur
- Gestion des invités bannis

### 📊 Cours & Réservations
- Planning des sessions
- Gestion des capacités
- Réservations avec liste d'attente
- Statistiques de fréquentation

### 🔧 Maintenance
- Suivi des équipements
- Tickets de maintenance
- Historique des réparations
- Priorisation des interventions

## 🏗️ Architecture

### Structure (19 Tables)

```
┌─────────────────────────────────────────────────┐
│                 CLUBS & STAFF                    │
├─────────────────────────────────────────────────┤
│ • clubs                                          │
│ • employes                                       │
│ • equipements                                    │
│ • maintenance                                    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│            MEMBRES & ABONNEMENTS                 │
├─────────────────────────────────────────────────┤
│ • membres                                        │
│ • abonnements                                    │
│ • options_services                               │
│ • contrats_adhesion                              │
│ • abonnement_options (N-N)                       │
│ • options_contrat (N-N)                          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│              FACTURATION                         │
├─────────────────────────────────────────────────┤
│ • factures                                       │
│ • lignes_factures                                │
│ • paiements                                      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│            CONTRÔLE D'ACCÈS                      │
├─────────────────────────────────────────────────┤
│ • journal_acces                                  │
│ • invites                                        │
│ • journal_acces_invites                          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│              COURS & ACTIVITÉS                   │
├─────────────────────────────────────────────────┤
│ • cours                                          │
│ • sessions_cours                                 │
│ • reservations (N-N)                             │
└─────────────────────────────────────────────────┘
```

### Composants Avancés

#### 🔧 Procédures Stockées (2)
- `sp_CheckAccess` - Vérification d'accès membre
- `sp_CheckAccessInvite` - Vérification d'accès invité (Pass Duo)

#### ⚡ Triggers (3)
- `trg_after_paiement_insert` - Mise à jour automatique des factures
- `trg_before_facture_insert` - Génération numéro de facture
- `trg_before_invite_insert_limite` - Limitation invités actifs

#### 📈 Index Optimisés (5 Critiques)
- `idx_facture_check_v2` - Performance procédure CheckAccess
- `idx_journal_invite_check` - Performance procédure CheckAccessInvite
- `idx_contrat_membre_statut` - Optimisation jointures
- `idx_contrat_membre_date` - Requêtes temporelles
- `idx_invites_parrain_statut` - Performance trigger

#### 🔐 Sécurité
- Utilisateur dédié `portique_user` avec principe de moindre privilège
- Permissions EXECUTE uniquement sur les procédures
- Conformité RGPD (consentement, marketing)

## 🚀 Installation

### Prérequis
- MySQL 8.0+ (requis pour CTE, WINDOW functions)
- Accès root pour la création initiale
- Client MySQL (CLI, Workbench, etc.)

### Installation Complète

```bash
# 1. Cloner le repository
git clone https://github.com/weliou/Riada.git
cd Riada

# 2. Se connecter à MySQL en tant que root
mysql -u root -p

# 3. Exécuter les scripts dans l'ordre
mysql -u root -p < sql/01_Create_Database.sql
mysql -u root -p < sql/02_Create_Tables.sql
mysql -u root -p < sql/03_Indexes.sql
mysql -u root -p < sql/04_Procedures.sql
mysql -u root -p < sql/05_Triggers.sql
mysql -u root -p < sql/06_Security.sql
mysql -u root -p < sql/07_Insert_All_Data.sql

# 4. Vérifier l'installation
mysql -u root -p < sql/10_System_Check.sql
```

### Installation Rapide (Script Unique)

```bash
# Exécuter tous les scripts en une commande
cat sql/01_*.sql sql/02_*.sql sql/03_*.sql sql/04_*.sql sql/05_*.sql sql/06_*.sql sql/07_*.sql | mysql -u root -p
```

## 📊 Utilisation

### Exemples de Requêtes

#### 1. Vérifier l'accès d'un membre
```sql
CALL sp_CheckAccess(1, 1, @decision);
SELECT @decision; -- 'Accepté' ou 'Refusé'
```

#### 2. Vérifier l'accès d'un invité (Pass Duo)
```sql
CALL sp_CheckAccessInvite(1, 1, 1, @decision);
SELECT @decision; -- 'Autorisé' ou 'Refusé'
```

#### 3. Liste des membres actifs
```sql
SELECT 
    m.nom, 
    m.prenom, 
    a.nom_offre, 
    c.statut
FROM membres m
JOIN contrats_adhesion c ON m.id = c.membre_id
JOIN abonnements a ON c.abonnement_id = a.id
WHERE c.statut = 'Actif';
```

#### 4. Taux de défaut par club
```sql
SELECT 
    cl.nom_club,
    COUNT(f.id) AS total_factures,
    SUM(CASE WHEN f.statut_facture IN ('Impayée', 'Partiellement payée') 
        THEN 1 ELSE 0 END) AS impayees,
    ROUND((SUM(CASE WHEN f.statut_facture IN ('Impayée', 'Partiellement payée') 
        THEN 1 ELSE 0 END) / COUNT(f.id)) * 100, 2) AS taux_defaut
FROM factures f
JOIN contrats_adhesion c ON f.contrat_id = c.id
JOIN clubs cl ON c.club_rattachement_id = cl.id
GROUP BY cl.id;
```

### Requêtes d'Analyse

Consultez le fichier `sql/08_Select_Queries.sql` pour des exemples avancés :
- Vue 360° des membres
- Fréquentation (membres + invités)
- Reporting financier
- Analyses statistiques

## 🧪 Tests

### Scénarios de Test (09_Tests.sql)

Le système inclut des tests complets couvrant :
- ✅ Accès membres (contrat actif, expiré, gelé)
- ✅ Blocage pour impayés
- ✅ Restrictions Basic (club limité)
- ✅ Pass Duo Premium
- ✅ Vérification d'âge invités (16 ans minimum)
- ✅ Présence accompagnateur (30 minutes)
- ✅ Limite 1 invité actif par membre
- ✅ Invités bannis

### Audit Système (10_System_Check.sql)

Script d'audit automatisé vérifiant :
- 🔍 19 tables créées
- 🔍 3 triggers actifs
- 🔍 2 procédures stockées
- 🔍 5 index critiques
- 🔍 Utilisateur sécurisé
- 🔍 25 clés étrangères
- 🔍 Données de test
- 🔍 Performance (<2000 µs)
- 🔍 Calculs générés (TTC)
- 🔍 Logs de fréquentation

**Résultat attendu :** ✅ 10/10 vérifications = 100% opérationnel 🏆

## 📈 Performance

### Optimisations Appliquées

1. **Index Composites** - Couvrent les requêtes critiques
2. **Colonnes Générées** - Calculs TTC/TVA précalculés
3. **Procédures DEFINER** - Sécurité + Performance
4. **CTE & Window Functions** - Requêtes complexes optimisées
5. **Filtres Temporels** - Index sur date_passage (30 jours)

### Benchmarks

| Opération | Temps Moyen | Index Utilisé |
|-----------|-------------|---------------|
| CheckAccess (Membre) | <500 µs | idx_facture_check_v2 |
| CheckAccess (Invité) | <800 µs | idx_journal_invite_check |
| Requête Fréquentation | <1500 µs | idx_journal_date |
| Audit Système Complet | ~2000 µs | Multiples |

## 🔐 Sécurité

### Principe de Moindre Privilège

L'utilisateur `portique_user` dispose uniquement de :
- ✅ EXECUTE sur `sp_CheckAccess`
- ✅ EXECUTE sur `sp_CheckAccessInvite`
- ❌ Aucun accès direct aux tables

Les procédures s'exécutent en tant que `DEFINER` (root), garantissant :
- Isolation des permissions
- Traçabilité des actions
- Impossibilité de contournement

### Conformité RGPD

- ✅ Consentement tracé (`date_consentement_rgpd`)
- ✅ Marketing opt-in (`consentement_marketing`)
- ✅ Données minimales
- ✅ Certificat médical (conformité légale)

## 📁 Structure du Projet

```
Riada/
├── README.md                    # Ce fichier
├── .gitignore                   # Fichiers à exclure
├── LICENSE                      # Licence du projet
├── docs/
│   ├── SCHEMA.md               # Schéma détaillé des tables
│   ├── CHANGELOG.md            # Historique des versions
│   └── API.md                  # Documentation des procédures
├── sql/
│   ├── 01_Create_Database.sql  # Création DB
│   ├── 02_Create_Tables.sql    # Structure (19 tables)
│   ├── 03_Indexes.sql          # Index + FK
│   ├── 04_Procedures.sql       # Procédures stockées
│   ├── 05_Triggers.sql         # Automatisations
│   ├── 06_Security.sql         # Utilisateur sécurisé
│   ├── 07_Insert_All_Data.sql  # Données de test
│   ├── 08_Select_Queries.sql   # Exemples d'analyse
│   ├── 09_Tests.sql            # Scénarios de test
│   └── 10_System_Check.sql     # Audit automatisé
└── scripts/
    ├── install.sh              # Installation automatique
    ├── backup.sh               # Sauvegarde automatisée
    └── reset.sh                # Réinitialisation complète
```

## 🔄 Versioning

### Version Actuelle : 5.0

#### Historique

- **V5.0** (Actuelle)
  - Correction règle métier Pass Duo (30 min au lieu de 10 min)
  - Optimisation index composite `idx_facture_check_v2`
  - Correction trigger limite invités (vérifie statut 'Actif')
  - 25 FK complètes
  
- **V4.0**
  - Ajout système Pass Duo complet
  - Procédure `sp_CheckAccessInvite`
  - Table `invites` et `journal_acces_invites`
  
- **V3.0**
  - Sécurité renforcée (utilisateur dédié)
  - Principe de moindre privilège
  
- **V2.0**
  - Facturation automatisée
  - Triggers de mise à jour
  
- **V1.0**
  - Structure de base
  - Contrôle d'accès membres

## 🤝 Contributions

Ce projet est actuellement privé. Pour toute suggestion ou amélioration :

1. Créer une issue détaillée
2. Proposer une pull request
3. Documenter les changements

### Standards de Code

- Utiliser les conventions de nommage existantes
- Commenter les modifications complexes
- Tester avec `10_System_Check.sql`
- Versionner les changements (V5.1, V5.2...)

## 📞 Support

Pour toute question ou problème :
- 📧 Email : [Votre email]
- 💬 GitHub Issues : [Créer une issue](https://github.com/weliou/Riada/issues)

## 📝 License

© 2025 Riada. Tous droits réservés.

Ce projet est privé et propriétaire. Toute utilisation, reproduction ou distribution nécessite une autorisation explicite.

## 🙏 Remerciements

Développé avec ❤️ pour optimiser la gestion des salles de sport.

Technologies utilisées :
- MySQL 8.0+
- InnoDB Engine
- Procédures Stockées
- Triggers
- CTE & Window Functions

---

**🏆 Système 100% Opérationnel - V5.0**

*Dernière mise à jour : Novembre 2025*
