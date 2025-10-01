#!/bin/bash
#
# Video compression script using ffmpeg
#

#######################################
# User-configurable settings
#######################################
VIDEO_FOLDER="$HOME/Videos"   # Root folder to search ("" = use script location)
CRF=27                        # Constant Rate Factor (lower = better quality, 18–28 typical)
PRESET="medium"                 # Preset: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
AUDIO_BITRATE="192k"          # Audio bitrate (""=copy audio, "0", or "0k" = strip audio)
SUFFIX="_comp"                # Suffix for compressed files
SUFFIX_PROCESSED=""           # Optional suffix for marking original files as processed
CODEC="libx264"               # Video codec
DRY_RUN=false                 # Set true for testing (no ffmpeg executed)

#######################################
# Script logic
#######################################

# If VIDEO_FOLDER is empty, use the directory where the script resides
if [[ -z "$VIDEO_FOLDER" ]]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    VIDEO_FOLDER="$SCRIPT_DIR"
fi

echo "=== Video Compression Script ==="
echo "Search directory : $VIDEO_FOLDER"
echo "Codec            : $CODEC"
echo "Preset           : $PRESET"
echo "CRF              : $CRF"
echo "Audio bitrate    : ${AUDIO_BITRATE:-copy original} (0 = strip audio)"
echo "Compressed suffix: $SUFFIX"
echo "Processed suffix : $SUFFIX_PROCESSED"
echo "Dry run          : $DRY_RUN"
echo "================================"

# Build audio options
get_audio_opts() {
    if [[ -z "$AUDIO_BITRATE" ]]; then
        echo "-c:a copy"
    elif [[ "$AUDIO_BITRATE" == "0" || "$AUDIO_BITRATE" == "0k" ]]; then
        echo "-an"
    else
        echo "-c:a aac -b:a $AUDIO_BITRATE"
    fi
}

AUDIO_OPTS="$(get_audio_opts)"

# Use find -print0 to handle spaces/special chars safely
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

    output="$dir/${filename}${SUFFIX_PROCESSED}${SUFFIX}.${extension}"

    # Skip if compressed version already exists
    if [[ -f "$output" ]]; then
        echo "Skipping (compressed file exists): $output"
        continue
    fi

    echo "Processing: $file"
    echo " -> Output: $output"

    if [[ "$DRY_RUN" == true ]]; then
        echo " [Dry Run] ffmpeg -nostdin -i \"$file\" -c:v $CODEC -preset $PRESET -crf $CRF $AUDIO_OPTS \"$output\""
    else
        ffmpeg -nostdin -i "$file" \
            -c:v $CODEC -preset $PRESET -crf $CRF \
            $AUDIO_OPTS \
            "$output"

        if [[ $? -eq 0 ]]; then
            echo "Done: $output"

            # Optionally mark original as processed
            if [[ -n "$SUFFIX_PROCESSED" ]]; then
                processed_name="$dir/${filename}${SUFFIX_PROCESSED}.${extension}"
                mv -n "$file" "$processed_name"
                echo "Original marked as: $processed_name"
            fi
        else
            echo "Error compressing: $file"
        fi
    fi
done
