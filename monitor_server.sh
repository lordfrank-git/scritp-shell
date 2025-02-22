#!/bin/bash

# Définition des couleurs
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Liste des scripts à exécuter
SCRIPTS=("check_disk_.sh" "update_server_progress.sh" "monitor_processes_.sh")

# Fichier de log principal
LOGFILE="/var/log/server_monitor.log"

# Fonction pour afficher un message et enregistrer dans le log
log_message() {
    local message="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a $LOGFILE
}

error_message() {
    local message="$1"
    echo -e "${RED}[ERREUR]${RESET} $message"
    log_message "ERREUR: $message"
}

# Adresse email de destination pour les alertes
ALERT_EMAIL="tonadressemail@gmail.com"

# Fonction d'envoi d'alerte par email via sSMTP
send_alert_mail() {
    local subject="$1"        # $1 signifie le premier argument
    local message="$2"        # $2 signifie le second argument
    echo -e "$message" | mail -s "$subject" "$ALERT_EMAIL"      # -e renvoie 0 si fichier existe. et 
}

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
    error_message "Ce script doit être exécuté en tant que root (sudo)."
    exit 1
fi

# Fonction pour exécuter les scripts et gérer les erreurs
run_scripts() {
    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${YELLOW}🚀 Démarrage du monitoring serveur${RESET}"
    echo -e "${BLUE}------------------------------------------------${RESET}"

    for SCRIPT in "${SCRIPTS[@]}"; do
        if [[ -f "$SCRIPT" && -x "$SCRIPT" ]]; then
            echo -e "${GREEN}▶️ Exécution de $SCRIPT...${RESET}"
            log_message "Exécution de $SCRIPT..."
            ./"$SCRIPT"
            echo -e "${GREEN}✅ Fin de $SCRIPT${RESET}"
        else
            echo -e "${RED}❌ Erreur : Impossible d'exécuter $SCRIPT (fichier introuvable ou non exécutable)${RESET}"
            log_message "❌ Erreur : $SCRIPT est introuvable ou non exécutable"
        fi
    done
}

# Fonction d'affichage du bilan
display_summary() {
    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${YELLOW}📊 BILAN DU MONITORING${RESET}"
    echo -e "${BLUE}------------------------------------------------${RESET}"
    
    log_message "📊 Récapitulatif de l'exécution :"
    echo -e "${GREEN}✅ Tous les scripts ont été exécutés.${RESET}"
    log_message "✅ Tous les scripts ont été exécutés."

    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${GREEN}✅ Fin du monitoring.${RESET}"
}

# Exécution du script principal
log_message "🚀 Début du monitoring serveur"
run_scripts
display_summary
log_message "🏁 Fin du monitoring serveur"
