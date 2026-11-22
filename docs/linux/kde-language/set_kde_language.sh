#!/bin/bash
# Script: set_kde_language.sh
# Purpose: Use one language for the GUI, another for locale settings (dates, numbers, currency, etc.),
#          including spell checking.

# -----------------------------
# KDE/Plasma language and locale settings
# -----------------------------

# Define your preferred languages/locales here:
GUI_LANG="en_US"
LOCALE_LANG="de_DE"

# Set GUI language
kwriteconfig5 --file kcmfonts --group General --key Language "$GUI_LANG"

# Set date, number, currency, and paper formats
kwriteconfig5 --file kdeglobals --group Locale --key LANG "${LOCALE_LANG}.UTF-8"
kwriteconfig5 --file kdeglobals --group Locale --key LC_TIME "${LOCALE_LANG}.UTF-8"
kwriteconfig5 --file kdeglobals --group Locale --key LC_NUMERIC "${LOCALE_LANG}.UTF-8"
kwriteconfig5 --file kdeglobals --group Locale --key LC_MONETARY "${LOCALE_LANG}.UTF-8"
kwriteconfig5 --file kdeglobals --group Locale --key LC_PAPER "${LOCALE_LANG}.UTF-8"

# Set spell-checking language
kwriteconfig5 --file kdeglobals --group KDE --key SpellCheckingLanguage "$LOCALE_LANG"

# -----------------------------
# Optional: system-wide environment variables
# -----------------------------
PROFILE_FILE="$HOME/.profile"

add_env_var() {
    local VAR="$1"
    local VALUE="$2"
    grep -qxF "export $VAR=$VALUE" "$PROFILE_FILE" || echo "export $VAR=$VALUE" >> "$PROFILE_FILE"
}

add_env_var LANG "${GUI_LANG}.UTF-8"
add_env_var LC_MESSAGES "${GUI_LANG}.UTF-8"
add_env_var LC_TIME "${LOCALE_LANG}.UTF-8"
add_env_var LC_NUMERIC "${LOCALE_LANG}.UTF-8"
add_env_var LC_MONETARY "${LOCALE_LANG}.UTF-8"
add_env_var LC_PAPER "${LOCALE_LANG}.UTF-8"

echo "Done! Please log out and log back in for all changes to take effect."
