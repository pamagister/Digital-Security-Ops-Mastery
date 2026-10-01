# Kubuntu Setup Script

A comprehensive automated setup script for Kubuntu 24.04 that installs essential software, configures system security, and sets up a productive desktop environment.

## ✨ Overview

This script automates the initial setup of a fresh Kubuntu 24.04 installation by:

- Updating the system and enabling automatic updates
- Installing development tools and desktop applications
- Setting up security features (firewall, antivirus)
- Configuring shell environment (Zsh + Oh My Zsh)
- Installing Flatpak applications and Snap packages
- Autostart Configuration: add selected applications automatically to autostart menu

## 📥 Prerequisites

- Fresh Kubuntu installation
- User account with sudo privileges
- Active internet connection

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
3. **Set up your applications** (KeePassXC database, Signal account, etc.)

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

## Contributing

Feel free to submit issues and pull requests to improve this setup script.

## License

This script is released under the MIT License.