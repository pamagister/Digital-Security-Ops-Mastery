#!/bin/bash
# mount_nas.sh

# 1. Erst credentials_nas anlegen:
# sudo nano /etc/samba/credentials_nas

# 2. Inhalt:
# username=USERNAME
# password=PASSWORD

# 3. Rechte beschränken
# sudo chmod 600 /etc/samba/credentials_nas

# 4. Dieses Script ausführbar machen
# chmod +x mount_nas.sh

# 5. Dieses Script ausführen
# sudo ./mount_nas.sh

# Option 1 (Mount all) → macht dein bisheriges Verhalten
# Option 2 (Unmount all) → hängt alle Shares aus
# Option 3 (Automount on restart) → schreibt alle Shares in /etc/fstab, wobei uid und gid dynamisch per id -u und id -g ermittelt werden


NAS_HOST="NAS_HOST_NAME.local"
MOUNT_BASE="/mnt/nas"
CREDENTIALS="/etc/samba/credentials_nas"

# Shares, die gemountet werden sollen
SHARES=("book" "data" "music" "photo" "software" "video" "data_encrypt" "cloud")

# UID und GID dynamisch ermitteln
# UID und GID des aufrufenden Benutzers ermitteln (nicht root!)
USER_UID=${SUDO_UID:-$(id -u)}
USER_GID=${SUDO_GID:-$(id -g)}

echo "Was möchtest du tun?"
echo "1 = Mount all (default)"
echo "2 = Unmount all"
echo "3 = Automount on restart (in /etc/fstab eintragen)"
read -p "Auswahl [1/2/3]: " choice

# Standard = 1
choice=${choice:-1}

case $choice in
    1)
        # Prüfen, ob NAS erreichbar ist
        ping -c 1 -W 1 $NAS_HOST > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "NAS ($NAS_HOST) nicht erreichbar – Mounts werden abgebrochen."
            exit 1
        fi

        echo "NAS erreichbar – verbinde Netzlaufwerke..."

        for share in "${SHARES[@]}"; do
            TARGET="$MOUNT_BASE/$share"
            mkdir -p "$TARGET"

            # ggf. vorher aushängen
            if mountpoint -q "$TARGET"; then
                umount "$TARGET"
            fi

            echo "Mounting //$NAS_HOST/$share -> $TARGET"
            mount -t cifs "//$NAS_HOST/$share" "$TARGET" -o credentials=$CREDENTIALS,iocharset=utf8,vers=2.0,nounix,uid=$USER_UID,gid=$USER_GID,file_mode=0664,dir_mode=0775
        done
        ;;

    2)
        echo "Unmounting all NAS shares..."
        for share in "${SHARES[@]}"; do
            TARGET="$MOUNT_BASE/$share"
            if mountpoint -q "$TARGET"; then
                echo "Unmounting $TARGET"
                umount "$TARGET"
            else
                echo "$TARGET ist nicht gemountet."
            fi
        done
        ;;

    3)
        echo "Automount in /etc/fstab eintragen..."
        BACKUP="/etc/fstab.backup.$(date +%Y%m%d%H%M%S)"
        sudo cp /etc/fstab "$BACKUP"
        echo "Backup von /etc/fstab erstellt: $BACKUP"

        # Alte NAS-Zeilen entfernen
        sudo sed -i '/# Synology NAS - Automount Shares/,$d' /etc/fstab

        {
            echo ""
            echo "# Synology NAS - Automount Shares"
            for share in "${SHARES[@]}"; do
                TARGET="$MOUNT_BASE/$share"
                mkdir -p "$TARGET"
                echo "//$NAS_HOST/$share   $TARGET   cifs   credentials=$CREDENTIALS,vers=2.0,iocharset=utf8,uid=$USER_UID,gid=$USER_GID,file_mode=0664,dir_mode=0775,nofail,_netdev,x-systemd.automount   0   0"
            done
        } | sudo tee -a /etc/fstab > /dev/null

        echo "Neue Einträge in /etc/fstab geschrieben."
        echo "Du kannst jetzt mit 'sudo mount -a' testen oder einfach neu starten."
        ;;
    *)
        echo "Ungültige Eingabe."
        exit 1
        ;;
esac

