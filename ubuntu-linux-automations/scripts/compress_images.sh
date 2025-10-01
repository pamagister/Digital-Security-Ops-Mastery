#!/bin/bash
# make file executable: chmod +x compress.sh

# Target size
TARGET="500kb"

for file in "$@"; do
    if [[ -f "$file" ]]; then
        echo "Processing: $file"
        dir=$(dirname "$file")
        base=$(basename "$file")
        output="$dir/compressed_$base"

        # Compress without resizing
        convert "$file" -define jpeg:extent=$TARGET "$output"

        echo "Compressed $file -> $output"
    fi
done
