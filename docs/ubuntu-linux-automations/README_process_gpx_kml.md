# GPX/KML-Dateien über das Dolphin-Kontextmenü verarbeiten

Mit dem KDE-Dolphin-Kontextmenü lassen sich eine oder mehrere GPX-/KML-Dateien sowie Ordner an `gpx-kml-converter` übergeben. Ordner werden einschließlich aller Unterordner rekursiv durchsucht.

## Voraussetzungen

- Linux mit KDE Plasma und Dolphin
- `konsole`
- `gpx-kml-converter` Version 1.0.9 oder neuer

## Installation

Die Installation besteht aus drei getrennten Schritten. Die Code-Blöcke richten die Installation automatisch ein; unter jedem Schritt steht die manuelle Alternative.

### 1. Abhängigkeiten

`pipx` und `konsole` installieren und anschließend das CLI einrichten:

```bash
sudo apt update
sudo apt install -y pipx konsole
pipx ensurepath
pipx install gpx-kml-converter
```

**Manuell:** `pipx` und `konsole` über die Paketverwaltung installieren. Danach `gpx-kml-converter` mit `pipx install gpx-kml-converter` installieren. Falls `pipx` noch nicht im Suchpfad liegt, ein neues Terminal öffnen.

### 2. Skript und Dolphin-Menüdatei herunterladen

Der Block lädt beide Dateien aus diesem Repository in die benutzerspezifischen Installationsordner:

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
```

**Manuell:** [`process_gpx_kml.sh`](scripts/process_gpx_kml.sh) nach `~/.local/bin/` und [`process_gpx_kml.desktop`](scripts/process_gpx_kml.desktop) nach `~/.local/share/kservices5/ServiceMenus/` kopieren. Die Zielordner bei Bedarf vorher anlegen.

### 3. Pfad anpassen und aktivieren

Der Block setzt den Home-Verzeichnispfad in der Menüdatei, macht das Skript ausführbar und aktualisiert den KDE-Menü-Cache:

```bash
sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/kservices5/ServiceMenus/process_gpx_kml.desktop"
chmod +x "$HOME/.local/bin/process_gpx_kml.sh"
kbuildsycoca5
```

**Manuell:** In `process_gpx_kml.desktop` den Platzhalter `@HOME@` durch den vollständigen Pfad zum Home-Verzeichnis ersetzen. Danach im Terminal `chmod +x ~/.local/bin/process_gpx_kml.sh` ausführen und mit `kbuildsycoca5` das Dolphin-Menü aktualisieren.

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

# Command Line Interface von gpx_kml_converter

Command line options for gpx_kml_converter

```bash
gpx-kml-converter [OPTIONS] <input>
```

For development from a source checkout, the equivalent module invocation is:

```bash
python -m gpx_kml_converter [OPTIONS] <input>
```

## Options

| Option        | Type  | Description                                              | Default    | Choices                                          |
|---------------|-------|----------------------------------------------------------|------------|--------------------------------------------------|
| --config      | str   | Path to configuration file                               | -          | -                                                |
| -v, --verbose | bool  | Enable debug logging                                     | False      | [True, False]                                    |
| -q, --quiet   | bool  | Show warnings and errors only                            | False      | [True, False]                                    |
| `input`       | str   | One or more input paths (GPX, KML, ZIP, or directory)    | *required* | -                                                |
| `--output`    | str   | Output directory; 'auto' creates a timestamped directory | 'auto'     | -                                                |
| `--tolerance` | float | Douglas-Peucker simplification tolerance in meters       | 10.0       | -                                                |
| `--mode`      | str   | Processing operation                                     | 'compress' | ['compress', 'merge', 'extract-pois', 'add-poi'] |
| `--recursive` | bool  | Search input directories recursively                     | False      | [True, False]                                    |
| `--elevation` | bool  | Include elevation data in waypoints                      | True       | [True, False]                                    |


## Examples


### 1. Basic usage

```bash
gpx-kml-converter input
```

### 2. With verbose logging

```bash
gpx-kml-converter -v input
gpx-kml-converter --verbose input
```

### 3. With quiet mode

```bash
gpx-kml-converter -q input
gpx-kml-converter --quiet input
```

### 4. With output parameter

```bash
gpx-kml-converter --output auto input
```

### 5. With tolerance parameter

```bash
gpx-kml-converter --tolerance 10.0 input
```

### 6. With mode parameter

```bash
gpx-kml-converter --mode compress input
```

### Developer usage

```bash
python -m gpx_kml_converter --help
python -m gpx_kml_converter input
```


## Adding a waypoint

Use `--mode add-poi` to append one waypoint to a GPX file. The input must be a single
`.gpx` path; if it does not exist, a new GPX document is created. The waypoint is appended
even if an equivalent waypoint already exists. Latitude, longitude, and name are required;
description, symbol, and elevation are optional.

| Option | Description |
| --- | --- |
| `--lat` | Latitude in decimal degrees, from -90 to 90 |
| `--lon` | Longitude in decimal degrees, from -180 to 180 |
| `--name` | Waypoint name |
| `--desc` | Optional waypoint description |
| `--sym` | Optional waypoint symbol |
| `--ele` | Optional elevation in meters |

In this mode, `--output` is an output GPX file path rather than the output directory used
by the other modes. If omitted, the input file is updated in place.

```bash
gpx-kml-converter --mode add-poi --lat 51.0632 --lon 13.7421 \
  --name "Historic Cafe" \
  --desc "A nice coffee shop with outdoor seating." \
  --sym Coffee --ele 115 input.gpx
```

To create a new file, pass a not-yet-existing `.gpx` path as the input:

```bash
gpx-kml-converter --mode add-poi --lat 48.8584 --lon 2.2945 --name "Eiffel Tower" --desc "A iconic landmark in Paris." --sym Landmark --ele 330 new-pois.gpx
```
