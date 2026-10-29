# Kubuntu Setup Script

A comprehensive automated setup script for Kubuntu 24.04 that installs essential software, configures system security, and sets up a productive desktop environment.

## ✨ Overview

This script automates the initial setup of a fresh Kubuntu 24.04 installation by:

- Updating the system and enabling automatic updates
- Installing development tools and desktop applications
- Installing Firefox from Mozilla's signed APT repository and preferring that package over Ubuntu's transitional Snap package
- Setting up security features (firewall, antivirus)
- Configuring shell environment (Zsh + Oh My Zsh)
- Installing Flatpak applications and Snap packages
- Configuring selected applications, including Firefox, to start automatically at login

## 📱 Interactive App Selection

At startup, the script asks which app groups should be set up and installed. All prompts come first; only afterwards are the selected packages installed in one batch.

| Group | Included Programs |
|-------|------------------|
| **Developer** | git, subversion, kdesvn, vim, nano, build-essential, software-properties-common, PyCharm (Snap) |
| **Internet / Browser** | Signal Messenger, Nextcloud-Desktop |
| **Firefox** (separate) | Do not install / keep status quo / switch to Mozilla APT repository (incl. Snap removal, default browser, autostart) |
| **Audio/Video Editing** | ffmpeg, kdenlive, vlc, digikam, imagemagick, gthumb |
| **System Tools / Utilities** | curl, htop, unzip, p7zip-full, rsync, unison, unison-gtk, gocryptfs, **baobab**, keepassxc, veracrypt, tipp10 |
| **Security** | ufw (Firewall), ClamAV (Antivirus) |
| **Desktop / Shell** | Zsh + Oh My Zsh, Latte Dock (+ Autostart) |
| **Flatpak Apps** | NewPipe, FreeTube |

System update, automatic updates, and the Flatpak/Flathub base are always executed.

### Firefox

Kubuntu ships Firefox as a Snap by default. The options are:

- **n** – Do not install Firefox (no changes to an existing Firefox)
- **s** – Keep status quo (the script does not actively modify Firefox)
- **m** – Switch to Mozilla APT repository (current Firefox version, Snap is removed, Firefox becomes default browser and is added to autostart)

## 📥 Prerequisites

- Fresh Kubuntu installation
- User account with sudo privileges
- Active internet connection
- The setup verifies Mozilla's APT signing-key fingerprint before adding the repository

## 🚀 Quick Start

1. **Download the script:**
   ```bash
   curl -fL -o setup_kubuntu.sh https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations/scripts/setup_kubuntu.sh
   ```
2. **Make it executable:**
   ```bash
   chmod +x setup_kubuntu.sh
   ```

3. **Run the script:**
   ```bash
   ./setup_kubuntu.sh
   ```

## ⚙️ Post-Installation Notes

### Manual Steps Required

1. **Reboot or logout/login** to activate Zsh as the default shell
2. Review the automatic-update settings; the script enables `unattended-upgrades` and mentions an optional separate scheduling script.
3. If Firefox was already open, close it and rerun the setup when prompted; the script does not remove a running Firefox Snap.
4. **Set up your applications** (Firefox profile, KeePassXC database, Signal account, etc.)

### Customization

The script can be easily customized by:

- Modifying the application list in each section
- Adding or removing autostart applications

## Security Considerations

- UFW is enabled with its existing default rules; check them before relying on the firewall.
- Automatic security updates are enabled, but the script also installs software from Snap, Flathub, and Signal's package repository.
- ClamAV provides on-demand virus scanning
- Review the script before running it: it installs software, changes system settings, adds an external Signal repository, and configures shell startup.

## 📝 Troubleshooting

### Common Issues

**Script fails during package installation:**
Review the failing package command, run `sudo apt update`, then retry the relevant step.

**Flatpak applications don't appear in menu:**
Log out and back in, or run `kbuildsycoca5 --noincremental`

**Zsh not set as default shell:**
Reboot or manually run `chsh -s $(which zsh)`

### Manual Fixes

If any step fails, you can run individual sections by copying the relevant commands from the script.

### Firefox launcher after changing package source

Firefox is installed from Mozilla's APT repository, not Ubuntu's transitional Snap package. The setup removes the Snap only after the APT package installs successfully. If an old KDE panel launcher still has a blank icon, remove that pinned launcher and pin **Firefox** again from the application menu; do not pin a launcher whose command contains a versioned `/snap/firefox/<revision>/` path.

## Contributing

Feel free to submit issues and pull requests to improve this setup script.

## License

This script is released under the MIT License.