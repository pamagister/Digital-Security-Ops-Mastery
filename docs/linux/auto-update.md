# Automatic security updates

`auto-update-setup.sh` configures Ubuntu/Debian `unattended-upgrades` for automatic security and update installation. It also enables automatic reboots.

> **Warning:** This script overwrites `/etc/apt/apt.conf.d/50unattended-upgrades`, enables automatic reboots, and restarts the unattended-upgrades service. Review the script and back up existing configuration before running it. Do not use it on a device that must not reboot without supervision.

## ✨ Features

- Installs `unattended-upgrades` and `apt-listchanges`.
- Enables the unattended-upgrades systemd timer/service.
- Writes a minimal `20auto-upgrades` configuration.
- Writes a `50unattended-upgrades` configuration with security and update origins.
- Enables automatic reboots at 03:30 with `Automatic-Reboot-WithUsers=false`.
- Runs a dry-run check after configuration.

## ⚙️ Set-Up

### 📋 Requirements

- Ubuntu or an Ubuntu-based distribution with APT.
- `sudo` privileges.
- An active internet connection.
- A device that may be rebooted automatically.

### 📦 Installation

Download and inspect the script first:

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/linux/scripts"

curl -fL "$BASE_URL/auto-update-setup.sh" -o /tmp/auto-update-setup.sh
less /tmp/auto-update-setup.sh
```

Run it with `sudo`:

```bash
sudo bash /tmp/auto-update-setup.sh
```

### 🔩 Manual installation

1. Download [`auto-update-setup.sh`](scripts/auto-update-setup.sh).
2. Review the configuration it writes, especially the automatic-reboot settings.
3. Back up the existing files:

   ```bash
   sudo cp /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades.backup 2>/dev/null || true
   sudo cp /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.backup 2>/dev/null || true
   ```

4. Run the script with `sudo bash auto-update-setup.sh`.

## 🚀 Usage

Check the current state:

```bash
systemctl status unattended-upgrades
unattended-upgrade --dry-run --debug
```

Review the log:

```bash
less /var/log/unattended-upgrades/unattended-upgrades.log
```

## 📝 Notes / Warnings

- The script replaces the existing `50unattended-upgrades` file. It does not merge with a customized configuration.
- Automatic reboots are enabled. Adjust `Unattended-Upgrade::Automatic-Reboot` and `Automatic-Reboot-Time` in `/etc/apt/apt.conf.d/50unattended-upgrades` if that is not acceptable.
- The script enables unattended upgrades for the configured distribution origins. Review the origins before running it on a customized system.
- A dry run does not prove that every package will upgrade cleanly. Keep backups and test on a non-critical system first.
- The script does not configure desktop notifications or monitoring.