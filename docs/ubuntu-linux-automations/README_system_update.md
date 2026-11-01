# Ubuntu System Update

A convenient way to update Ubuntu and Ubuntu-based systems, including APT packages and, when installed, Snap and Flatpak applications.

> **Note:** The script uses `apt-get full-upgrade`, which may remove packages to complete an upgrade. Review the proposed changes and keep backups of important data.

## Features

- Checks the system and APT repositories before upgrading.
- Checks package dependencies and performs a full system upgrade.
- Updates Snap and Flatpak applications when their package managers are available.
- Offers optional cleanup of unused packages, cache files, and Flatpak runtimes.
- Reports detected Flatpak end-of-life runtimes and whether a reboot is required.
- Stops when an update step fails and reports the error.

## Set-Up

### Requirements

- Ubuntu or an Ubuntu-based distribution (for example, Kubuntu).
- `sudo` privileges.
- `curl` for the installation command below.

If `curl` is not installed, install it using your package manager.

### Installation

The following installs the update script, registers its application launcher, and places a separate copy of the launcher in `~/Applications/`.

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
PERSONAL_APP_DIR="$HOME/Applications"

mkdir -p "$BIN_DIR" "$APP_DIR" "$PERSONAL_APP_DIR"

curl -fL "$BASE_URL/scripts/system-update.sh" -o "$BIN_DIR/system-update.sh"

curl -fL "$BASE_URL/scripts/system-update.desktop" -o "$APP_DIR/system-update.desktop"

sed "s|@HOME@|$HOME|g" "$APP_DIR/system-update.desktop" > "$PERSONAL_APP_DIR/System Update.desktop"

chmod +x "$BIN_DIR/system-update.sh"
```

The launcher in `~/.local/share/applications/` is used by the desktop environment. The copy in `~/Applications/` is for convenient access and can also be copied to the desktop.

### Manual installation

1. Download [`system-update.sh`](scripts/system-update.sh) to `~/.local/bin/`.
2. Download [`system-update.desktop`](scripts/system-update.desktop) to `~/.local/share/applications/`.
3. Replace `@HOME@` in the desktop file with your home directory path.
4. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/system-update.sh
   ```

5. Optionally, place a configured copy of the desktop file in `~/Applications/`.

## Usage

### From the application menu

Search for **System Update** in your desktop environment's application launcher. A terminal window opens and remains available until you press Enter.

### From a terminal

```bash
~/.local/bin/system-update.sh
```

Use `--pause` to keep an interactive terminal open after the script finishes:

```bash
~/.local/bin/system-update.sh --pause
```


