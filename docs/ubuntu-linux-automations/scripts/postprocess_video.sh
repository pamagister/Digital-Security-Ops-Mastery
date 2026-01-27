#!/bin/bash
#
# Video postprocessing script to join video Files passed as main argument and
# a music track passed as optional argument --music:
# video file is the main argument for this script
# music file can be provided by --music argument, if not, user can select the track from an enumbereated list
#   from audio files in the MUSIC_FOLDER
# video and music are joined into one file, with a given FADEOUT_TIME to fade out audio and video in the end
# if the audio is longer then the video, it will be cutted at the end of the video
# if the audio is shorter, the video will have silence in the end
# file fill be saved at the location of the intput video file, with a SUFFIX_PROCESSED

#!/usr/bin/env bash
set -euo pipefail

#######################################
# User-configurable defaults
#######################################
DEFAULT_CRF=27                # Default Constant Rate Factor (lower = better quality, 20–30 typical)
PRESET="slow"                 # Preset: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
AUDIO_BITRATE="192k"          # Audio bitrate (""=copy audio, "0", or "0k" = strip audio)
SUFFIX_PROCESSED="_processed" # Default suffix for processed files (only used if not overwriting)
CODEC="libx264"               # Video codec
MUSIC_FOLDER="$HOME/Musik"    # Root folder to search for music tracks
FADEOUT_TIME=2.5              # Time (s) to fade out video (to black) and music (to silent)

#######################################
# Helper: print usage
#######################################
usage() {
    echo "Usage: $0 <video_file> [--music <music_file>]"
    exit 1
}

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

#######################################
# Helper: get duration of a media file
#######################################
get_duration() {
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1" \
    | LC_NUMERIC=C awk '{printf "%.2f", $1}'
}

#######################################
# Parse arguments
#######################################
VIDEO_FILE=""
MUSIC_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --music)
            MUSIC_FILE="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            if [[ -z "$VIDEO_FILE" ]]; then
                VIDEO_FILE="$1"
            else
                echo "Error: Multiple video files not supported."
                usage
            fi
            shift
            ;;
    esac
done

[[ -z "$VIDEO_FILE" ]] && usage
[[ ! -f "$VIDEO_FILE" ]] && { echo "Video file not found: $VIDEO_FILE"; exit 1; }

#######################################
# Prompt music if not provided
#######################################
if [[ -z "$MUSIC_FILE" ]]; then
    echo "No music file provided. Searching in $MUSIC_FOLDER..."
    mapfile -t MUSIC_FILES < <(find "$MUSIC_FOLDER" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.ogg" \) | sort)

    if [[ ${#MUSIC_FILES[@]} -eq 0 ]]; then
        echo "No audio files found in $MUSIC_FOLDER"
        exit 1
    fi

    VIDEO_DURATION=$(get_duration "$VIDEO_FILE")
    echo "Video duration: ${VIDEO_DURATION}s"
    echo
    echo "Available music files:"
    for i in "${!MUSIC_FILES[@]}"; do
        dur=$(get_duration "${MUSIC_FILES[$i]}")
        echo "[$i] ${MUSIC_FILES[$i]}  (duration: ${dur}s)"
    done

    read -p "Select music track index: " idx
    MUSIC_FILE="${MUSIC_FILES[$idx]}"
fi

[[ ! -f "$MUSIC_FILE" ]] && { echo "Music file not found: $MUSIC_FILE"; exit 1; }

#######################################
# Processing
#######################################
AUDIO_OPTS="$(get_audio_opts)"
VIDEO_DURATION=$(get_duration "$VIDEO_FILE")
MUSIC_DURATION=$(get_duration "$MUSIC_FILE")

OUTPUT_FILE="${VIDEO_FILE%.*}${SUFFIX_PROCESSED}.${VIDEO_FILE##*.}"

echo "=== Video Processing ==="
echo "Video: $VIDEO_FILE (${VIDEO_DURATION}s)"
echo "Music: $MUSIC_FILE (${MUSIC_DURATION}s)"
echo "Output: $OUTPUT_FILE"
echo "Codec: $CODEC"
echo "Preset: $PRESET"
echo "CRF: $DEFAULT_CRF"
echo "Audio options: $AUDIO_OPTS"
echo "Fadeout: $FADEOUT_TIME s"
echo "========================"

#######################################
# Build filters
#######################################
# Determine fade start times
fade_start_video=$(LC_NUMERIC=C awk -v vd="$VIDEO_DURATION" -v ft="$FADEOUT_TIME" 'BEGIN {print (vd-ft>0)?vd-ft:0}')
fade_start_audio=$(LC_NUMERIC=C awk -v vd="$VIDEO_DURATION" -v ft="$FADEOUT_TIME" 'BEGIN {print (vd-ft>0)?vd-ft:0}')

VIDEO_FILTER="fade=t=out:st=$fade_start_video:d=$FADEOUT_TIME"
AUDIO_FILTER="afade=t=out:st=$fade_start_audio:d=$FADEOUT_TIME"

#######################################
# Run ffmpeg
#######################################
ffmpeg -y \
    -i "$VIDEO_FILE" \
    -i "$MUSIC_FILE" \
    -t "$VIDEO_DURATION" \
    -map 0:v:0 -map 1:a:0 \
    -vf "$VIDEO_FILTER" \
    -af "$AUDIO_FILTER" \
    -c:v $CODEC -preset $PRESET -crf $DEFAULT_CRF \
    $AUDIO_OPTS \
    "$OUTPUT_FILE"

echo "✅ Done! Output saved to: $OUTPUT_FILE"
