#!/bin/bash

#######################################
# User-configurable settings
#######################################
VIDEO_FOLDER="$HOME/Videos"   # Root folder to search for videos
CRF=32                        # Constant Rate Factor (lower = better quality, 18–28 typical)
PRESET="slower"                 # Preset: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
BITRATE="1000k"               # Target video bitrate (~7 Mbps for ~50MB/min Full HD)
AUDIO_BITRATE="192k"          # Audio bitrate
SUFFIX="_comp"                # Suffix for compressed files
SUFFIX_PROCESSED=""                # Suffix for processed files
CODEC="libx264"               # Video codec

#######################################
# Script logic
#######################################

echo "Searching in: $VIDEO_FOLDER"
echo "Using codec: $CODEC, preset: $PRESET, bitrate: $BITRATE, CRF: $CRF"

# Use find -print0 to handle spaces and weird characters safely
find "$VIDEO_FOLDER" -type f \( \
  -iname "*.mp4" -o \
  -iname "*.mov" -o \
  -iname "*.avi" -o \
  -iname "*.mkv" -o \
  -iname "*.flv" -o \
  -iname "*.wmv" \
\) -print0 | while IFS= read -r -d '' file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    extension="${base##*.}"
    filename="${base%.*}"

    # Skip already compressed files
    if [[ "$filename" == *"$SUFFIX" ]]; then
        echo "Skipping (already compressed): $file"
        continue
    fi

    output="$dir/${filename}${SUFFIX}.${extension}"

    # Skip if compressed version already exists
    if [[ -f "$output" ]]; then
        echo "Skipping (compressed file exists): $output"
        continue
    fi

    echo "Compressing: $file"
    ffmpeg -nostdin -i "$file" \
        -c:v $CODEC -b:v $BITRATE -preset $PRESET -crf $CRF \
        -c:a aac -b:a $AUDIO_BITRATE \
        "$output"

    if [[ $? -eq 0 ]]; then
        echo "Done: $output"
    else
        echo "Error compressing: $file"
    fi
done
