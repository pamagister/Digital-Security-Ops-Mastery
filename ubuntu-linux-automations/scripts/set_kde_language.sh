#!/bin/bash
# Script: set_kde_language.sh
# Zweck: GUI auf Englisch, Rest auf Deutsch, inklusive Rechtschreibprüfung

# -----------------------------
# KDE/Plasma Sprach- und Formateinstellungen
# -----------------------------

# Setze GUI-Sprache auf Englisch
kwriteconfig5 --file kcmfonts --group General --key Language en_US

# Setze Datums-, Zahlen-, Währungs- und Papierformate auf Deutsch
kwriteconfig5 --file kdeglobals --group Locale --key LANG de_DE.UTF-8
kwriteconfig5 --file kdeglobals --group Locale --key LC_TIME de_DE.UTF-8
kwriteconfig5 --file kdeglobals --group Locale --key LC_NUMERIC de_DE.UTF-8
kwriteconfig5 --file kdeglobals --group Locale --key LC_MONETARY de_DE.UTF-8
kwriteconfig5 --file kdeglobals --group Locale --key LC_PAPER de_DE.UTF-8

# Setze Rechtschreibprüfung auf Deutsch
kwriteconfig5 --file kdeglobals --group KDE --key SpellCheckingLanguage de_DE

# -----------------------------
# Optional: Systemweite Umgebungsvariablen
# -----------------------------
PROFILE_FILE="$HOME/.profile"

grep -qxF "export LANG=en_US.UTF-8" "$PROFILE_FILE" || echo "export LANG=en_US.UTF-8" >> "$PROFILE_FILE"
grep -qxF "export LC_MESSAGES=en_US.UTF-8" "$PROFILE_FILE" || echo "export LC_MESSAGES=en_US.UTF-8" >> "$PROFILE_FILE"
grep -qxF "export LC_TIME=de_DE.UTF-8" "$PROFILE_FILE" || echo "export LC_TIME=de_DE.UTF-8" >> "$PROFILE_FILE"
grep -qxF "export LC_NUMERIC=de_DE.UTF-8" "$PROFILE_FILE" || echo "export LC_NUMERIC=de_DE.UTF-8" >> "$PROFILE_FILE"
grep -qxF "export LC_MONETARY=de_DE.UTF-8" "$PROFILE_FILE" || echo "export LC_MONETARY=de_DE.UTF-8" >> "$PROFILE_FILE"
grep -qxF "export LC_PAPER=de_DE.UTF-8" "$PROFILE_FILE" || echo "export LC_PAPER=de_DE.UTF-8" >> "$PROFILE_FILE"

echo "Fertig! Bitte abmelden und wieder anmelden, damit alle Änderungen greifen."

