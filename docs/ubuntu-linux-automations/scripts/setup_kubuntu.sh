#!/usr/bin/env bash
#
# Kubuntu 24.04 Setup Script
#
# Features:
#   - Interactive installation groups
#   - Firefox via Snap or official Mozilla APT repository
#   - Safe APT repository and signing-key management
#   - Signal and Nextcloud
#   - Developer tools
#   - Multimedia tools
#   - System utilities
#   - Firewall and ClamAV
#   - Zsh + Oh My Zsh
#   - Flatpak + Flathub
#
# Designed to be safely re-runnable (idempotent).
#
# Usage:
#   chmod +x setup_kubuntu.sh
#   ./setup_kubuntu.sh
#

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="${0##*/}"
readonly MOZILLA_FINGERPRINT="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"
readonly MOZILLA_KEY_URL="https://packages.mozilla.org/apt/repo-signing-key.gpg"
readonly SIGNAL_KEY_URL="https://updates.signal.org/desktop/apt/keys.asc"
readonly SIGNAL_SOURCE_URL="https://updates.signal.org/static/desktop/apt/signal-desktop.sources"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

log() {
    printf '\n=== %s ===\n\n' "$1"
}

info() {
    printf 'INFO: %s\n' "$1"
}

warn() {
    printf 'WARNING: %s\n' "$1" >&2
}

die() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

# ------------------------------------------------------------
# Interactive helpers
# ------------------------------------------------------------

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

    while true; do
        read -r -p \
            "Firefox: s = Snap, m = Mozilla APT, n = unchanged [n]: " \
            reply || true

        reply="${reply:-n}"

        case "$reply" in
            [sS]) printf 'snap\n'; return ;;
            [mM]) printf 'mozilla\n'; return ;;
            [nN]) printf 'none\n'; return ;;
            *) warn "Please enter s, m or n." ;;
        esac
    done
}

# ------------------------------------------------------------
# System checks
# ------------------------------------------------------------

check_system() {
    [[ "$EUID" -ne 0 ]] || die "Do not run this script as root. Use your normal user account."

    command -v sudo >/dev/null 2>&1 || die "sudo is required."

    [[ -f /etc/os-release ]] || die "/etc/os-release not found."

    # shellcheck disable=SC1091
    source /etc/os-release

    [[ "${ID:-}" == "ubuntu" ]] ||
        die "This script is designed for Ubuntu/Kubuntu."

    [[ "${VERSION_ID:-}" == "24.04" ]] ||
        warn "This script was designed for Ubuntu 24.04. Detected: ${VERSION_ID:-unknown}"

    [[ "$(dpkg --print-architecture)" == "amd64" ]] ||
        warn "Some external repositories (especially Signal) may require amd64."

    command -v apt-get >/dev/null 2>&1 ||
        die "apt-get not found."
}

# ------------------------------------------------------------
# APT helpers
# ------------------------------------------------------------

