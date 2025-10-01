#!/bin/bash

# Default target size
DEFAULT_TARGET="500kb"

# --- Check if ImageMagick is installed ---
if ! command -v convert >/dev/null 2>&1; then
    echo "❌ ImageMagick is not installed."
    echo "Install it with: sudo apt install imagemagick"
    exit 1
fi

# --- Ask user for target size ---
read -p "Enter target size in kB (default: $DEFAULT_TARGET): " TARGET
TARGET="${TARGET:-$DEFAULT_TARGET}"

# --- Ask user about overwriting ---
read -p "Overwrite original files? [y/N]: " OVERWRITE
OVERWRITE=${OVERWRITE,,}   # lowercase
[[ -z "$OVERWRITE" ]] && OVERWRITE="n"

# --- Process each file ---
for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "⚠️ Skipping '$file' (not a file)"
        continue
    fi

    ext="${file##*.}"
    case "${ext,,}" in
        jpg|jpeg|png)
            dir=$(dirname "$file")
            base=$(basename "$file")
            if [[ "$OVERWRITE" == "y" ]]; then
                output="$file"
            else
                output="${dir}/${base%.*}_compressed.${base##*.}"
            fi

            echo "🔧 Compressing $file -> $output (target $TARGET)..."
            if convert "$file" -define jpeg:extent=$TARGET "$output" 2>/dev/null; then
                echo "✅ Done: $output"
            else
                echo "❌ Failed to compress $file"
                continue
            fi
            ;;
        *)
            echo "⚠️ Skipping $file (unsupported format)"
            ;;
    esac
done
