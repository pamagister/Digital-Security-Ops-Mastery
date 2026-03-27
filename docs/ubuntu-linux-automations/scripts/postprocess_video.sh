#!/bin/bash
#
# Video postprocessing script to join video Files passed as main argument and
# a music track passed as optional argument --music:
# video file is the main argument for this script
# music file can be provided by --music argument, if not, user can select the track from an enumerated list
#   from audio files in the MUSIC_FOLDER
# video and music are joined into one file, with a given FADEOUT_TIME to fade out audio and video in the end
# if the audio is longer then the video, it will be cutted at the end of the video
# if the audio is shorter, the video will have silence in the end
# file will be saved at the location of the intput video file, with a SUFFIX_PROCESSED

#!/usr/bin/env bash
set -euo pipefail

#######################################
# User-configurable defaults
#######################################
DEFAULT_CRF=30                # Default Constant Rate Factor (lower = better quality, 20–30 typical)
PRESET="veryfast"                 # Preset: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
AUDIO_BITRATE="192k"          # Audio bitrate (""=copy audio, "0", or "0k" = strip audio)
SUFFIX_PROCESSED="_processed" # Default suffix for processed files (only used if not overwriting)
CODEC="libx264"               # Video codec
MUSIC_FOLDER="$HOME/Musik"    # Root folder to search for music tracks
FADEIN_TIME=3.0
FADEOUT_TIME=3.0              # Time (s) to fade out video (to black) and music (to silent)

PRESERVE_LRF=0                # Set to 1 if you want to keep original LRF format, otherwise output MP4

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
    ffprobe -v error \
        -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$1" \
        | LC_NUMERIC=C awk '{printf "%.2f",$1}'
}

#######################################
# Extract DJI timestamp
#######################################
extract_datetime_text() {

    local file="$1"
    local base
    base=$(basename "$file")

    if [[ $base =~ DJI_([0-9]{14})_ ]]; then
        ts="${BASH_REMATCH[1]}"

        year=${ts:0:4}
        month=${ts:4:2}
        day=${ts:6:2}
        hour=${ts:8:2}

        echo "${day}.${month}.${year} - ${hour} Uhr"
    else
        echo ""
    fi
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
            usage
            ;;
        *)
            VIDEO_FILE="$1"
            shift
            ;;
    esac
done

[[ -z "$VIDEO_FILE" ]] && usage
[[ ! -f "$VIDEO_FILE" ]] && exit 1

#######################################
# LRF Support
#######################################
TMP_INPUT=""
INPUT_FOR_FFMPEG="$VIDEO_FILE"

EXT="${VIDEO_FILE##*.}"

if [[ "${EXT^^}" == "LRF" ]]; then
    echo "Copy LRF file into MP4"
    TMP_INPUT=$(mktemp /tmp/dji_lrf_XXXXXX.mp4)
    cp -f "$VIDEO_FILE" "$TMP_INPUT"
    INPUT_FOR_FFMPEG="$TMP_INPUT"
fi

#######################################
# Prompt music if needed
#######################################
if [[ -z "$MUSIC_FILE" ]]; then
    mapfile -t MUSIC_FILES < <(
        find "$MUSIC_FOLDER" -type f \
        \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" \
           -o -iname "*.aac" -o -iname "*.ogg" \) | sort
    )

    [[ ${#MUSIC_FILES[@]} -eq 0 ]] && exit 1

    echo "Available music:"
    for i in "${!MUSIC_FILES[@]}"; do
        echo "[$i] ${MUSIC_FILES[$i]}"
    done

    read -p "Select index: " idx
    MUSIC_FILE="${MUSIC_FILES[$idx]}"
fi

#######################################
# Processing values
#######################################
AUDIO_OPTS=$(get_audio_opts)

VIDEO_DURATION=$(get_duration "$INPUT_FOR_FFMPEG")

fade_start_video=$(LC_NUMERIC=C awk -v vd="$VIDEO_DURATION" -v ft="$FADEOUT_TIME" \
'BEGIN{printf "%.3f",(vd-ft>0)?vd-ft:0}')

fade_start_audio="$fade_start_video"

#######################################
# Date overlay
#######################################
DATETIME_TEXT=$(extract_datetime_text "$VIDEO_FILE")
TEXT_DURATION=$(LC_NUMERIC=C awk -v f="$FADEIN_TIME" 'BEGIN{printf "%.3f",f*1.2}')

DRAW_TEXT=""

if [[ -n "$DATETIME_TEXT" ]]; then
DRAW_TEXT="drawtext=
text='${DATETIME_TEXT}':
fontcolor=white:
fontsize=100:
x=20:
y=h-th-20:
enable='between(t,0,$TEXT_DURATION)'"
fi

#######################################
# Filters
#######################################
VIDEO_FILTER="fade=t=in:st=0:d=$FADEIN_TIME,\
fade=t=out:st=$fade_start_video:d=$FADEOUT_TIME"

[[ -n "$DRAW_TEXT" ]] && VIDEO_FILTER="$VIDEO_FILTER,$DRAW_TEXT"

AUDIO_FILTER="afade=t=out:st=$fade_start_audio:d=$FADEOUT_TIME"

#######################################
# Output filename
#######################################
OUT_BASE="${VIDEO_FILE%.*}${SUFFIX_PROCESSED}"

TMP_OUTPUT="${OUT_BASE}.mp4"

#######################################
# Run ffmpeg
#######################################
ffmpeg -y \
    -i "$INPUT_FOR_FFMPEG" \
    -i "$MUSIC_FILE" \
    -t "$VIDEO_DURATION" \
    -map 0:v:0 -map 1:a:0 \
    -vf "$VIDEO_FILTER" \
    -af "$AUDIO_FILTER" \
    -c:v $CODEC -preset $PRESET -crf $DEFAULT_CRF \
    $AUDIO_OPTS \
    "$TMP_OUTPUT"

#######################################
# Restore LRF extension if needed
#######################################
FINAL_OUTPUT="$TMP_OUTPUT"

if  [[ "$PRESERVE_LRF" == 1 ]]; then
  if [[ "${EXT^^}" == "LRF" ]]; then
      FINAL_OUTPUT="${OUT_BASE}.LRF"
      mv "$TMP_OUTPUT" "$FINAL_OUTPUT"
  fi
fi

[[ -n "$TMP_INPUT" ]] && rm "$TMP_INPUT"
echo "✅ Done: $FINAL_OUTPUT"