apt_install() {
    local -a available=()
    local package

    for package in "$@"; do
        if apt-cache show "$package" >/dev/null 2>&1; then
            available+=("$package")
        else
            warn "Package not available: $package (skipping)"
        fi
    done

    if ((${#available[@]})); then
        sudo apt-get install -y "${available[@]}"
    fi
}

# ------------------------------------------------------------
# Firefox helpers
# ------------------------------------------------------------

firefox_running() {
    pgrep -u "$UID" -x firefox >/dev/null 2>&1
}

check_firefox_closed() {
    if firefox_running; then
        die "Firefox is running. Close all Firefox windows and rerun the script."
    fi
}

snap_firefox_installed() {
    command -v snap >/dev/null 2>&1 &&
        snap list firefox >/dev/null 2>&1
}

apt_firefox_installed() {
    dpkg-query -W -f='${Status}' firefox 2>/dev/null |
        grep -q 'install ok installed'
}

remove_mozilla_apt_configuration() {
    log "Removing Mozilla APT repository configuration"

    sudo rm -f \
        /etc/apt/sources.list.d/mozilla.list \
        /etc/apt/sources.list.d/mozilla.sources \
        /etc/apt/sources.list.d/mozilla-firefox.sources \
        /etc/apt/preferences.d/mozilla \
        /etc/apt/preferences.d/mozilla-firefox
}

set_default_firefox() {
    local desktop_id=""

    if [[ -f /var/lib/snapd/desktop/applications/firefox_firefox.desktop ]]; then
        desktop_id="firefox_firefox.desktop"
    elif [[ -f /usr/share/applications/firefox.desktop ]]; then
        desktop_id="firefox.desktop"
    fi

    if [[ -n "$desktop_id" ]]; then
        if command -v xdg-settings >/dev/null 2>&1; then
            xdg-settings set default-web-browser "$desktop_id" || true
        fi

        if command -v xdg-mime >/dev/null 2>&1; then
            xdg-mime default "$desktop_id" \
                x-scheme-handler/http \
                x-scheme-handler/https \
                text/html || true
        fi
    else
        warn "Could not locate Firefox desktop entry. Set the default browser manually."
    fi
}

migrate_firefox_profile() {
    local source_dir="$1"
    local target_dir="$2"
    local source_file

    [[ -d "$source_dir" ]] || return 0

    if [[ -d "$target_dir" ]] &&
        find "$target_dir" -mindepth 1 -maxdepth 1 -print -quit |
            grep -q .; then

        warn "Firefox profile already exists at $target_dir."
        warn "Automatic migration skipped to avoid overwriting existing data."
        return 0
    fi

    log "Migrating Firefox profile"

    mkdir -p "$target_dir"

    # Copy all profile files, including hidden files.
    cp -a "$source_dir/." "$target_dir/"

    info "Firefox profile copied successfully."
}

configure_firefox_mozilla() {
    local key_file="$TMP_DIR/mozilla-key.gpg"
    local fingerprint

    check_firefox_closed

    log "Configuring official Mozilla APT repository"

    sudo install -d -m 0755 /etc/apt/keyrings

    curl -fsSL "$MOZILLA_KEY_URL" -o "$key_file"

    fingerprint="$(
        gpg --show-keys --with-colons "$key_file" |
            awk -F: '$1 == "fpr" { print $10; exit }'
    )"

    [[ "$fingerprint" == "$MOZILLA_FINGERPRINT" ]] ||
        die "Mozilla signing-key fingerprint verification failed: ${fingerprint:-not found}"

    info "Mozilla signing key verified."

    sudo install -m 0644 "$key_file" \
        /etc/apt/keyrings/packages.mozilla.org.asc

    # Remove old or incorrectly configured Mozilla sources.
    sudo rm -f \
        /etc/apt/sources.list.d/mozilla.list \
        /etc/apt/sources.list.d/mozilla.sources

    sudo tee /etc/apt/sources.list.d/mozilla-firefox.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF

    # Prefer Mozilla Firefox and prevent Ubuntu's Snap transition package.
    sudo tee /etc/apt/preferences.d/mozilla-firefox >/dev/null <<'EOF'
Package: firefox
Pin: origin packages.mozilla.org
Pin-Priority: 1000

Package: firefox
Pin: release o=Ubuntu
Pin-Priority: -1
EOF

    sudo apt-get update
    sudo apt-get install -y firefox

    # Preserve the existing Snap profile if no DEB profile exists.
    if snap_firefox_installed; then
        migrate_firefox_profile \
            "$HOME/snap/firefox/common/.mozilla/firefox" \
            "$HOME/.mozilla/firefox"

        log "Removing Firefox Snap"
        sudo snap remove firefox
    fi

    set_default_firefox

    info "Firefox is now managed by Mozilla APT."
}

configure_firefox_snap() {
    check_firefox_closed

    log "Configuring Firefox Snap"

    # Remove Mozilla APT configuration first to avoid package conflicts.
    remove_mozilla_apt_configuration

    sudo apt-get update

    # Remove a previously installed Mozilla DEB version.
    if apt_firefox_installed; then
        sudo apt-get remove -y firefox
    fi

    if ! command -v snap >/dev/null 2>&1; then
        log "Installing Snap support"
        sudo apt-get install -y snapd
    fi

    if ! snap_firefox_installed; then
        sudo snap install firefox
    else
        info "Firefox Snap is already installed."
    fi

    # Preserve an existing Mozilla DEB profile if no Snap profile exists.
    migrate_firefox_profile \
        "$HOME/.mozilla/firefox" \
        "$HOME/snap/firefox/common/.mozilla/firefox"

    set_default_firefox

    info "Firefox is now managed by Snap."
}

configure_firefox() {
    case "$INSTALL_FIREFOX" in
        mozilla)
            configure_firefox_mozilla
            ;;
        snap)
            configure_firefox_snap
            ;;
        none)
            info "Firefox configuration left unchanged."
            ;;
    esac
}

