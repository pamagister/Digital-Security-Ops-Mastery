#!/bin/bash
# mount_nas.sh

# 1. Create credentials file:
#    sudo nano /etc/samba/credentials_nas
#
# 2. File contents:
#    username=USERNAME
#    password=PASSWORD
#
# 3. Restrict permissions:
#    sudo chmod 600 /etc/samba/credentials_nas
#
# 4. Make this script executable:
#    chmod +x mount_nas.sh
#
# 5. Run this script:
#    sudo ./mount_nas.sh
#
# Options:
#   1. Mount all → mounts all shares (default behavior)
#   2. Unmount all → unmounts all shares
#   3. Automount on restart → adds shares to /etc/fstab with dynamic uid/gid detection


NAS_HOST="NAS_HOST_NAME.local"
MOUNT_BASE="/mnt/nas"
CREDENTIALS="/etc/samba/credentials_nas"

# Shares to be mounted
SHARES=("book" "data" "music" "photo" "software" "video" "data_encrypt" "cloud")

# Detect UID and GID of the calling (non-root) user
USER_UID=${SUDO_UID:-$(id -u)}
USER_GID=${SUDO_GID:-$(id -g)}

echo "What do you want to do?"
echo "1 = Mount all (default)"
echo "2 = Unmount all"
echo "3 = Enable automount on restart (write to /etc/fstab)"
read -p "Select [1/2/3]: " choice

# Default = 1
choice=${choice:-1}

case $choice in
    1)
        # Check if NAS is reachable
        if ! ping -c 1 -W 1 "$NAS_HOST" > /dev/null 2>&1; then
            echo "NAS ($NAS_HOST) not reachable – aborting mounts."
            exit 1
        fi

        echo "NAS reachable – mounting shares..."

        for share in "${SHARES[@]}"; do
            TARGET="$MOUNT_BASE/$share"
            mkdir -p "$TARGET"

            # Unmount first if already mounted
            if mountpoint -q "$TARGET"; then
                umount "$TARGET"
            fi

            echo "Mounting //$NAS_HOST/$share -> $TARGET"
            mount -t cifs "//$NAS_HOST/$share" "$TARGET" \
                -o credentials="$CREDENTIALS",iocharset=utf8,vers=2.0,nounix,uid="$USER_UID",gid="$USER_GID",file_mode=0664,dir_mode=0775
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
                echo "$TARGET is not mounted."
            fi
        done
        ;;

    3)
        echo "Writing automount entries to /etc/fstab..."
        BACKUP="/etc/fstab.backup.$(date +%Y%m%d%H%M%S)"
        sudo cp /etc/fstab "$BACKUP"
        echo "Backup of /etc/fstab created: $BACKUP"

        # Remove old NAS entries
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

        echo "New entries written to /etc/fstab."
        echo "You can now test with 'sudo mount -a' or simply reboot."
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac
