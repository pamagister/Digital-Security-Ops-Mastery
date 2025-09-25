#!/bin/bash
# Kubuntu 24.04 Setup Script
# Führt Systemupdates durch, installiert Programme & Tools,
# aktiviert Firewall, Flatpak, automatische Updates usw.

set -euo pipefail
IFS=$'\n\t'

log() { echo -e "\n=== $1 ===n"; }

# -----------------------------
# Systemupdate
# -----------------------------
log "System wird aktualisiert"
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y


# -----------------------------
# Automatische Updates
# -----------------------------
log "Automatische Updates aktivieren (interaktiv)"
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades


# -----------------------------
# Flatpak + Flathub
# -----------------------------
log "Flatpak + Flathub aktivieren"
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# -----------------------------
# Basis-Werkzeuge
# -----------------------------
log "Basis-Werkzeuge installieren"

sudo apt install -y curl                         # Werkzeug zum Herunterladen von Dateien über HTTP/FTP
sudo apt install -y git                          # Versionsverwaltung (sehr verbreitet bei Softwareprojekten)
sudo apt install -y subversion                   # Älteres Versionsverwaltungssystem (SVN)
sudo apt install -y kdesvn                       # KDE-Frontend für Subversion
sudo apt install -y htop                         # Interaktiver Prozess- und Ressourcenmonitor
sudo apt install -y vim                          # Leistungsfähiger Texteditor (konsolenbasiert)
sudo apt install -y nano                         # Einfacher Texteditor (konsolenbasiert, benutzerfreundlich)
sudo apt install -y unzip                        # Entpacken von .zip-Dateien
sudo apt install -y p7zip-full                   # Vollständige 7-Zip-Unterstützung (z. B. .7z Archive)
sudo apt install -y rsync                        # Schnelles Synchronisieren/Kopieren von Dateien und Verzeichnissen
sudo apt install -y unison                       # Programm zur Synchronisation
sudo apt install -y unison-gtk                   # Programm zur Synchronisation, GUI-Variante
sudo apt install -y gocryptfs                    # Verschlüsseltes Dateisystem in Benutzer-Space (FUSE-basiert)
sudo apt install -y build-essential              # Grundlegende Entwicklungswerkzeuge (gcc, g++, make usw.)
sudo apt install -y software-properties-common   # Zusätzliche Tools für Paketquellen (z. B. add-apt-repository)


# -----------------------------
# Desktop-Programme
# -----------------------------
log "Desktop-Programme installieren"

log "Desktop-Programme installieren"

sudo apt install -y firefox           # Webbrowser (Standard in Ubuntu/Kubuntu)
sudo apt install -y keepassxc         # Passwort-Manager mit Datenbank im KeePass-Format
sudo apt install -y kdenlive          # Video-Editor (KDE/Qt-basiert)
sudo apt install -y vlc               # Universeller Media-Player für Audio/Video
sudo apt install -y digikam           # Fotoverwaltung und -bearbeitung (KDE/Qt-basiert)
sudo apt install -y veracrypt         # Tool für verschlüsselte Container/Partitionen
sudo apt install -y nextcloud-desktop # Synchronisation von Dateien mit einem Nextcloud-Server
sudo apt install -y gthumb            # Leichter Bildbetrachter mit Basisbearbeitung


# -----------------------------
# PyCharm (Snap)
# -----------------------------
log "PyCharm Community Edition installieren"
sudo snap install pycharm-community --classic || true
if [ -f /var/lib/snapd/desktop/applications/pycharm-community_pycharm-community.desktop ]; then
  cp /var/lib/snapd/desktop/applications/pycharm-community_pycharm-community.desktop ~/.local/share/applications/
fi

# -----------------------------
# Flatpak-Apps
# -----------------------------
log "Flatpak-Apps installieren (NewPipe, FreeTube)"
flatpak install -y flathub net.newpipe.NewPipe io.freetubeapp.FreeTube

# -----------------------------
# Firewall
# -----------------------------
log "Firewall (ufw) aktivieren"
sudo apt install -y ufw
# sudo ufw allow OpenSSH   # Falls SSH benötigt
sudo ufw --force enable

# -----------------------------
# Zsh + Oh My Zsh
# -----------------------------
log "Zsh + Oh My Zsh installieren"
sudo apt install -y zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  chsh -s "$(which zsh)"
fi

# -----------------------------
# Signal Messenger
# -----------------------------
log "Signal Messenger installieren"
wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
wget -qO signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources
sudo mv signal-desktop.sources /etc/apt/sources.list.d/
sudo apt update
sudo apt install -y signal-desktop

# -----------------------------
# Latte Dock + Autostart
# -----------------------------
log "Latte Dock installieren und Autostart einrichten"
sudo apt install -y latte-dock


# -----------------------------
# Autostart Apps hinzufügen
# -----------------------------
mkdir -p ~/.config/autostart

for app in \
  /usr/share/applications/org.kde.latte-dock.desktop \
  /usr/share/applications/org.mozilla.firefox.desktop \
  /var/lib/snapd/desktop/applications/signal-desktop.desktop; do
  [ -f "$app" ] && cp "$app" ~/.config/autostart/
done

# -----------------------------
# ClamAV Virenscanner
# -----------------------------
log "ClamAV installieren (On-Demand Virenscanner)"
sudo apt install -y clamav clamav-daemon

# Virendatenbank aktualisieren
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam


# -----------------------------
# KDE Menü Cache aktualisieren
# -----------------------------
log "KDE Menü Cache aktualisieren"
kbuildsycoca5 --noincremental || true

# -----------------------------
# NAS-Mount-Hinweis
# -----------------------------
log "Vorlage für NAS-Mount"
cat << EOF

Um deine Synology NAS automatisch zu mounten:

1. Mountpoint erstellen:
   sudo mkdir -p /mnt/nas

2. Zugangsdaten-Datei:
   nano ~/.smbcredentials
   ---
   username=DEINUSER
   password=DEINPASSWD
   ---
   chmod 600 ~/.smbcredentials

3. In /etc/fstab einfügen:
   //192.168.1.100/Shared /mnt/nas cifs credentials=/home/$USER/.smbcredentials,iocharset=utf8,uid=$(id -u),gid=$(id -g),file_mode=0770,dir_mode=0770,nofail 0 0

EOF

log "Einrichtung abgeschlossen 🎉"
