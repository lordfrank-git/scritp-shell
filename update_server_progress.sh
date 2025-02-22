#!/bin/bash

#### Définition des variables

# Définir les couleurs pour l'affichage
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Fichier de log
LOGFILE="/var/log/server_update.log"

#### Fin de la définition des variables

# Fonction pour afficher des messages formatés
log_message() {
    echo -e "${GREEN}[INFO]${RESET} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOGFILE
}

error_message() {
    echo -e "${RED}[ERREUR]${RESET} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERREUR: $1" >> $LOGFILE
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

# Fonction de mise à jour avec affichage progressif
update_packages() {
    log_message "Mise à jour de la liste des paquets..."
    echo -ne "${YELLOW}Mise à jour en cours...${RESET} "
    apt-get update -y >> $LOGFILE 2>&1 && echo -e "${GREEN}✔️${RESET}"
    send_alert_mail "🚨 ALERTE MISE À JOUR SERVEUR" \
        "Échec de la mise à jour des paquets sur le serveur. Vérifiez les logs."

    log_message "Mise à niveau des paquets installés..."
    echo -ne "${YELLOW}Mise à niveau en cours...${RESET} "
    apt-get upgrade -y >> $LOGFILE 2>&1 && echo -e "${GREEN}✔️${RESET}"
    send_alert_mail "🚨 ALERTE MISE À JOUR SERVEUR" \
        "Échec de la mise à niveau des paquets sur le serveur. Vérifiez les logs."

    log_message "Mise à jour terminée."
}

# Exécution du script
log_message "Début de la mise à jour du serveur"
update_packages
log_message "Fin de la mise à jour du serveur"
