#!/bin/bash   #Indique que le script doit être exécuté avec Bash

# Définir les variables
LOGFILE="/var/log/server_update.log"        #Fichier de log pour enregistrer les actions

# Fonction pour enregistrer un message dans le log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOGFILE
}

# Mise à jour des paquets
update_packages() {
    log_message "Mise à jour des paquets"
    apt-get update >> $LOGFILE 2>&1
    apt-get upgrade -y >> $LOGFILE 2>&1
    log_message "Mise à jour des paquets terminée"
}

# Exécution des fonctions
log_message "Début de la mise à jour du serveur"
update_packages
log_message "Fin de la mise à jour du serveur"