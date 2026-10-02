# GPX/KML-Dateien über das Dolphin-Kontextmenü verarbeiten

Mit dem KDE-Dolphin-Kontextmenü lassen sich eine oder mehrere GPX-/KML-Dateien sowie Ordner an `gpx-kml-converter` übergeben. Ordner werden einschließlich aller Unterordner rekursiv durchsucht.

## Voraussetzungen

- Linux mit KDE Plasma und Dolphin
- `konsole`
- `gpx-kml-converter` Version 1.0.9 oder neuer

Falls das CLI noch nicht installiert ist:

```bash
pipx install gpx-kml-converter
```

## Installation mit einem Copy-paste-Snippet

Den folgenden Block im Terminal ausführen. Er lädt das Skript und die Dolphin-Service-Menüdatei aus diesem Repository herunter, legt sie im Benutzerverzeichnis ab und aktiviert den Menüeintrag:

```bash
set -e
command -v gpx-kml-converter >/dev/null || {
    echo "Bitte zuerst installieren: pipx install gpx-kml-converter"
    exit 1
}
BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/kservices5/ServiceMenus"
curl -fL "$BASE_URL/scripts/process_gpx_kml.sh" -o "$HOME/.local/bin/process_gpx_kml.sh"
curl -fL "$BASE_URL/scripts/process_gpx_kml.desktop" -o "$HOME/.local/share/kservices5/ServiceMenus/process_gpx_kml.desktop"
sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/kservices5/ServiceMenus/process_gpx_kml.desktop"
chmod +x "$HOME/.local/bin/process_gpx_kml.sh"
kbuildsycoca5
```

`@HOME@` in der Desktop-Datei wird durch den tatsächlichen Pfad zum Home-Verzeichnis ersetzt. Die Dateien können alternativ manuell aus `docs/ubuntu-linux-automations/scripts/` in dieselben Zielverzeichnisse kopiert werden.

## Verwendung

1. In Dolphin eine oder mehrere GPX-/KML-Dateien oder einen Ordner auswählen.
2. Rechtsklicken und **Process GPX/KML** auswählen.
3. Im Terminal die Vereinfachungstoleranz in Metern und den gewünschten Modus eingeben.

Die Voreinstellungen sind **10 Meter** und **merge**. Für Ordner wird rekursiv `--recursive true` verwendet. Die verfügbaren Modi sind `compress`, `merge` und `extract-pois`. Die Ausgabedateien werden vom CLI entsprechend dessen Standardverhalten erstellt.

Das Skript kann auch direkt im Terminal gestartet werden:

```bash
~/.local/bin/process_gpx_kml.sh route1.gpx route2.kml
~/.local/bin/process_gpx_kml.sh ~/Tracks
```

Es fragt ausschließlich nach Toleranz und Modus. Eingaben und numerische Toleranz werden vor dem Aufruf geprüft; ungültige Werte brechen mit einer Fehlermeldung ab.
