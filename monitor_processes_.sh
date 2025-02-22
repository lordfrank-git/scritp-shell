#!/bin/bash

# Définition des couleurs
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Fichier de log
LOGFILE="/var/log/monitor_processes.log"

# Liste des processus à surveiller
PROCESSES=("apache2" "mysql" "ssh")

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

# Fonction de surveillance des processus
monitor_processes() {
    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${YELLOW}🔍 Surveillance des processus...${RESET}"
    echo -e "${BLUE}------------------------------------------------${RESET}"
    
    ALERT_TRIGGERED=0
    STOPPED_PROCESSES=()

    for PROCESS in "${PROCESSES[@]}"; do
        if pgrep "$PROCESS" > /dev/null; then
            echo -e "${GREEN}✅ $PROCESS est en cours d'exécution${RESET}"
            log_message "✅ $PROCESS est en cours d'exécution"
        else
            echo -e "${RED}❌ ALERTE: $PROCESS est arrêté${RESET}"
            log_message "⚠️ ALERTE: $PROCESS est arrêté"
            ALERT_TRIGGERED=1
            STOPPED_PROCESSES+=("$PROCESS")  # Ajoute le processus à la liste des arrêts

            # Option : Redémarrer automatiquement le service si disponible
            if systemctl list-units --type=service | grep -q "$PROCESS.service"; then
                echo -e "${YELLOW}🔄 Tentative de redémarrage de $PROCESS...${RESET}"
                systemctl restart "$PROCESS"
                if pgrep "$PROCESS" > /dev/null; then
                    echo -e "${GREEN}✅ $PROCESS redémarré avec succès${RESET}"
                    log_message "✅ $PROCESS redémarré avec succès"
                else
                    echo -e "${RED}❌ Échec du redémarrage de $PROCESS${RESET}"
                    log_message "❌ Échec du redémarrage de $PROCESS"
                fi
            fi
        fi
    done

    # Envoi d'un email si un ou plusieurs processus sont arrêtés
    if [[ $ALERT_TRIGGERED -eq 1 ]]; then
        STOPPED_LIST=$(printf "%s\n" "${STOPPED_PROCESSES[@]}")
        send_alert_mail "🚨 ALERTE PROCESSUS CRITIQUES" \
        "Les processus suivants sont arrêtés sur le serveur :\n$STOPPED_LIST"
    fi
}

# Fonction d'affichage du bilan
display_summary() {
    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${YELLOW}📊 BILAN DU MONITORING${RESET}"
    echo -e "${BLUE}------------------------------------------------${RESET}"
    
    if [[ $ALERT_TRIGGERED -eq 1 ]]; then
        echo -e "${RED}❌ Une ou plusieurs alertes ont été détectées !${RESET}"
        log_message "❌ ALERTE: Un ou plusieurs processus étaient arrêtés"
    else
        echo -e "${GREEN}✅ Tous les processus sont en cours d'exécution.${RESET}"
        log_message "✅ Aucun problème détecté, tous les processus fonctionnent normalement."
    fi

    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${GREEN}✅ Fin du monitoring.${RESET}"
}

# Exécution du script
log_message "🚀 Début du monitoring des processus"
monitor_processes
display_summary
log_message "🏁 Fin du monitoring des processus"
