#!/bin/bash

# Default target size
DEFAULT_TARGET="500"

# --- Check ImageMagick ---
if ! command -v convert >/dev/null 2>&1; then
    echo "❌ ImageMagick is not installed."
    echo "Install it with: sudo apt install imagemagick"
    exit 1
fi

# --- Check pngquant (optional but recommended) ---
HAS_PNGQUANT=false
if command -v pngquant >/dev/null 2>&1; then
    HAS_PNGQUANT=true
fi

# --- Ask user for target size ---
read -p "Enter target size in kB (default: $DEFAULT_TARGET): " TARGET
TARGET="${TARGET:-$DEFAULT_TARGET}KB"

# --- Ask user about overwriting ---
read -p "Overwrite original files? [y/N]: " OVERWRITE
OVERWRITE=${OVERWRITE,,}
[[ -z "$OVERWRITE" ]] && OVERWRITE="n"

# --- Process files ---
for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "⚠️ Skipping '$file' (not a file)"
        continue
    fi

    ext="${file##*.}"
    ext="${ext,,}"
    dir=$(dirname "$file")
    base=$(basename "$file" .$ext)

    # Determine output file
    if [[ "$OVERWRITE" == "y" ]]; then
        output="$file"
    else
        output="$dir/${base}_compressed.$ext"
    fi

    echo "🔧 Processing $file with to size $TARGET ..."

    case "$ext" in
        jpg|jpeg)
            echo "📉 Compressing JPG to target size $TARGET..."
            if convert "$file" -define jpeg:extent=$TARGET "$output" 2>/dev/null; then
                echo "✅ Done: $output"
            else
                echo "❌ Failed to compress $file"
            fi
            ;;

        png)
            if $HAS_PNGQUANT; then
                # Use pngquant for real PNG compression
                echo "📉 Compressing PNG using pngquant..."
                temp="$dir/${base}-fs8.png"
                if pngquant --force --output "$temp" "$file"; then
                    if [[ "$OVERWRITE" == "y" ]]; then
                        mv "$temp" "$file"
                        output="$file"
                    else
                        mv "$temp" "$output"
                    fi
                    echo "✅ PNG compressed: $output"
                else
                    echo "❌ pngquant failed, converting to JPG instead..."
                fi


            # If pngquant not available OR jpeg conversion desired:
            else
                echo "🔄 Converting PNG → JPG to meet target size..."
                output_jpg="${output%.*}.jpg"
                if convert "$file" -define jpeg:extent=$TARGET "$output_jpg" 2>/dev/null; then
                    echo "✅ PNG converted + compressed: $output_jpg"
                else
                    echo "❌ Failed to convert/compress PNG $file"
                fi
            fi
            ;;

        *)
            echo "⚠️ Skipping $file (unsupported format)"
            ;;
    esac

done
read -p "Press key to exit " OVERWRITE
