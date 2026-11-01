# Process GPX/KML files via the Dolphin context menu

The KDE Dolphin context menu passes one or more GPX/KML files or folders to `gpx-kml-converter`. Folders are searched recursively, including all subfolders.

## ✨ Features

- Process GPX and KML files or folders from the Dolphin context menu.
- Modes: `compress`, `merge`, and `extract-pois`.
- Configurable simplification tolerance.
- Interactive prompts for tolerance and mode.

## ⚙️ Set-Up

### Requirements

- Linux with KDE Plasma and Dolphin.
- `konsole`.
- `gpx-kml-converter` version 1.0.9 or newer.

### Installation

```bash
set -e

command -v gpx-kml-converter >/dev/null || {
    echo "Please install first: pipx install gpx-kml-converter"
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

### Manual installation

1. Install `pipx` and `konsole` via the package manager. Then install `gpx-kml-converter` with `pipx install gpx-kml-converter`. If `pipx` is not yet on the PATH, open a new terminal.
2. Copy [`process_gpx_kml.sh`](scripts/process_gpx_kml.sh) to `~/.local/bin/` and [`process_gpx_kml.desktop`](scripts/process_gpx_kml.desktop) to `~/.local/share/kservices5/ServiceMenus/`. Create the destination directories if needed.
3. Replace `@HOME@` in the desktop file with the full path to your home directory.
4. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/process_gpx_kml.sh
   ```

5. Refresh the Dolphin menu with `kbuildsycoca5`.

## Usage

1. In Dolphin, select one or more GPX/KML files or a folder.
2. Right-click and choose **Process GPX/KML**.
3. In the terminal, enter the simplification tolerance in meters and the desired mode.

The defaults are **10 meters** and **merge**. For folders, `--recursive true` is used. The available modes are `compress`, `merge`, and `extract-pois`. Output files are created according to the CLI's default behavior.

The script can also be started directly in a terminal:

```bash
~/.local/bin/process_gpx_kml.sh route1.gpx route2.kpl
~/.local/bin/process_gpx_kml.sh ~/Tracks
```

It asks only for tolerance and mode. Inputs and the numeric tolerance are validated before invocation; invalid values abort with an error message.

## Command line interface of gpx_kml_converter

Command line options for `gpx-kml-converter`:

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

### Examples

#### 1. Basic usage

```bash
gpx-kml-converter input
```

#### 2. With verbose logging

```bash
gpx-kml-converter -v input
gpx-kml-converter --verbose input
```

#### 3. With quiet mode

```bash
gpx-kml-converter -q input
gpx-kml-converter --quiet input
```

#### 4. With output parameter

```bash
gpx-kml-converter --output auto input
```

#### 5. With tolerance parameter

```bash
gpx-kml-converter --tolerance 10.0 input
```

#### 6. With mode parameter

```bash
gpx-kml-converter --mode compress input
```

#### Developer usage

```bash
python -m gpx_kml_converter --help
python -m gpx_kml_converter input
```

### Adding a waypoint

Use `--mode add-poi` to append one waypoint to a GPX file. The input must be a single `.gpx` path; if it does not exist, a new GPX document is created. The waypoint is appended even if an equivalent waypoint already exists. Latitude, longitude, and name are required; description, symbol, and elevation are optional.

| Option | Description |
|--------|-------------|
| `--lat` | Latitude in decimal degrees, from -90 to 90 |
| `--lon` | Longitude in decimal degrees, from -180 to 180 |
| `--name` | Waypoint name |
| `--desc` | Optional waypoint description |
| `--sym` | Optional waypoint symbol |
| `--ele` | Optional elevation in meters |

In this mode, `--output` is an output GPX file path rather than the output directory used by the other modes. If omitted, the input file is updated in place.

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