# ------------------------------------------------------------
# Signal repository
# ------------------------------------------------------------

configure_signal_repository() {
    local key_asc="$TMP_DIR/signal-key.asc"
    local key_gpg="$TMP_DIR/signal-key.gpg"
    local source_file="$TMP_DIR/signal-desktop.sources"

    [[ "$(dpkg --print-architecture)" == "amd64" ]] ||
        die "Signal's official APT repository requires amd64."

    log "Configuring Signal APT repository"

    sudo apt-get install -y ca-certificates curl gnupg

    curl -fsSL "$SIGNAL_KEY_URL" -o "$key_asc"

    gpg --dearmor --yes --output "$key_gpg" "$key_asc"

    [[ -s "$key_gpg" ]] || die "Signal signing key is empty."

    sudo install -d -m 0755 /usr/share/keyrings

    sudo install -m 0644 "$key_gpg" \
        /usr/share/keyrings/signal-desktop-keyring.gpg

    # Use Signal's official Deb822 source definition.
    curl -fsSL "$SIGNAL_SOURCE_URL" -o "$source_file"

    grep -Fq 'updates.signal.org/desktop/apt' "$source_file" ||
        die "Downloaded Signal source file does not contain the expected repository URL."

    grep -Fq 'signal-desktop-keyring.gpg' "$source_file" ||
        die "Downloaded Signal source file does not reference the expected signing key."

    sudo install -m 0644 "$source_file" \
        /etc/apt/sources.list.d/signal-desktop.sources

    # Remove the legacy source created by previous script versions.
    sudo rm -f /etc/apt/sources.list.d/signal-desktop.list

    sudo apt-get update
    sudo apt-get install -y signal-desktop

    info "Signal repository configured successfully."
}

# ------------------------------------------------------------
# Initial system setup
# ------------------------------------------------------------

check_system

log "App Selection"

INSTALL_DEVELOPER=false
INSTALL_INTERNET=false
INSTALL_AV=false
INSTALL_SYSTEM=false
INSTALL_SECURITY=false
INSTALL_DESKTOP=false
INSTALL_FLATPAK=false

if ask_yn "Developer tools (Git, build-essential, PyCharm, ...)"; then
    INSTALL_DEVELOPER=true
fi

if ask_yn "Internet / Browser apps (Signal, Nextcloud, ...)"; then
    INSTALL_INTERNET=true
fi

INSTALL_FIREFOX="$(ask_firefox)"

if ask_yn "Audio / Video tools (FFmpeg, Kdenlive, VLC, digiKam, ...)"; then
    INSTALL_AV=true
fi

if ask_yn "System utilities (htop, KeePassXC, VeraCrypt, ...)"; then
    INSTALL_SYSTEM=true
fi

if ask_yn "Security tools (UFW, ClamAV)"; then
    INSTALL_SECURITY=true
fi

if ask_yn "Desktop / Shell (Zsh, Oh My Zsh, Latte Dock)"; then
    INSTALL_DESKTOP=true
fi

if ask_yn "Flatpak applications (NewPipe, FreeTube)"; then
    INSTALL_FLATPAK=true
fi

log "Selection complete"

# Cache sudo credentials before starting.
sudo -v

# ------------------------------------------------------------
# System update
# ------------------------------------------------------------

log "Updating system"

sudo apt-get update
sudo apt-get upgrade -y

# ------------------------------------------------------------
# Basic dependencies
# ------------------------------------------------------------

log "Installing basic dependencies"

apt_install \
    ca-certificates \
    curl \
    wget \
    gnupg \
    software-properties-common

# ------------------------------------------------------------
# Automatic updates
# ------------------------------------------------------------

log "Enabling automatic updates"

apt_install unattended-upgrades apt-listchanges

sudo dpkg-reconfigure -f noninteractive unattended-upgrades

info "Automatic security updates enabled."
info "For scheduled update configuration, use auto-update-setup.sh."

# ------------------------------------------------------------
# Developer tools
# ------------------------------------------------------------

