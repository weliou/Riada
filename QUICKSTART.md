# 🚀 Guide de Démarrage Rapide - Riada

Guide pour installer et tester **Riada** en moins de 5 minutes.

---

## ⚡ Installation Express

### Prérequis
- MySQL 8.0+ installé
- Accès root MySQL
- Git installé

### 1️⃣ Cloner le Repository

```bash
git clone https://github.com/weliou/Riada.git
cd Riada
```

### 2️⃣ Installation Automatique

```bash
# Rendre le script exécutable
chmod +x scripts/install.sh

# Lancer l'installation
./scripts/install.sh
```

Le script va :
- ✅ Vérifier MySQL
- ✅ Créer la base de données
- ✅ Créer 19 tables
- ✅ Ajouter index et contraintes
- ✅ Créer 2 procédures + 3 triggers
- ✅ Configurer l'utilisateur sécurisé
- ✅ (Optionnel) Charger données de test
- ✅ (Optionnel) Exécuter l'audit système

**Résultat attendu :** 🏆 Système 100% Opérationnel

---

## 🧪 Test Rapide

### Se Connecter

```bash
mysql -u root -p riada_db
```

### Test 1 : Vérifier l'Accès d'un Membre

```sql
-- Marie (Membre 1) avec Premium et facture payée
CALL sp_CheckAccess(1, 1, @decision);
SELECT @decision;
-- Résultat attendu: 'Accepté' ✅
```

### Test 2 : Vérifier un Invité (Pass Duo)

```sql
-- Thomas (Invité 1) accompagné par Marie (Membre 1)
CALL sp_CheckAccessInvite(1, 1, 1, @decision);
SELECT @decision;
-- Résultat attendu: 'Autorisé' ✅
```

### Test 3 : Lister les Membres Actifs

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

---

## 📊 Dashboard Rapide

### Vue d'Ensemble du Système

```sql
-- Statistiques générales
SELECT 
    (SELECT COUNT(*) FROM membres) AS total_membres,
    (SELECT COUNT(*) FROM membres WHERE id IN (
        SELECT membre_id FROM contrats_adhesion WHERE statut = 'Actif'
    )) AS membres_actifs,
    (SELECT COUNT(*) FROM clubs) AS total_clubs,
    (SELECT COUNT(*) FROM factures WHERE statut_facture = 'Impayée') AS factures_impayees;
```

### Fréquentation du Jour

```sql
SELECT 
    c.nom_club,
    COUNT(DISTINCT ja.membre_id) AS membres_venus_aujourdhui
FROM journal_acces ja
JOIN clubs c ON ja.club_id = c.id
WHERE DATE(ja.date_passage) = CURDATE()
  AND ja.statut_acces = 'Accepté'
GROUP BY c.id;
```

### Top 5 Cours Populaires

```sql
SELECT 
    c.nom_cours,
    COUNT(r.membre_id) AS total_reservations
FROM reservations r
JOIN sessions_cours sc ON r.session_id = sc.id
JOIN cours c ON sc.cours_id = c.id
WHERE r.statut_reservation = 'Confirmée'
GROUP BY c.id
ORDER BY total_reservations DESC
LIMIT 5;
```

---

## 🔧 Commandes Utiles

### Audit Système

```bash
mysql -u root -p < sql/10_System_Check.sql
```

**Vérifications :**
- ✅ 19 tables
- ✅ 3 triggers
- ✅ 2 procédures
- ✅ 5 index critiques
- ✅ Utilisateur sécurisé
- ✅ 25 clés étrangères
- ✅ Données de test
- ✅ Performance (<2000 µs)
- ✅ Calculs générés (TTC)
- ✅ Logs de fréquentation

### Requêtes d'Analyse Avancées

```bash
mysql -u root -p < sql/08_Select_Queries.sql
```

**Inclus :**
- Vue 360° des membres
- Taux de défaut par club
- Fréquentation (membres + invités) 30 jours
- Analyses statistiques

### Tests Métier Complets

```bash
mysql -u root -p < sql/09_Tests.sql
```

**Scénarios testés :**
- Accès membres (actif, expiré, gelé)
- Blocage impayés
- Restrictions Basic
- Pass Duo Premium
- Vérification âge invités
- Présence accompagnateur
- Limite invités actifs
- Invités bannis

---

## 🎯 Scénarios d'Usage

### Scénario 1 : Nouveau Membre

```sql
-- 1. Créer le membre
INSERT INTO membres (nom, prenom, email, date_naissance, telephone_mobile, 
                     adresse_rue, adresse_ville, adresse_code_postal)
VALUES ('Nouveau', 'Membre', 'nouveau@email.com', '1990-01-01', '+32470000000',
        'Rue Test 1', 'Bruxelles', '1000');

SET @nouveau_membre_id = LAST_INSERT_ID();

-- 2. Créer le contrat
INSERT INTO contrats_adhesion (membre_id, abonnement_id, club_rattachement_id, 
                               date_debut, type_contrat, statut)
VALUES (@nouveau_membre_id, 2, 1, CURDATE(), 'Durée Déterminée', 'Actif');

-- 3. Tester l'accès
CALL sp_CheckAccess(@nouveau_membre_id, 1, @decision);
SELECT @decision; -- 'Accepté' ✅
```

