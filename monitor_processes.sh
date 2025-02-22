#!/bin/bash

# Définir les couleurs pour l'affichage
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Fichier de log
LOGFILE="/var/log/monitor_processes.log"

# Fonction pour afficher des messages formatés
log_message() {
    echo -e "${GREEN}[INFO]${RESET} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOGFILE
}

error_message() {
    echo -e "${RED}[ERREUR]${RESET} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERREUR: $1" >> $LOGFILE
}

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
    error_message "Ce script doit être exécuté en tant que root (sudo)."
    exit 1
fi

# Surveillance des processus
monitor_processes() {
    log_message "Surveillance des processus"
    PROCESSES=("apache2" "mysql" "ssh")
    for PROCESS in "${PROCESSES[@]}"; do
        if pgrep $PROCESS > /dev/null; then
            log_message "$PROCESS est en cours d'exécution"
        else
            log_message "ALERTE: $PROCESS n'est pas en cours d'exécution"
        fi
    done
}

# Exécution du script
log_message "Début du monitoring des processus"
monitor_processes
log_message "Fin du monitoring des processus"
