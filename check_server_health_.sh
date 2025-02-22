#!/bin/bash  

# Définition des couleurs
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Fichier de log
LOGFILE="/var/log/server_health.log"

# Adresse email de destination pour les alertes
ALERT_EMAIL="tonadressemail.com"

# Seuils d'alerte
MEMORY_THRESHOLD=90  # Pourcentage d'utilisation RAM critique
CPU_THRESHOLD=2.00   # Charge CPU critique (Load Average 1 min)

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

# Fonction d'envoi d'alerte par email via sSMTP
send_alert_mail() {
    local subject="$1"
    local message="$2"
    echo -e "$message" | mail -s "$subject" "$ALERT_EMAIL"
}

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
    error_message "Ce script doit être exécuté en tant que root (sudo)."
    exit 1
fi

# Fonction pour vérifier la santé du serveur
check_server_health() {
    log_message "🔍 Vérification de la santé du serveur"
    ALERT_TRIGGERED=0
    ALERT_MESSAGE=""

    # Vérification de la mémoire
    MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2 }')
    log_message "💾 Utilisation de la mémoire: $MEMORY_USAGE%"

    if (( $(echo "$MEMORY_USAGE > $MEMORY_THRESHOLD" | bc -l) )); then
        ALERT_TRIGGERED=1
        ALERT_MESSAGE+="\n⚠️ Mémoire critique: $MEMORY_USAGE% utilisée"
    fi

    # Vérification de la charge CPU
    CPU_LOAD=$(top -bn1 | grep "load average" | awk '{printf "%.2f", $(NF-2)}')
    log_message "⚙️ Charge CPU: $CPU_LOAD"

    if (( $(echo "$CPU_LOAD > $CPU_THRESHOLD" | bc -l) )); then
        ALERT_TRIGGERED=1
        ALERT_MESSAGE+="\n⚠️ Charge CPU critique: Load Average 1 min = $CPU_LOAD"
    fi

    # Vérification de l'uptime
    UPTIME=$(uptime -p)
    log_message "🕒 Uptime: $UPTIME"

    # Envoi d'un email si une alerte est déclenchée
    if [[ $ALERT_TRIGGERED -eq 1 ]]; then
        send_alert_mail "🚨 ALERTE SANTÉ SERVEUR" "Le serveur présente des problèmes:\n$ALERT_MESSAGE"
    fi
}

# Fonction d'affichage du bilan
display_summary() {
    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${YELLOW}📊 BILAN DE LA VÉRIFICATION${RESET}"
    echo -e "${BLUE}------------------------------------------------${RESET}"
    
    if [[ $ALERT_TRIGGERED -eq 1 ]]; then
        echo -e "${RED}❌ Problèmes détectés : ${ALERT_MESSAGE}${RESET}"
        log_message "❌ ALERTE: Problèmes détectés : ${ALERT_MESSAGE}"
    else
        echo -e "${GREEN}✅ Aucun problème détecté, le serveur fonctionne normalement.${RESET}"
        log_message "✅ Aucun problème détecté, le serveur est en bonne santé."
    fi

    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${GREEN}✅ Fin de la vérification.${RESET}"
}

# Exécution du script
log_message "🚀 Début de la vérification de la santé du serveur"
check_server_health
display_summary
log_message "🏁 Fin de la vérification de la santé du serveur"
