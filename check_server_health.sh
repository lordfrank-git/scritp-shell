#!/bin/bash  

# Définition des couleurs
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Fichier de log
LOGFILE="/var/log/server_check_disk.log"

# Fonction pour afficher des messages formatés
log_message() {
    local message="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a $LOGFILE
}

error_message() {
    local message="$1"
    echo -e "${RED}[ERREUR]${RESET} $message"
    log_message "ERREUR: $message"
}

 #Vérification des droits root
if [[ $EUID -ne 0 ]]; then
    error_message "Ce script doit être exécuté en tant que root (sudo)."
    exit 1
fi

# Fonction pour vérifier la santé du serveur
check_server_health() {
    log_message "Vérification de la santé du serveur"
    # Vérification de la mémoire
    MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
    log_message "Utilisation de la mémoire: $MEMORY_USAGE"

    # Vérification de la charge CPU
    CPU_LOAD=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
    log_message "Charge CPU: $CPU_LOAD"

    # Vérification de l'uptime
    UPTIME=$(uptime -p)
    log_message "Uptime: $UPTIME"
}

# Exécution du script
log_message "🚀 Début de la vérification de la santé du serveur"
check_server_health
log_message "🏁 Fin de la vérification de la santé du serveur"
