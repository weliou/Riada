#!/bin/bash

# =====================================================
# Script: install.sh
# Objectif: Installation automatisée de Riada DB
# Version: 1.0
# =====================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DB_NAME="riada_db"
SQL_DIR="./sql"
MYSQL_USER="root"
MYSQL_HOST="localhost"

# =====================================================
# Fonction: Afficher le header
# =====================================================
show_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       INSTALLATION RIADA DATABASE V5.0          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

# =====================================================
# Fonction: Vérifier les prérequis
# =====================================================
check_prerequisites() {
    echo -e "${YELLOW}[1/8]${NC} Vérification des prérequis..."
    
    # Vérifier MySQL
    if ! command -v mysql &> /dev/null; then
        echo -e "${RED}❌ MySQL n'est pas installé!${NC}"
        exit 1
    fi
    
    # Vérifier les fichiers SQL
    if [ ! -d "$SQL_DIR" ]; then
        echo -e "${RED}❌ Dossier sql/ introuvable!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prérequis OK${NC}"
}

# =====================================================
# Fonction: Demander les credentials MySQL
# =====================================================
get_credentials() {
    echo -e "${YELLOW}[2/8]${NC} Configuration MySQL..."
    
    # Demander le mot de passe root
    read -sp "Mot de passe MySQL root: " MYSQL_PASSWORD
    echo ""
    
    # Tester la connexion
    if ! mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" -e "SELECT 1;" &> /dev/null; then
        echo -e "${RED}❌ Connexion MySQL échouée! Vérifiez vos credentials.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Connexion MySQL réussie${NC}"
}

# =====================================================
# Fonction: Exécuter un script SQL
# =====================================================
execute_sql() {
    local script=$1
    local description=$2
    
    if [ ! -f "$script" ]; then
        echo -e "${RED}❌ Fichier introuvable: $script${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}   ${NC} Exécution: $description..."
    
    if mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" < "$script" 2>&1 | grep -i "error" > /dev/null; then
        echo -e "${RED}❌ Erreur lors de l'exécution de $script${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}   ✅ $description OK${NC}"
}

# =====================================================
# Fonction: Installation complète
# =====================================================
install_database() {
    echo ""
    echo -e "${YELLOW}[3/8]${NC} Création de la base de données..."
    execute_sql "$SQL_DIR/01_Create_Database.sql" "Base de données"
    
    echo -e "${YELLOW}[4/8]${NC} Création des tables..."
    execute_sql "$SQL_DIR/02_Create_Tables.sql" "19 tables"
    
    echo -e "${YELLOW}[5/8]${NC} Création des index et contraintes..."
    execute_sql "$SQL_DIR/03_Indexes.sql" "Index + FK"
    
    echo -e "${YELLOW}[6/8]${NC} Création des procédures stockées..."
    execute_sql "$SQL_DIR/04_Procedures.sql" "Procédures"
    
    echo -e "${YELLOW}[7/8]${NC} Création des triggers..."
    execute_sql "$SQL_DIR/05_Triggers.sql" "Triggers"
    
    echo -e "${YELLOW}[8/8]${NC} Configuration de la sécurité..."
    execute_sql "$SQL_DIR/06_Security.sql" "Utilisateur sécurisé"
}

# =====================================================
# Fonction: Charger les données de test
# =====================================================
load_test_data() {
    echo ""
    read -p "Charger les données de test? (o/N): " response
    
    if [[ "$response" =~ ^[Oo]$ ]]; then
        echo -e "${YELLOW}   ${NC} Chargement des données de test..."
        execute_sql "$SQL_DIR/07_Insert_All_Data.sql" "Données de test"
    else
        echo -e "${BLUE}   ℹ️  Données de test ignorées${NC}"
    fi
}

# =====================================================
# Fonction: Audit système
# =====================================================
run_audit() {
    echo ""
    read -p "Exécuter l'audit système? (o/N): " response
    
    if [[ "$response" =~ ^[Oo]$ ]]; then
        echo -e "${YELLOW}   ${NC} Audit système en cours..."
        mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" < "$SQL_DIR/10_System_Check.sql"
    else
        echo -e "${BLUE}   ℹ️  Audit ignoré${NC}"
    fi
}

# =====================================================
# Fonction: Afficher le résumé
# =====================================================
show_summary() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         INSTALLATION TERMINÉE                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Base de données:${NC} $DB_NAME"
    echo -e "${GREEN}✅ Structure:${NC} 19 tables créées"
    echo -e "${GREEN}✅ Composants:${NC} 2 procédures + 3 triggers"
    echo -e "${GREEN}✅ Sécurité:${NC} Utilisateur portique_user configuré"
    echo ""
    echo -e "${BLUE}📖 Prochaines étapes:${NC}"
    echo -e "   1. Tester l'accès: ${YELLOW}mysql -u portique_user -p riada_db${NC}"
    echo -e "   2. Consulter le README.md pour les exemples d'utilisation"
    echo -e "   3. Exécuter les tests: ${YELLOW}mysql -u root -p < sql/09_Tests.sql${NC}"
    echo ""
}

# =====================================================
# Fonction: Gestion des erreurs
# =====================================================
handle_error() {
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           INSTALLATION ÉCHOUÉE                   ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}Une erreur s'est produite lors de l'installation.${NC}"
    echo -e "${YELLOW}Vérifiez les logs ci-dessus pour plus de détails.${NC}"
    echo ""
    exit 1
}

# Trap pour gérer les erreurs
trap handle_error ERR

# =====================================================
# MAIN - Exécution du script
# =====================================================
main() {
    show_header
    check_prerequisites
    get_credentials
    install_database
    load_test_data
    run_audit
    show_summary
}

# Lancer le script
main
