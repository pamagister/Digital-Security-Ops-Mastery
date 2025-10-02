#!/bin/bash
# Kubuntu 24.04 Setup Script
# Performs system updates, installs programs & tools,
# activates firewall, Flatpak, automatic updates etc.

set -euo pipefail
IFS=$'\n\t'

log() { echo -e "\n=== $1 ===\n"; }

# -----------------------------
# System Update
# -----------------------------
log "Updating system"
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y


# -----------------------------
# Automatic Updates
# -----------------------------
log "Enabling automatic updates (interactive)"
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# -----------------------------
# Auto-update schedule, e.g. Sunday and Wednesday 8 PM:
# -----------------------------

CRON_FILE="/etc/cron.d/apt-weekly"

# Cron job content
CRON_JOB="0 20 * * 0,3 root apt update && apt full-upgrade -y && apt autoremove -y && apt clean"
echo "Setting up system-wide cron job at: $CRON_FILE"

# Write file
sudo bash -c "cat > $CRON_FILE <<EOF
# Automatic updates via cron job:
$CRON_JOB
EOF"

# Set permissions
sudo chmod 644 "$CRON_FILE"

echo "System-wide cron job configured:"
cat "$CRON_FILE"



# -----------------------------
# Flatpak + Flathub
# -----------------------------
log "Activating Flatpak + Flathub"
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# -----------------------------
# Basic Tools
# -----------------------------
log "Installing basic tools"

sudo apt install -y curl                         # Tool for downloading files via HTTP/FTP
sudo apt install -y git                          # Version control (very common in software projects)
sudo apt install -y subversion                   # Older version control system (SVN)
sudo apt install -y ffmpeg                       # Video encoder
sudo apt install -y kdesvn                       # KDE frontend for Subversion
sudo apt install -y htop                         # Interactive process and resource monitor
sudo apt install -y vim                          # Powerful text editor (console-based)
sudo apt install -y nano                         # Simple text editor (console-based, user-friendly)
sudo apt install -y unzip                        # Extract .zip files
sudo apt install -y p7zip-full                   # Complete 7-Zip support (e.g. .7z archives)
sudo apt install -y rsync                        # Fast synchronization/copying of files and directories
sudo apt install -y unison                       # Synchronization program
sudo apt install -y unison-gtk                   # Synchronization program, GUI variant
sudo apt install -y gocryptfs                    # Encrypted filesystem in user space (FUSE-based)
sudo apt install -y build-essential              # Basic development tools (gcc, g++, make etc.)
sudo apt install -y software-properties-common   # Additional tools for package sources (e.g. add-apt-repository)
sudo apt install -y imagemagick                  # Tool for image editing, especially via terminal

# -----------------------------
# Desktop Programs
# -----------------------------
log "Installing desktop programs"

sudo apt install -y firefox           # Web browser (standard in Ubuntu/Kubuntu)
sudo apt install -y keepassxc         # Password manager with KeePass format database
sudo apt install -y kdenlive          # Video editor (KDE/Qt-based)
sudo apt install -y vlc               # Universal media player for audio/video
sudo apt install -y digikam           # Photo management and editing (KDE/Qt-based)
sudo apt install -y veracrypt         # Tool for encrypted containers/partitions
sudo apt install -y nextcloud-desktop # File synchronization with Nextcloud server
sudo apt install -y gthumb            # Lightweight image viewer with basic editing
sudo apt install -y tipp10            # Learn to write with 10 fingers


# -----------------------------
# PyCharm (Snap)
# -----------------------------
log "Installing PyCharm Community Edition"
sudo snap install pycharm-community --classic || true
if [ -f /var/lib/snapd/desktop/applications/pycharm-community_pycharm-community.desktop ]; then
  cp /var/lib/snapd/desktop/applications/pycharm-community_pycharm-community.desktop ~/.local/share/applications/
fi

# -----------------------------
# Flatpak Apps
# -----------------------------
log "Installing Flatpak apps (NewPipe, FreeTube)"
flatpak install -y flathub net.newpipe.NewPipe io.freetubeapp.FreeTube

# -----------------------------
# Firewall
# -----------------------------
log "Activating firewall (ufw)"
sudo apt install -y ufw
# sudo ufw allow OpenSSH   # If SSH is needed
sudo ufw --force enable

# -----------------------------
# Zsh + Oh My Zsh
# -----------------------------
log "Installing Zsh + Oh My Zsh"
sudo apt install -y zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  chsh -s "$(which zsh)"
fi

# -----------------------------
# Signal Messenger
# -----------------------------
log "Installing Signal Messenger"
wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
wget -qO signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources
sudo mv signal-desktop.sources /etc/apt/sources.list.d/
sudo apt update
sudo apt install -y signal-desktop


# -----------------------------
# Latte Dock + Autostart
# -----------------------------
log "Installing Latte Dock and setting up autostart"
sudo apt install -y latte-dock


# -----------------------------
# Add Autostart Apps
# -----------------------------
mkdir -p ~/.config/autostart
for app in \
  /usr/share/applications/org.kde.latte-dock.desktop \
  /usr/share/applications/org.mozilla.firefox.desktop \
  /usr/share/applications/signal-desktop.desktop; do
  [ -f "$app" ] && cp "$app" ~/.config/autostart/
done


# -----------------------------
# ClamAV Antivirus
# -----------------------------
log "Installing ClamAV (On-Demand Antivirus Scanner)"
sudo apt install -y clamav clamav-daemon

# Update virus database
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam


# -----------------------------
# Update KDE Menu Cache
# -----------------------------
log "Updating KDE menu cache"
kbuildsycoca5 --noincremental || true


log "Setup completed 🎉"