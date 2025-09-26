# Kubuntu Setup Script

A comprehensive automated setup script for Kubuntu 24.04 that installs essential software, configures system security, and sets up a productive desktop environment.

## Overview

This script automates the initial setup of a fresh Kubuntu 24.04 installation by:

- Updating the system and enabling automatic updates
- Installing development tools and desktop applications
- Setting up security features (firewall, antivirus)
- Configuring shell environment (Zsh + Oh My Zsh)
- Installing Flatpak applications and Snap packages

## Prerequisites

- Fresh Kubuntu 24.04 installation
- User account with sudo privileges
- Active internet connection

## Quick Start

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/ubuntu-linux-automations/scripts/setup_kubuntu.sh
   ```
2. **Make it executable:**
   ```bash
   chmod +x kubuntu_setup.sh
   ```

3. **Run the script:**
   ```bash
   ./kubuntu_setup.sh
   ```

## What Gets Installed

### System Updates & Security

- Automatic security updates (unattended-upgrades)
- UFW firewall (enabled by default)
- ClamAV antivirus scanner
- Weekly system update cron job (Sundays & Wednesdays at 8 PM)

### Development Tools

- Git and Subversion version control
- Build essentials (gcc, make, etc.)
- PyCharm Community Edition (via Snap)
- Vim and Nano text editors
- Archive utilities (unzip, 7zip)

### Desktop Applications

- **Browsers**: Firefox
- **Media**: VLC media player, Kdenlive video editor
- **Photography**: digiKam, gThumb image viewer
- **Security**: KeePassXC password manager, VeraCrypt encryption
- **Productivity**: Nextcloud desktop client
- **Communication**: Signal Messenger
- **Desktop Enhancement**: Latte Dock

### Package Managers

- Flatpak with Flathub repository
- Snap packages support

### Shell Environment

- Zsh shell with Oh My Zsh framework
- Enhanced command-line experience

### Autostart Configuration

The script automatically configures these applications to start with the desktop:

- Latte Dock
- Firefox
- Signal Messenger

## Post-Installation Notes

### Manual Steps Required

1. **Reboot or logout/login** to activate Zsh as the default shell
2. **Configure automatic updates** when prompted during installation
3. **Set up your applications** (KeePassXC database, Signal account, etc.)

### Customization

The script can be easily customized by:

- Modifying the application list in each section
- Adjusting the cron schedule for automatic updates
- Adding or removing autostart applications

## Security Considerations

- The firewall is enabled by default with no open ports
- Automatic security updates are configured
- ClamAV provides on-demand virus scanning
- All software is installed from official repositories

## Troubleshooting

### Common Issues

**Script fails during package installation:**
Run `sudo apt update` and try again

**Flatpak applications don't appear in menu:**
Log out and back in, or run `kbuildsycoca5 --noincremental`

**Zsh not set as default shell:**
Reboot or manually run `chsh -s $(which zsh)`

### Manual Fixes

If any step fails, you can run individual sections by copying the relevant commands from the script.

## Contributing

Feel free to submit issues and pull requests to improve this setup script.

## License

This script is released under the MIT License.