### Scénario 2 : Ajouter un Invité (Pass Duo)

```sql
-- Le membre doit avoir Premium (abonnement_id = 3)
-- 1. Créer l'invité
INSERT INTO invites (membre_parrain_id, nom, prenom, date_naissance, email)
VALUES (1, 'Invite', 'Test', '1995-05-05', 'invite.test@email.com');

SET @invite_id = LAST_INSERT_ID();

-- 2. Le membre Marie doit scanner d'abord
-- (Simulé dans les données de test - ID log 1)

-- 3. Tester l'accès invité
CALL sp_CheckAccessInvite(@invite_id, 1, 1, @decision);
SELECT @decision; -- 'Autorisé' ✅
```

### Scénario 3 : Réserver un Cours

```sql
-- 1. Voir les cours disponibles
SELECT 
    sc.id AS session_id,
    c.nom_cours,
    sc.heure_debut,
    cl.nom_club,
    c.capacite_max
FROM sessions_cours sc
JOIN cours c ON sc.cours_id = c.id
JOIN clubs cl ON sc.club_id = cl.id
WHERE sc.heure_debut > NOW();

-- 2. Réserver
INSERT INTO reservations (membre_id, session_id, statut_reservation)
VALUES (1, 1, 'Confirmée');

-- 3. Vérifier la réservation
SELECT 
    m.nom,
    m.prenom,
    c.nom_cours,
    sc.heure_debut,
    r.statut_reservation
FROM reservations r
JOIN membres m ON r.membre_id = m.id
JOIN sessions_cours sc ON r.session_id = sc.id
JOIN cours c ON sc.cours_id = c.id
WHERE r.membre_id = 1;
```

---

## 🛠️ Dépannage Rapide

### Erreur : "Access denied for user"

```bash
# Vérifier que l'utilisateur existe
mysql -u root -p -e "SELECT user, host FROM mysql.user WHERE user='portique_user';"

# Réappliquer les permissions
mysql -u root -p < sql/06_Security.sql
```

### Erreur : "Unknown database 'riada_db'"

```bash
# Recréer la base
mysql -u root -p < sql/01_Create_Database.sql
```

### Performance Lente

```sql
-- Vérifier les index
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    CARDINALITY
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'riada_db'
ORDER BY TABLE_NAME, INDEX_NAME;

-- Réappliquer les index
SOURCE sql/03_Indexes.sql;
```

### Tests Échouent

```bash
# Réinitialiser complètement
mysql -u root -p -e "DROP DATABASE IF EXISTS riada_db;"
./scripts/install.sh
```

---

## 📚 Prochaines Étapes

1. **Explorer la Documentation**
   - [README.md](README.md) - Vue complète
   - [CONTRIBUTING.md](CONTRIBUTING.md) - Contribuer
   - [CHANGELOG.md](CHANGELOG.md) - Historique

2. **Personnaliser**
   - Modifier les abonnements
   - Ajouter des clubs
   - Créer vos propres cours

3. **Intégrer**
   - Connecter un frontend web
   - Créer une API REST
   - Ajouter des notifications

4. **Optimiser**
   - Analyser les performances
   - Ajuster les index
   - Monitorer les logs

---

## 💡 Astuces

### Export des Données

```bash
# Export complet
mysqldump -u root -p riada_db > backup_riada.sql

# Export structure uniquement
mysqldump -u root -p --no-data riada_db > structure_only.sql

# Export données uniquement
mysqldump -u root -p --no-create-info riada_db > data_only.sql
```

### Import Rapide

```bash
mysql -u root -p riada_db < backup_riada.sql
```

### Mode Debug

```sql
-- Activer les logs détaillés
SET GLOBAL general_log = 'ON';
SET GLOBAL log_output = 'TABLE';

-- Voir les logs
SELECT * FROM mysql.general_log ORDER BY event_time DESC LIMIT 20;
```

---

## 🎓 Ressources

- 📖 [Documentation MySQL 8.0](https://dev.mysql.com/doc/refman/8.0/en/)
- 🎥 [Tutoriels SQL](https://www.mysqltutorial.org/)
- 💬 [Support GitHub](https://github.com/weliou/Riada/issues)

---

## ✅ Checklist Post-Installation

- [ ] Base de données créée
- [ ] 19 tables présentes
- [ ] Procédures testées (CheckAccess)
- [ ] Triggers actifs
- [ ] Audit système 10/10
- [ ] Données de test chargées
- [ ] Première requête exécutée
- [ ] Documentation lue

---

**🎉 Félicitations ! Vous êtes prêt à utiliser Riada !**

Pour aller plus loin, consultez le [README.md](README.md) complet.
