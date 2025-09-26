# Kubuntu Setup Script

A comprehensive automated setup script for Kubuntu 24.04 that installs essential software, configures system security, and sets up a productive desktop environment.

## Overview

This script automates the initial setup of a fresh Kubuntu 24.04 installation by:

- Updating the system and enabling automatic updates
- Installing development tools and desktop applications
- Setting up security features (firewall, antivirus)
- Configuring shell environment (Zsh + Oh My Zsh)
- Installing Flatpak applications and Snap packages
- Autostart Configuration: add selected applications automatically to autostart menu

## Prerequisites

- Fresh Kubuntu installation
- User account with sudo privileges
- Active internet connection

## Quick Start

1. **Download the script:**
   ```bash
   wget https://github.com/pamagister/Digital-Security-Ops-Mastery/blob/main/ubuntu-linux-automations/scripts/setup_kubuntu.sh
   ```
2. **Make it executable:**
   ```bash
   chmod +x kubuntu_setup.sh
   ```

3. **Run the script:**
   ```bash
   ./kubuntu_setup.sh
   ```

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