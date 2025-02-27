#!/bin/bash

# ========================================
# Script de Restauration Automatisée
# - Déchiffrement de la sauvegarde
# - Vérification d’intégrité après déchiffrement
# - Extraction des fichiers
# - Journalisation des opérations
# - Notification par e-mail
# ========================================

# ======== VARIABLES =========
BACKUP_DIR="/home/ordin/Documents/Backups"  # Dossier contenant les sauvegardes chiffrées
RESTORE_DIR="/home/ordin/Documents/Restaurations"  # Dossier de restauration
LOG_FILE="/var/log/restore_script.log"  # Fichier de log
EMAIL="mon_email@gmail.com"  # Adresse e-mail pour les notifications
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/backup_*.tar.gz.gpg | head -n 1)  # Dernière sauvegarde trouvée
DECRYPTED_FILE="${LATEST_BACKUP%.gpg}"  # Nom du fichier après déchiffrement

# ======== CONFIGURATION ENVIRONNEMENT GPG =========
export GNUPGHOME="/home/ordin/.gnupg"  # Assure que GPG trouve les clés

# ======== FONCTIONS =========
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $message" | tee -a "$LOG_FILE"
}

# ======== VÉRIFICATIONS =========
# Vérifier si une sauvegarde chiffrée existe
if [ ! -f "$LATEST_BACKUP" ]; then
    log_message "❌ ERREUR : Aucune sauvegarde chiffrée trouvée dans $BACKUP_DIR !"
    echo "Erreur : Aucune sauvegarde trouvée !" | mail -s "Échec de la restauration" "$EMAIL"
    exit 1
fi

# Vérifier si le répertoire de restauration existe, sinon le créer
if [ ! -d "$RESTORE_DIR" ]; then
    log_message "Création du répertoire de restauration..."
    mkdir -p "$RESTORE_DIR"
fi

# ======== DÉCHIFFREMENT =========
log_message "Déchiffrement de la sauvegarde : $LATEST_BACKUP..."
gpg --decrypt --output "$DECRYPTED_FILE" "$LATEST_BACKUP" 2>>"$LOG_FILE"

# Vérifier si le fichier déchiffré a été correctement généré
if [ $? -eq 0 ] && [ -s "$DECRYPTED_FILE" ]; then
    log_message "✅ Déchiffrement réussi : $DECRYPTED_FILE"
else
    log_message "❌ ERREUR : Échec du déchiffrement !"
    echo "Erreur : Déchiffrement échoué !" | mail -s "Échec de la restauration" "$EMAIL"
    exit 1
fi

# ======== VÉRIFICATION D’INTÉGRITÉ =========
log_message "Vérification d'intégrité de la sauvegarde..."
tar -tzf "$DECRYPTED_FILE" > /dev/null 2>>"$LOG_FILE"

if [ $? -eq 0 ]; then
    log_message "✅ Intégrité vérifiée avec succès !"
else
    log_message "❌ ERREUR : Le fichier de sauvegarde est corrompu !"
    echo "Erreur : Sauvegarde corrompue !" | mail -s "Échec de la restauration" "$EMAIL"
    exit 1
fi

# ======== EXTRACTION =========
log_message "Extraction de la sauvegarde..."
tar -xzf "$DECRYPTED_FILE" -C "$RESTORE_DIR" 2>>"$LOG_FILE"

if [ $? -eq 0 ]; then
    log_message "✅ Restauration réussie dans : $RESTORE_DIR"
    echo "Restauration terminée avec succès." | mail -s "Restauration réussie" "$EMAIL"
    rm -f "$DECRYPTED_FILE"  # Suppression du fichier temporaire déchiffré
else
    log_message "❌ ERREUR : Échec de l’extraction des fichiers !"
    echo "Erreur : Extraction échouée !" | mail -s "Échec de la restauration" "$EMAIL"
    exit 1
fi

log_message "Processus de restauration terminé avec succès !"
exit 0
