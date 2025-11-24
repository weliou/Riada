# Guide de Contribution

Merci de votre intérêt pour contribuer au projet **Riada** ! 🎉

Ce document décrit les standards et processus pour contribuer efficacement au projet.

## 📋 Table des Matières

- [Code de Conduite](#code-de-conduite)
- [Comment Contribuer](#comment-contribuer)
- [Standards de Code](#standards-de-code)
- [Processus de Pull Request](#processus-de-pull-request)
- [Reporting de Bugs](#reporting-de-bugs)
- [Suggestions de Fonctionnalités](#suggestions-de-fonctionnalités)

---

## 🤝 Code de Conduite

Ce projet adhère à un code de conduite pour garantir un environnement accueillant et inclusif pour tous.

### Nos Engagements

- Respecter les différents points de vue et expériences
- Accepter la critique constructive avec grâce
- Se concentrer sur ce qui est le mieux pour la communauté
- Faire preuve d'empathie envers les autres membres

### Comportements Inacceptables

- Langage ou images inappropriés
- Attaques personnelles ou commentaires insultants
- Harcèlement public ou privé
- Publication d'informations privées sans permission

---

## 🚀 Comment Contribuer

### 1. Fork & Clone

```bash
# Fork le repository sur GitHub
# Puis clonez votre fork
git clone https://github.com/VOTRE_USERNAME/Riada.git
cd Riada
```

### 2. Créer une Branche

```bash
# Créez une branche pour votre fonctionnalité ou correction
git checkout -b feature/ma-nouvelle-fonctionnalite
# ou
git checkout -b fix/correction-bug-xyz
```

### 3. Faire vos Modifications

- Suivez les [Standards de Code](#standards-de-code)
- Ajoutez des tests si nécessaire
- Documentez vos changements

### 4. Tester

```bash
# Testez votre code avec le script d'audit
mysql -u root -p < sql/10_System_Check.sql

# Assurez-vous que tous les tests passent
# Résultat attendu: 10/10 vérifications ✅
```

### 5. Commit

```bash
# Ajoutez vos fichiers
git add .

# Commit avec un message clair
git commit -m "feat: Ajout de la fonctionnalité X"
```

### 6. Push

```bash
# Poussez vers votre fork
git push origin feature/ma-nouvelle-fonctionnalite
```

### 7. Pull Request

- Allez sur GitHub et créez une Pull Request
- Remplissez le template de PR
- Attendez la review

---

## 📝 Standards de Code

### Conventions SQL

#### Nommage

```sql
-- ✅ BON: Snake_case pour les tables
CREATE TABLE contrats_adhesion (...);

-- ✅ BON: Préfixes pour les procédures
CREATE PROCEDURE sp_CheckAccess(...);

-- ✅ BON: Préfixes pour les triggers
CREATE TRIGGER trg_after_paiement_insert ...;

-- ✅ BON: Préfixes pour les index
CREATE INDEX idx_membres_nom_prenom ON membres(nom, prenom);

-- ✅ BON: Préfixes pour les contraintes
ALTER TABLE factures ADD CONSTRAINT fk_factures_contrats ...;
```

#### Formatage

```sql
-- ✅ BON: Indentation et lisibilité
SELECT 
    m.nom,
    m.prenom,
    a.nom_offre
FROM 
    membres AS m
INNER JOIN 
    contrats_adhesion AS c ON m.id = c.membre_id
WHERE 
    c.statut = 'Actif'
ORDER BY 
    m.nom;

-- ❌ MAUVAIS: Tout sur une ligne
SELECT m.nom,m.prenom,a.nom_offre FROM membres m INNER JOIN contrats_adhesion c ON m.id=c.membre_id WHERE c.statut='Actif';
```

#### Commentaires

```sql
-- ✅ BON: Commentaires explicatifs
-- VérifiCATION 1: Le membre existe-t-il ?
SELECT COUNT(*) INTO v_membre_existe FROM membres WHERE id = p_membre_id;

-- ✅ BON: Headers de script
-- -----------------------------------------------------
-- Script: 05_Triggers.sql (Version V5)
-- Objectif: Automatiser les mises à jour
-- -----------------------------------------------------

-- ❌ MAUVAIS: Pas de commentaires pour logique complexe
IF v_impayes_en_retard > 0 THEN
    SET p_decision = 'Refusé';
END IF;
```

#### Types de Données

```sql
-- ✅ BON: Types précis et optimisés
id INT UNSIGNED
prix DECIMAL(7,2)
nom VARCHAR(100)
est_actif BOOLEAN

-- ❌ MAUVAIS: Types trop larges
id BIGINT
prix FLOAT
nom TEXT
est_actif TINYINT
```

### Versioning

Chaque modification majeure doit être versionnée :

```sql
-- Version actuelle: V5.0
-- Prochaine modification mineure: V5.1
-- Prochaine modification majeure: V6.0
```

### Performance

#### Index Obligatoires

- Toute FK doit avoir un index
- Les colonnes de WHERE/JOIN fréquents doivent être indexées
- Les index composites doivent suivre la règle "égalité avant range"

```sql
-- ✅ BON: Index composite optimisé
CREATE INDEX idx_contrat_membre_statut 
ON contrats_adhesion(membre_id, statut);

-- ❌ MAUVAIS: Index dans le mauvais ordre
CREATE INDEX idx_contrat_statut_membre 
ON contrats_adhesion(statut, membre_id);
```

#### Requêtes

- Toujours utiliser des filtres temporels pour les grandes tables
- Préférer les CTE aux subqueries pour la lisibilité
- Limiter les SELECT *

```sql
-- ✅ BON: Filtre temporel
SELECT COUNT(*) FROM journal_acces 
WHERE date_passage >= DATE_SUB(NOW(), INTERVAL 30 DAY);

-- ❌ MAUVAIS: Scan complet de table
SELECT COUNT(*) FROM journal_acces;
```

---

## 🔄 Processus de Pull Request

### Template de PR

Utilisez ce template pour vos Pull Requests :

```markdown
## Description
Brève description des changements

## Type de Changement
- [ ] 🐛 Bug fix (correction non-breaking)
- [ ] ✨ Nouvelle fonctionnalité (changement non-breaking)
- [ ] 💥 Breaking change (correction ou fonctionnalité causant des incompatibilités)
- [ ] 📖 Documentation

## Motivation et Contexte
Pourquoi ce changement est-il nécessaire ? Quel problème résout-il ?

## Comment a-t-il été testé ?
- [ ] Tests unitaires
- [ ] Script 10_System_Check.sql (10/10 ✅)
- [ ] Tests manuels

## Checklist
- [ ] Mon code suit les standards du projet
- [ ] J'ai commenté les parties complexes
- [ ] J'ai mis à jour la documentation
- [ ] J'ai ajouté des tests
- [ ] Tous les tests passent
- [ ] J'ai mis à jour CHANGELOG.md

## Screenshots (si applicable)
```

### Review Process

1. **Automatique**: Les tests CI/CD doivent passer
2. **Review**: Au moins 1 approbation requise
3. **Tests**: Vérification manuelle si nécessaire
4. **Merge**: Squash and merge recommandé

---

## 🐛 Reporting de Bugs

### Template d'Issue

```markdown
**Description du Bug**
Description claire et concise du bug.

**Pour Reproduire**
Étapes pour reproduire le comportement:
1. Exécuter le script '...'
2. Appeler la procédure '...'
3. Voir l'erreur

**Comportement Attendu**
Ce qui devrait se passer normalement.

**Comportement Actuel**
Ce qui se passe actuellement.

**Environnement**
- OS: [ex: Ubuntu 22.04]
- MySQL Version: [ex: 8.0.35]
- Version Riada: [ex: V5.0]

**Logs d'Erreur**
```sql
-- Coller les logs MySQL ici
```

**Informations Additionnelles**
Tout autre contexte utile.
```

### Labels

Utilisez les labels appropriés :
- `bug` : Quelque chose ne fonctionne pas
- `enhancement` : Nouvelle fonctionnalité ou amélioration
- `documentation` : Améliorations de la doc
- `performance` : Optimisations
- `security` : Problèmes de sécurité
- `question` : Questions sur le projet

---

## 💡 Suggestions de Fonctionnalités

### Template de Feature Request

```markdown
**Fonctionnalité Demandée**
Description claire de la fonctionnalité.

**Problème Résolu**
Quel problème cette fonctionnalité résout-elle ?

**Solution Proposée**
Comment imaginez-vous cette fonctionnalité ?

**Alternatives Considérées**
Autres solutions envisagées.

**Impact**
- Tables affectées: [...]
- Procédures affectées: [...]
- Breaking change: Oui/Non

**Informations Additionnelles**
Contexte, exemples d'utilisation, etc.
```

---

## 🧪 Tests

### Avant de Soumettre

```bash
# 1. Tester l'installation complète
bash scripts/install.sh

# 2. Exécuter l'audit système
mysql -u root -p < sql/10_System_Check.sql

# 3. Vérifier les tests métier
mysql -u root -p < sql/09_Tests.sql

# 4. Tester les requêtes d'analyse
mysql -u root -p < sql/08_Select_Queries.sql
```

### Résultats Attendus

- ✅ 10/10 vérifications dans l'audit
- ✅ Tous les tests métier passent
- ✅ Aucune erreur SQL
- ✅ Performance maintenue (<2000 µs)

---

## 📚 Documentation

Toute nouvelle fonctionnalité doit être documentée :

1. **README.md** : Vue d'ensemble
2. **CHANGELOG.md** : Historique des versions
3. **Commentaires SQL** : Dans le code
4. **Exemples** : Dans 08_Select_Queries.sql

---

## ❓ Questions

Pour toute question :
- 💬 Créez une [Discussion GitHub](https://github.com/weliou/Riada/discussions)
- 📧 Contactez les mainteneurs
- 📖 Consultez la [Documentation](README.md)

---

## 🙏 Remerciements

Merci de contribuer à **Riada** ! Chaque contribution, petite ou grande, est précieuse.

---

**Dernière mise à jour** : Novembre 2025
