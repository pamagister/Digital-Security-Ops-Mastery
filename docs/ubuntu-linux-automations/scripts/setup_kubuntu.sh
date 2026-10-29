#!/bin/bash
# Kubuntu 24.04 Setup Script
# Performs system updates, installs programs & tools,
# activates firewall, Flatpak, automatic updates etc.

set -euo pipefail
IFS=$'\n\t'

log() { echo -e "\n=== $1 ===\n"; }

# -----------------------------
# Interactive App Group Selection
# -----------------------------
ask_yn() {
  local prompt="$1"
  local default="${2:-n}"
  local reply
  if [[ "$default" == "y" ]]; then
    prompt="${prompt} [Y/n]: "
  else
    prompt="${prompt} [y/N]: "
  fi
  read -r -p "$prompt" reply || true
  reply="${reply:-$default}"
  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

ask_firefox() {
  local reply
  read -r -p "Firefox? (n = do not install, s = keep status quo, m = switch to Mozilla APT repository) [n/s/m]: " reply || true
  reply="${reply:-n}"
  case "$reply" in
    [mM]) echo "mozilla" ;;
    [sS]) echo "statusquo" ;;
    *) echo "no" ;;
  esac
}

echo ""
echo "=== App Selection ==="
echo "Which app groups should be set up and installed?"
echo ""

INSTALL_DEVELOPER=false
INSTALL_INTERNET=false
INSTALL_FIREFOX="no"
INSTALL_AV=false
INSTALL_SYSTEM=false
INSTALL_SECURITY=false
INSTALL_DESKTOP=false
INSTALL_FLATPAK=false

if ask_yn "Developer (git, build-essential, vim, PyCharm, …) install?"; then INSTALL_DEVELOPER=true; fi
if ask_yn "Internet/Browser (Signal, Nextcloud-Desktop, …) install?"; then INSTALL_INTERNET=true; fi
INSTALL_FIREFOX=$(ask_firefox)
if ask_yn "Audio/Video editing (ffmpeg, kdenlive, vlc, digikam, …) install?"; then INSTALL_AV=true; fi
if ask_yn "System tools/utilities (htop, baobab, keepassxc, veracrypt, …) install?"; then INSTALL_SYSTEM=true; fi
if ask_yn "Security (ufw, ClamAV) install?"; then INSTALL_SECURITY=true; fi
if ask_yn "Desktop/Shell (Zsh + Oh My Zsh, Latte Dock) install?"; then INSTALL_DESKTOP=true; fi
if ask_yn "Flatpak apps (NewPipe, FreeTube) install?"; then INSTALL_FLATPAK=true; fi

echo ""
echo "=== Selection complete. Starting installation... ==="

# -----------------------------
# System Update
# -----------------------------
log "Updating system"
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y


# -----------------------------
# Automatic Updates
# -----------------------------
log "Enabling automatic updates (noninteractive)"
# install unattended-upgrades
sudo apt install -y unattended-upgrades apt-listchanges

# activate automatic Updates
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

log "if you want to activate scheduled auto-updates, run auto-update-setup.sh"

# -----------------------------
# Flatpak + Flathub
# -----------------------------
log "Activating Flatpak + Flathub"
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# -----------------------------
# Developer
# -----------------------------
if $INSTALL_DEVELOPER; then
log "Installing developer tools"

sudo apt install -y git                          # Version control (very common in software projects)
sudo apt install -y subversion                   # Older version control system (SVN)
sudo apt install -y kdesvn                       # KDE frontend for Subversion
sudo apt install -y vim                          # Powerful text editor (console-based)
sudo apt install -y nano                         # Simple text editor (console-based, user-friendly)
sudo apt install -y build-essential              # Basic development tools (gcc, g++, make etc.)
sudo apt install -y software-properties-common   # Additional tools for package sources (e.g. add-apt-repository)

log "Installing PyCharm Community Edition"
sudo snap install pycharm-community --classic || true
if [ -f /var/lib/snapd/desktop/applications/pycharm-community_pycharm-community.desktop ]; then
  cp /var/lib/snapd/desktop/applications/pycharm-community_pycharm-community.desktop ~/.local/share/applications/
fi
fi

# -----------------------------
# Internet / Browser
# -----------------------------
if $INSTALL_INTERNET; then
log "Installing Internet/Browser apps"

# Signal Messenger
wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
wget -qO signal-desktop.sources https://updates.signal.org/static/desktop/signal-desktop.sources
sudo mv signal-desktop.sources /etc/apt/sources.list.d/
sudo apt update
sudo apt install -y signal-desktop

sudo apt install -y nextcloud-desktop # File synchronization with Nextcloud server
fi

# -----------------------------
# Firefox (Mozilla APT)
# -----------------------------
if [[ "$INSTALL_FIREFOX" == "mozilla" ]]; then
log "Installing Firefox from the Mozilla APT repository"

