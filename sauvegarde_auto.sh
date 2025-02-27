#!/bin/bash

# ========================================
# Script de Sauvegarde Automatisée avec :
# - Compression des fichiers
# - Nettoyage des anciennes sauvegardes
# - Journalisation des opérations
# - Notification par e-mail
# - Chiffrement GPG
# ========================================

# ======== VARIABLES =========
SOURCE_DIRS=("/home/ordin/lab maintenance serveur")  # Répertoires à sauvegarder
BACKUP_DIR="/home/ordin/Documents/Backups"  # Répertoire de sauvegarde
LOG_FILE="/var/log/backup_script.log"  # Fichier de log
RETENTION_DAYS=7  # Nombre de jours avant suppression
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")  # Horodatage
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"  # Nom du fichier de sauvegarde
ENCRYPTED_FILE="$BACKUP_FILE.gpg"  # Fichier chiffré

# E-mail de notification
EMAIL="mon_email@gmail.com"

# Clé publique GPG
GPG_RECIPIENT="DCE927B9929A816B"

# ======== CONFIGURATION ENVIRONNEMENT GPG =========
export GNUPGHOME="/home/ordin/.gnupg"  # Définit le dossier contenant les clés GPG

# ======== FONCTIONS =========
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $message" | tee -a "$LOG_FILE"
}

# Vérification et création du répertoire de sauvegarde
if [ ! -d "$BACKUP_DIR" ]; then
    log_message "Le répertoire de sauvegarde n'existe pas. Création en cours..."
    mkdir -p "$BACKUP_DIR"
fi

# Vérification que le répertoire à sauvegarder existe
for dir in "${SOURCE_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        log_message "❌ ERREUR : Le répertoire source $dir n'existe pas !"
        echo "Erreur : Répertoire $dir introuvable !" | mail -s "Échec de la sauvegarde" "$EMAIL"
        exit 1
    fi
done

# ======== SAUVEGARDE =========
log_message "Démarrage de la sauvegarde..."

# Gestion des espaces dans les noms de fichiers
tar -czf "$BACKUP_FILE" -- "${SOURCE_DIRS[@]}" 2>>"$LOG_FILE"

# Vérification du succès de la sauvegarde
if [ $? -eq 0 ] && [ -s "$BACKUP_FILE" ]; then
    log_message "Sauvegarde réussie : $BACKUP_FILE"
else
    log_message "❌ ERREUR : Échec de la sauvegarde !"
    echo "Sauvegarde échouée !" | mail -s "Échec de la sauvegarde" "$EMAIL"
    exit 1
fi

# Vérification des permissions du fichier de sauvegarde
chmod 644 "$BACKUP_FILE"

# Vérification que la clé GPG est disponible
if ! gpg --list-keys "$GPG_RECIPIENT" > /dev/null 2>&1; then
    log_message "❌ ERREUR : Clé GPG non trouvée pour le chiffrement !"
    echo "Erreur : Clé GPG $GPG_RECIPIENT introuvable !" | mail -s "Échec du chiffrement" "$EMAIL"
    exit 1
fi

# ======== CHIFFREMENT =========
log_message "Chiffrement du fichier de sauvegarde..."
gpg --encrypt --recipient "$GPG_RECIPIENT" --output "$ENCRYPTED_FILE" "$BACKUP_FILE" 2>>"$LOG_FILE"

# Vérification du succès du chiffrement
if [ $? -eq 0 ] && [ -s "$ENCRYPTED_FILE" ]; then
    log_message "Fichier chiffré avec succès : $ENCRYPTED_FILE"
    rm -f "$BACKUP_FILE"  # Suppression du fichier non chiffré
else
    log_message "❌ ERREUR : Échec du chiffrement !"
    echo "Chiffrement échoué !" | mail -s "Échec du chiffrement" "$EMAIL"
    exit 1
fi

# ======== NETTOYAGE DES ANCIENNES SAUVEGARDES =========
log_message "Nettoyage des anciennes sauvegardes..."
find "$BACKUP_DIR" -name "backup_*.tar.gz.gpg" -mtime +$RETENTION_DAYS -exec rm -f {} \; 2>>"$LOG_FILE"

if [ $? -eq 0 ]; then
    log_message "Nettoyage terminé. Suppression des fichiers de plus de $RETENTION_DAYS jours."
else
    log_message "❌ ERREUR : Problème lors du nettoyage des anciennes sauvegardes !"
fi

# ======== NOTIFICATION PAR EMAIL =========
echo "Sauvegarde et chiffrement terminés avec succès." | mail -s "Sauvegarde réussie" "$EMAIL"

log_message "Processus de sauvegarde terminé avec succès !"
exit 0
