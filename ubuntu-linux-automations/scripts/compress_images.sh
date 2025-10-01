#!/bin/bash
# make file executable: chmod +x compress.sh
# Target size
TARGET="500kb"

# Loop over all files dropped onto the script
for file in "$@"; do
    if [[ -f "$file" ]]; then
        dir=$(dirname "$file")
        base=$(basename "$file")
        output="$dir/compressed_$base"

        # Using ImageMagick to compress to target size
        convert "$file" -define jpeg:extent=$TARGET "$output"
        echo "Compressed $file -> $output"
    fi
done