firefox_key_tmp="$(mktemp)"
trap 'rm -f "$firefox_key_tmp"' EXIT
curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o "$firefox_key_tmp"
firefox_key_fingerprint="$(gpg --show-keys --with-colons "$firefox_key_tmp" | awk -F: '$1 == "fpr" { print $10; exit }')"
if [[ "$firefox_key_fingerprint" != "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3" ]]; then
  echo "Mozilla APT signing-key fingerprint verification failed: ${firefox_key_fingerprint:-not found}" >&2
  exit 1
fi
sudo install -d -m 0755 /etc/apt/keyrings
sudo install -m 0644 "$firefox_key_tmp" /etc/apt/keyrings/packages.mozilla.org.asc
rm -f "$firefox_key_tmp"
trap - EXIT

sudo tee /etc/apt/sources.list.d/mozilla.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF

sudo tee /etc/apt/preferences.d/mozilla-firefox >/dev/null <<'EOF'
Package: firefox
Pin: origin packages.mozilla.org
Pin-Priority: 1000

Package: firefox
Pin: release o=Ubuntu
Pin-Priority: -1
EOF

sudo apt update
sudo apt install -y firefox

if command -v snap >/dev/null && snap list firefox >/dev/null 2>&1; then
  if pgrep -x firefox >/dev/null 2>&1; then
    echo "Firefox is running. Close it and rerun the setup before removing the Snap." >&2
    exit 1
  fi
  sudo snap remove firefox
fi

if command -v xdg-settings >/dev/null 2>&1; then
  xdg-settings set default-web-browser firefox.desktop
fi
if command -v xdg-mime >/dev/null 2>&1; then
  xdg-mime default firefox.desktop x-scheme-handler/http x-scheme-handler/https text/html
fi
rm -f ~/.local/share/applications/userapp-Firefox-*.desktop
fi

# -----------------------------
# Audio/Video Editing
# -----------------------------
if $INSTALL_AV; then
log "Installing Audio/Video editing tools"

sudo apt install -y ffmpeg                       # Video encoder
sudo apt install -y kdenlive          # Video editor (KDE/Qt-based)
sudo apt install -y vlc               # Universal media player for audio/video
sudo apt install -y digikam           # Photo management and editing (KDE/Qt-based)
sudo apt install -y imagemagick                  # Tool for image editing, especially via terminal
sudo apt install -y gthumb            # Lightweight image viewer with basic editing
fi

# -----------------------------
# System Tools / Utilities
# -----------------------------
if $INSTALL_SYSTEM; then
log "Installing System tools/utilities"

sudo apt install -y curl                         # Tool for downloading files via HTTP/FTP
sudo apt install -y htop                         # Interactive process and resource monitor
sudo apt install -y unzip                        # Extract .zip files
sudo apt install -y p7zip-full                   # Complete 7-Zip support (e.g. .7z archives)
sudo apt install -y rsync                        # Fast synchronization/copying of files and directories
sudo apt install -y unison                       # Synchronization program
sudo apt install -y unison-gtk                   # Synchronization program, GUI variant
sudo apt install -y gocryptfs                    # Encrypted filesystem in user space (FUSE-based)
sudo apt install -y baobab                       # Disk usage analyzer
sudo apt install -y keepassxc         # Password manager with KeePass format database
sudo apt install -y veracrypt         # Tool for encrypted containers/partitions
sudo apt install -y tipp10            # Learn to write with 10 fingers
fi

# -----------------------------
# Security
# -----------------------------
if $INSTALL_SECURITY; then
log "Activating firewall (ufw)"
sudo apt install -y ufw
# sudo ufw allow OpenSSH   # If SSH is needed
sudo ufw --force enable

log "Installing ClamAV (On-Demand Antivirus Scanner)"
sudo apt install -y clamav clamav-daemon

# Update virus database
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam
fi

# -----------------------------
# Desktop / Shell
# -----------------------------
if $INSTALL_DESKTOP; then
log "Installing Zsh + Oh My Zsh"
sudo apt install -y zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  chsh -s "$(which zsh)"
fi

log "Installing Latte Dock and setting up autostart"
sudo apt install -y latte-dock

mkdir -p ~/.config/autostart
for app in \
  /usr/share/applications/org.kde.latte-dock.desktop \
  /usr/share/applications/signal-desktop.desktop; do
  [ -f "$app" ] && cp "$app" ~/.config/autostart/
done

if [[ "$INSTALL_FIREFOX" == "mozilla" ]]; then
  mkdir -p ~/.config/autostart
  cat <<'EOF' > ~/.config/autostart/firefox.desktop
[Desktop Entry]
Type=Application
Name=Firefox
Exec=sh -c "sleep 10 && exec firefox"
Icon=firefox
X-GNOME-Autostart-enabled=true
EOF
fi
fi

# -----------------------------
# Flatpak Apps
# -----------------------------
if $INSTALL_FLATPAK; then
log "Installing Flatpak apps (NewPipe, FreeTube)"
flatpak install -y flathub net.newpipe.NewPipe io.freetubeapp.FreeTube
fi

# -----------------------------
# Update KDE Menu Cache
# -----------------------------
log "Updating KDE menu cache"
kbuildsycoca5 --noincremental || true


log "Setup completed 🎉"
