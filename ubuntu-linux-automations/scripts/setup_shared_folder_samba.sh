#!/usr/bin/env bash
# ============================================================
#  Brother MFC / Samba Shared Folder Setup Script for Linux
# ============================================================

set -e

# --- 1️⃣ Retrieve user name ---
USERNAME=$(whoami)
echo "Detected user: $USERNAME"

# --- 2️⃣ Prompt for shared folder name ---
read -p "Enter the name of your shared folder [default: shared]: " SHARENAME
SHARENAME=${SHARENAME:-shared}
SHAREPATH="/home/$USERNAME/$SHARENAME"
echo "Folder to be shared: $SHAREPATH"
echo

# --- 3️⃣ Create folder and set permissions ---
echo "Creating shared folder..."
mkdir -p "$SHAREPATH"
sudo chown -R "$USERNAME":"$USERNAME" "$SHAREPATH"
sudo chmod -R 775 "$SHAREPATH"
echo "✅ Folder created and permissions set."
echo

# --- 4️⃣ Install Samba if missing ---
if ! dpkg -l | grep -q samba; then
  echo "Samba not found. Installing Samba..."
  sudo apt update -y
  sudo apt install -y samba
  echo "✅ Samba installed."
else
  echo "✅ Samba already installed."
fi
echo

# --- 5️⃣ Check Samba service status ---
echo "Checking Samba service..."
if systemctl is-active --quiet smbd; then
  echo "✅ Samba service is active."
else
  echo "⚙️  Samba not active. Starting service..."
  sudo systemctl start smbd
fi
echo

# --- 6️⃣ Add share to smb.conf ---
SMB_CONF="/etc/samba/smb.conf"
BACKUP_CONF="/etc/samba/smb.conf.backup_$(date +%Y%m%d%H%M%S)"

echo "Backing up Samba configuration to: $BACKUP_CONF"
sudo cp "$SMB_CONF" "$BACKUP_CONF"

# Check if share already exists
if grep -q "^\[$SHARENAME\]" "$SMB_CONF"; then
  echo "⚠️  A share named [$SHARENAME] already exists in smb.conf. Skipping addition."
else
  echo "Adding new share [$SHARENAME] to smb.conf..."
  sudo bash -c "cat <<EOF >> $SMB_CONF

[$SHARENAME]
   path = $SHAREPATH
   browseable = yes
   writable = yes
   guest ok = no
   valid users = $USERNAME
   create mask = 0664
   directory mask = 0775
EOF"
  echo "✅ Share [$SHARENAME] added to smb.conf."
fi
echo

# --- 7️⃣ Restart Samba ---
echo "Restarting Samba service..."
sudo systemctl restart smbd
sleep 2

# --- 8️⃣ Configure Firewall ---
echo "Configuring firewall to allow Samba..."
if sudo ufw status | grep -q "inactive"; then
  echo "⚠️  UFW firewall is inactive, skipping firewall rule addition."
else
  sudo ufw allow Samba
fi
echo "✅ Firewall configured."
echo

# --- 9️⃣ Verification ---
echo "🔍 Verifying Samba share availability..."
if smbclient -L localhost -U "$USERNAME" 2>/dev/null | grep -q "$SHARENAME"; then
  echo "✅ Verification passed: Share '$SHARENAME' is visible to Samba clients."
else
  echo "❌ Verification failed: Share not visible. Please check /etc/samba/smb.conf."
fi
echo

echo "🎉 Setup complete!"
echo "You can now access your shared folder via:"
echo "   smb://$(hostname)/$SHARENAME"
echo "Shared path on this machine: $SHAREPATH"

# --- 🧭 Print connection info ---

# Detect hostname and IP address
HOSTNAME=$(hostname)
IPADDR=$(hostname -I | awk '{print $1}')

echo "🎉 Setup complete!"
echo
echo "========================================"
echo "✅ Samba share successfully configured!"
echo
echo "📂 Shared folder path (on Linux):"
echo "   $SHAREPATH"
echo
echo "💻 Connect from another Windows machine using one of these:"
echo "   ➜ \\\\$HOSTNAME\\$SHARENAME"
echo "   ➜ \\\\$IPADDR\\$SHARENAME"
echo
echo "   Example (in Windows Explorer):"
echo "     \\\\$HOSTNAME\\$SHARENAME"
echo "   or"
echo "     \\\\$IPADDR\\$SHARENAME"
echo
echo "🧠 Tip: When prompted for credentials, use:"
echo "   Username: $USERNAME"
echo "   Password: (your Linux/Samba password)"
echo "========================================"
