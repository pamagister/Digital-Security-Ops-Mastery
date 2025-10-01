#!/bin/bash
#
# Video compression script using ffmpeg
#

#######################################
# User-configurable defaults
#######################################
VIDEO_FOLDER="$HOME/Videos"   # Root folder to search if no input args
DEFAULT_CRF=27                # Default Constant Rate Factor (lower = better quality, 20–30 typical)
PRESET="medium"               # Preset: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
AUDIO_BITRATE="192k"          # Audio bitrate (""=copy audio, "0", or "0k" = strip audio)
SUFFIX_COMPRESSED="_comp"                # Default suffix for compressed files (only used if not overwriting)
SUFFIX_PROCESSED=""           # Optional suffix for marking originals
CODEC="libx264"               # Video codec
DRY_RUN=false                 # Set true for testing (no ffmpeg executed)

#######################################
# User prompts
#######################################

# Prompt for CRF
read -p "Enter Constant Rate Factor (CRF) (lower = better quality, 20–30 typical) [default=$DEFAULT_CRF]: " input_crf
CRF="${input_crf:-$DEFAULT_CRF}"

# Prompt overwrite
read -p "Overwrite original files? [y/N]: " overwrite
if [[ "$overwrite" =~ ^[Yy]$ ]]; then
    SUFFIX_COMPRESSED=""
else
    SUFFIX_COMPRESSED="_compressed"
fi

echo "=== Video Compression Script ==="
echo "Search directory : $VIDEO_FOLDER"
echo "Codec            : $CODEC"
echo "Preset           : $PRESET"
echo "CRF              : $CRF"
echo "Audio bitrate    : ${AUDIO_BITRATE:-copy original} (0 = strip audio)"
echo "Compressed suffix: '$SUFFIX'"
echo "Processed suffix : $SUFFIX_PROCESSED"
echo "Dry run          : $DRY_RUN"
echo "================================"

#######################################
# Helper: Build audio options
#######################################
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

#######################################
# Build file list
#######################################
files=()

if [[ $# -gt 0 ]]; then
    # Files passed as arguments
    files=("$@")
else
    # Use VIDEO_FOLDER
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$VIDEO_FOLDER" -type f \( \
        -iname "*.mp4" -o \
        -iname "*.mov" -o \
        -iname "*.avi" -o \
        -iname "*.mkv" -o \
        -iname "*.flv" -o \
        -iname "*.wmv" \
    \) -print0)
fi

#######################################
# Main loop
#######################################
for file in "${files[@]}"; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    extension="${base##*.}"
    filename="${base%.*}"

    # Skip already compressed if suffix is used
    if [[ -n "$SUFFIX_COMPRESSED" && "$filename" == *"$SUFFIX_COMPRESSED" ]]; then
        echo "Skipping (already compressed): $file"
        continue
    fi

    output="$dir/${filename}${SUFFIX_COMPRESSED}.${extension}"
    output_temp="$dir/${filename}${SUFFIX_COMPRESSED}_TEMP.${extension}"

    # Skip if compressed version already exists (when suffix is used)
    if [[ -n "$SUFFIX_COMPRESSED" && -f "$output" ]]; then
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
            "$output_temp"
            mv -f "$output_temp" "$output"

        if [[ $? -eq 0 ]]; then
            echo "Done: $output"

            # Optionally mark original as processed (only if suffix is used)
            if [[ -n "$SUFFIX_PROCESSED" && -n "$SUFFIX_COMPRESSED" ]]; then
                processed_name="$dir/${filename}${SUFFIX_PROCESSED}.${extension}"
                mv -n "$file" "$processed_name"
                echo "Original marked as: $processed_name"
            fi
        else
            echo "Error compressing: $file"
        fi
    fi
done