if "$INSTALL_DEVELOPER"; then
    log "Installing developer tools"

    apt_install \
        git \
        npm \
        subversion \
        kdesvn \
        vim \
        nano \
        build-essential \
        software-properties-common

    log "Installing PyCharm Community Edition"

    if ! command -v snap >/dev/null 2>&1; then
        sudo apt-get install -y snapd
    fi

    if snap list pycharm-community >/dev/null 2>&1; then
        info "PyCharm Community is already installed."
    else
        sudo snap install pycharm-community --classic
    fi

    mkdir -p "$HOME/.local/share/applications"

    if [[ -f /var/lib/snapd/desktop/applications/pycharm-community_pycharm-community.desktop ]]; then
        cp /var/lib/snapd/desktop/applications/pycharm-community_pycharm-community.desktop \
            "$HOME/.local/share/applications/"
    fi
fi

# ------------------------------------------------------------
# Internet / Browser
# ------------------------------------------------------------

if "$INSTALL_INTERNET"; then
    log "Installing Internet / Browser apps"

    configure_signal_repository

    apt_install nextcloud-desktop
fi

# ------------------------------------------------------------
# Firefox
# ------------------------------------------------------------

configure_firefox

# ------------------------------------------------------------
# Audio / Video
# ------------------------------------------------------------

if "$INSTALL_AV"; then
    log "Installing Audio / Video tools"

    apt_install \
        ffmpeg \
        kdenlive \
        vlc \
        digikam \
        imagemagick \
        gthumb \
        yt-dlp
fi

# ------------------------------------------------------------
# System tools
# ------------------------------------------------------------

if "$INSTALL_SYSTEM"; then
    log "Installing System utilities"

    apt_install \
        curl \
        htop \
        unzip \
        p7zip-full \
        rsync \
        unison \
        unison-gtk \
        gocryptfs \
        baobab \
        keepassxc \
        veracrypt \
        tipp10 \
        partitionmanager \
        skanlite
fi

# ------------------------------------------------------------
# Security
# ------------------------------------------------------------

if "$INSTALL_SECURITY"; then
    log "Installing and configuring firewall"

    apt_install ufw

    # Avoid locking out an active SSH session.
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        sudo ufw allow OpenSSH
    fi

    sudo ufw --force enable

    log "Installing ClamAV"

    apt_install clamav clamav-daemon

    # Let the freshclam service manage database updates.
    sudo systemctl enable --now clamav-freshclam
    sudo systemctl enable --now clamav-daemon
fi

# ------------------------------------------------------------
# Desktop / Shell
# ------------------------------------------------------------

if "$INSTALL_DESKTOP"; then
    log "Installing Zsh + Oh My Zsh"

    apt_install zsh

    ZSH_PATH="$(command -v zsh)"

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        info "Oh My Zsh is already installed."
    fi

    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

    if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
        if ask_yn "Set Zsh as the default login shell?"; then
            chsh -s "$ZSH_PATH"
        fi
    fi

    log "Installing Latte Dock"

    apt_install latte-dock

    # Add Latte Dock to the user's autostart, if available.
    mkdir -p "$HOME/.config/autostart"

    if [[ -f /usr/share/applications/org.kde.latte-dock.desktop ]]; then
        cp /usr/share/applications/org.kde.latte-dock.desktop \
            "$HOME/.config/autostart/"
    fi
fi

# ------------------------------------------------------------
# Flatpak
# ------------------------------------------------------------

if "$INSTALL_FLATPAK"; then
    log "Installing Flatpak + Flathub"

    apt_install flatpak plasma-discover-backend-flatpak

    flatpak remote-add --user --if-not-exists \
        flathub https://flathub.org/repo/flathub.flatpakrepo

    log "Installing Flatpak applications"

    flatpak install --user -y flathub \
        net.newpipe.NewPipe \
        io.freetubeapp.FreeTube
fi

# ------------------------------------------------------------
# Update KDE menu cache
# ------------------------------------------------------------

log "Updating KDE menu cache"

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 --noincremental
else
    warn "KDE menu cache utility not found."
fi

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------

log "Setup completed"

info "All selected installation tasks have finished."
info "No automatic APT autoremove was performed."
info "A reboot may be useful after system and desktop changes."
