# KDE/Plasma Mixed Language Setup Script

This script configures KDE/Plasma to use **one language for the user interface** (e.g., English) and **another language for regional settings** (e.g., German for dates, numbers, currency, and spell-checking).  

## ✨ Features
- Set GUI language separately from locale formats  
- Configure KDE/Plasma locale (time, numbers, currency, paper size)  
- Configure spell-checking language  
- Optionally set environment variables in `~/.profile` for consistency  

## Usage

1. Edit the variables at the top of the script to set your preferred languages:
   ```bash
   wget https://github.com/pamagister/Digital-Security-Ops-Mastery/blob/main/ubuntu-linux-automations/scripts/set_kde_language.sh
   ```

2. Edit the variables at the top of the script to set your preferred languages:
   ```bash
   GUI_LANG="en_US"   # Interface language
   LOCALE_LANG="de_DE" # Regional/locale settings
   ```
   (like `fr_FR`, `es_ES`, `ja_JP`)

2. Run the script:
   ```bash
   ./set_kde_language.sh
   ```

3. Log out and back in to apply changes.

## Example

* **GUI language**: English (`en_US`)
* **Locale settings**: German (`de_DE`)
  → The KDE interface will be in English, but dates, currency, and spell-checking will follow German conventions.

## Notes

* The script modifies KDE configs via `kwriteconfig5`.
* For full effect, it also appends environment variables to `~/.profile`.
* Logging out and logging back in ensures that all changes are applied.

