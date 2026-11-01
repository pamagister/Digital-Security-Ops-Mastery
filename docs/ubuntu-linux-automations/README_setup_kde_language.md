# KDE/Plasma Mixed Language Setup Script

This script configures KDE/Plasma to use **one language for the user interface** (e.g., English) and **another language for regional settings** (e.g., German for dates, numbers, currency, and spell-checking).

## Features

- Set GUI language separately from locale formats.
- Configure KDE/Plasma locale (time, numbers, currency, paper size).
- Configure spell-checking language.
- Optionally set environment variables in `~/.profile` for consistency.

## Set-Up

### Requirements

- KDE Plasma desktop environment.
- `kwriteconfig5` (part of KDE Plasma).

### Installation

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"

mkdir -p "$HOME/.local/bin"

curl -fL "$BASE_URL/scripts/set_kde_language.sh" -o "$HOME/.local/bin/set_kde_language.sh"
chmod +x "$HOME/.local/bin/set_kde_language.sh"
```

### Manual installation

1. Download [`set_kde_language.sh`](scripts/set_kde_language.sh) to `~/.local/bin/`.
2. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/set_kde_language.sh
   ```

## Usage

1. Edit the variables near the top of the script to set your preferred languages:

   ```bash
   GUI_LANG="en_US"   # Interface language
   LOCALE_LANG="de_DE" # Regional/locale settings
   ```

   (for example `fr_FR`, `es_ES`, `ja_JP`). Make sure these locales are installed.

2. Run the script as your regular user (not with `sudo`):

   ```bash
   ~/.local/bin/set_kde_language.sh
   ```

3. Log out and back in to apply changes.

## Example

- **GUI language**: English (`en_US`)
- **Locale settings**: German (`de_DE`)

  → The KDE interface will be in English, but dates, currency, and spell-checking will follow German conventions.

## Notes

- The script modifies KDE configuration via `kwriteconfig5` and appends environment variables to the current user's `~/.profile`; it does not configure the system-wide locale.
- Back up `~/.profile` first if you maintain locale settings there. The script adds entries but does not replace previous conflicting exports.
- Logging out and logging back in ensures that all changes are applied.