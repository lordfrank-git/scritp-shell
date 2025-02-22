#!/bin/bash  

# Définition des couleurs
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Fichier de log
LOGFILE="/var/log/server_check_disk.log"

# Paramètres
DISK_USAGE_THRESHOLD=65   # Seuil d'utilisation disque en pourcentage
LOG_DAYS_TO_KEEP=30       # Nombre de jours à conserver les logs
ALERT_TRIGGERED=0         # Variable pour suivre si une alerte a été déclenchée

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

# Fonction de vérification de l'espace disque
check_disk_usage() {
    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${YELLOW}🔍 Vérification de l'utilisation du disque...${RESET}"
    echo -e "${BLUE}------------------------------------------------${RESET}"

    sleep 1  # Effet de chargement

    DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')

    if [[ $DISK_USAGE -ge $DISK_USAGE_THRESHOLD ]]; then
        ALERT_TRIGGERED=1
        echo -e "${RED}❌ ALERTE: Utilisation du disque à ${DISK_USAGE}%${RESET}"
        log_message "⚠️ ALERTE: Utilisation du disque à ${DISK_USAGE}%"

        # Option : Envoyer une alerte par mail (si un serveur mail est configuré)
        # Envoi d'un mail d'alerte
        send_alert_mail "🚨 ALERTE DISQUE SERVEUR" \
        "Attention : L'utilisation du disque est à ${DISK_USAGE}%. Veuillez prendre des mesures immédiatement."
    
        # echo "Attention : L'utilisation du disque est à ${DISK_USAGE}%" | mail -s "Alerte Disque Serveur" admin@example.com

        # Option : Ajouter un message dans syslog
        logger -p user.warning "⚠️ ALERTE: Espace disque serveur à ${DISK_USAGE}%"

    else
        echo -e "${GREEN}✅ Utilisation du disque à ${DISK_USAGE}% - OK${RESET}"
        log_message "✅ Utilisation du disque à ${DISK_USAGE}% - OK"
    fi
}

# Fonction de nettoyage des anciens logs
clean_old_logs() {
    echo -e "${YELLOW}🧹 Nettoyage des anciens logs (+${LOG_DAYS_TO_KEEP} jours)...${RESET}"
    log_message "🧹 Suppression des logs de plus de ${LOG_DAYS_TO_KEEP} jours..."
    find /var/log -name "server_check_disk.log*" -type f -mtime +$LOG_DAYS_TO_KEEP -exec rm -f {} \;
    log_message "✅ Nettoyage des anciens logs terminé."
}

# Fonction pour afficher le bilan
display_summary() {
    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${YELLOW}📊 BILAN DE L'EXÉCUTION${RESET}"
    echo -e "${BLUE}------------------------------------------------${RESET}"
    
    log_message "📊 Récapitulatif :"

    if [[ $ALERT_TRIGGERED -eq 1 ]]; then
        echo -e "${RED}❌ Une alerte a été déclenchée !${RESET}"
        log_message "❌ ALERTE: Espace disque critique, action requise !"
        log_message "❌ ALERTE: Un mail vous a été transmis, action requise !"
    else
        echo -e "${GREEN}✅ Aucune alerte, tout est en ordre.${RESET}"
        log_message "✅ Aucun problème détecté, espace disque OK."
    fi

    echo -e "${BLUE}------------------------------------------------${RESET}"
    echo -e "${GREEN}✅ Fin du script.${RESET}"
}

# Exécution du script
log_message "🚀 Début de la vérification de l'espace disque"
check_disk_usage
clean_old_logs
display_summary
log_message "🏁 Fin de la vérification de l'espace disque"
