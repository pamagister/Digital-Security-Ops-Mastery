#!/bin/bash

# ==============================
# Backup-Script: Ordner in verschlüsseltes ZIP/7z packen
# ==============================

# Ordner bestimmen, in dem das Script liegt
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASENAME="$(basename "$SCRIPT_DIR")"

# Ziel-Dateiname (mit Datum)
BACKUP_FILE="${SCRIPT_DIR}/../${BASENAME}_backup_$(date +%Y-%m-%d_%H-%M-%S).7z"

# Passwort abfragen (sicher, ohne Anzeige)
read -s -p "Passwort für Archiv eingeben: " PASSWORD
echo

# Alternative: Passwort fest im Script (unsicher!)
# PASSWORD="meinGeheimesPasswort"

# Archiv erstellen (7z-Format, verschlüsselt)
7z a -p"$PASSWORD" -mhe=on "$BACKUP_FILE" "$SCRIPT_DIR"/*

# Status ausgeben
if [ $? -eq 0 ]; then
    echo "Backup erfolgreich erstellt: $BACKUP_FILE"
else
    echo "Fehler beim Erstellen des Backups!"
fi

