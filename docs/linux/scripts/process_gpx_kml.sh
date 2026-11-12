#!/usr/bin/env bash

set -euo pipefail

DEFAULT_TOLERANCE=10
DEFAULT_MODE=merge

if ! command -v gpx-kml-converter >/dev/null 2>&1; then
    echo "gpx-kml-converter was not found. Install it with: pipx install gpx-kml-converter" >&2
    exit 1
fi

if (( $# == 0 )); then
    echo "Usage: $0 <GPX/KML file or directory> [additional files or directories ...]" >&2
    exit 2
fi

for input in "$@"; do
    if [[ ! -f "$input" && ! -d "$input" ]]; then
        echo "Input does not exist or is not a file or directory: $input" >&2
        exit 2
    fi
done

read -r -p "Tolerance in meters [$DEFAULT_TOLERANCE]: " tolerance
tolerance="${tolerance:-$DEFAULT_TOLERANCE}"
if [[ ! "$tolerance" =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk -v value="$tolerance" 'BEGIN { exit !(value > 0) }'; then
    echo "Tolerance must be a positive number of meters." >&2
    exit 2
fi

read -r -p "Mode (compress/merge/extract-pois) [$DEFAULT_MODE]: " mode
mode="${mode:-$DEFAULT_MODE}"
case "$mode" in
    compress|merge|extract-pois) ;;
    *)
        echo "Mode must be compress, merge, or extract-pois." >&2
        exit 2
        ;;
esac

exec gpx-kml-converter --tolerance "$tolerance" --mode "$mode" --recursive true "$@"
