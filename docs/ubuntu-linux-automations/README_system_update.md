# Ubuntu System Update

Update Ubuntu packages, remove packages that are no longer needed, clean the APT cache, and refresh installed Snap and Flatpak applications. Flatpak and Snap updates are skipped when their package managers are not installed.

The script uses `apt full-upgrade`, which may remove packages to complete an upgrade. Review the APT output, and keep backups of important data.

## Requirements

* Ubuntu or a derivative such as Kubuntu
* `sudo` access
* `curl` for the copy-paste installation below

Install `curl` first if it is missing:

```bash
sudo apt install -y curl
```

## Installation

### Copy-paste installation

This installs the script in `~/.local/bin/` and a desktop launcher in `~/.local/share/applications/`:

```bash
set -e
BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
curl -fL "$BASE_URL/scripts/system-update.sh" -o "$HOME/.local/bin/system-update.sh"
curl -fL "$BASE_URL/scripts/system-update.desktop" -o "$HOME/.local/share/applications/system-update.desktop"
sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/applications/system-update.desktop"
chmod +x "$HOME/.local/bin/system-update.sh"
```

### Manual installation

1. Copy [`system-update.sh`](scripts/system-update.sh) to `~/.local/bin/`.
2. Copy [`system-update.desktop`](scripts/system-update.desktop) to `~/.local/share/applications/`.
3. Replace `@HOME@` in `system-update.desktop` with the full path to your home directory.
4. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/system-update.sh
   ```

## Usage

### From the desktop

Open your application launcher and search for **System Update**. A terminal opens and waits for Enter after the update finishes, so the result remains visible.

### From a terminal

Run:

```bash
~/.local/bin/system-update.sh
```

The script asks for your sudo password, then updates APT packages, Snap packages when available, and Flatpak packages when available. A reboot recommendation is shown if Ubuntu indicates one is required.

To keep a terminal window open when launching manually, use:

```bash
~/.local/bin/system-update.sh --pause
```

## What it does

* Refreshes APT package lists and runs `apt full-upgrade`.
* Removes unneeded packages and cleans the APT cache.
* Refreshes Snap and Flatpak packages when those tools are installed.
* Stops and reports an error if an update step fails.
* Reports when a reboot is recommended.
