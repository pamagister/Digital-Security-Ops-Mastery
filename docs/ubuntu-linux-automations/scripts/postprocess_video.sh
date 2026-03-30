#!/bin/bash
#
#
# ------------------------------------------------------------
# Drone Video Post-Processing Script
# ------------------------------------------------------------
#
# PURPOSE
# -------
# Automates post-processing of drone footage using ffmpeg.
# The script combines a video file with a music track, applies
# cinematic fades, optional recompression, resolution limiting,
# and automatically overlays a recording timestamp.
#
#
# USAGE
# -----
#   ./process_video.sh <video_file> [--music <audio_file>]
#
# Arguments:
#   <video_file>        Input video (DJI MP4 or LRF supported)
#   --music <file>      Optional music track
#
# If no music file is provided, the user can interactively
# select one from MUSIC_FOLDER.
#
#
# MAIN FEATURES
# -------------Nutzer
#
# ✔ Video + music merging
#   - Replaces original audio with selected music track
#   - Music automatically trimmed to video duration
#   - Silence added automatically if music is shorter
#
# ✔ Cinematic transitions
#   - Configurable fade-in
#   - Automatic fade-out to black and silence
#
# ✔ Automatic timestamp overlay
#   - Extracts date/time from DJI filename
#   - Fallback: reads creation_time from video metadata
#   - Text size and margins scale relative to video height
#   - Resolution-independent positioning
#
# ✔ Resolution control
#   - Optional LIMIT_HEIGHT caps output resolution
#   - Aspect ratio preserved automatically
#
# ✔ Smart format handling
#   - DJI LRF files supported transparently
#   - Optional restoration of original LRF extension
#
# ✔ Encoding control
#   - Adjustable CRF quality setting
#   - Configurable encoder preset
#   - Optional audio copy, re-encode, or removal
#
# ✔ Clean output workflow
#   - Output stored next to input file
#   - Filename appended with SUFFIX_PROCESSED
#
#
# WORKFLOW SUMMARY
# ----------------
# 1. Read input video
# 2. Select music (argument or interactive picker)
# 3. Detect video duration and resolution
# 4. Extract recording timestamp
# 5. Apply scaling, fades, and overlay
# 6. Encode final video
# 7. Write processed output file
#
# ------------------------------------------------------------
#

#!/usr/bin/env bash
set -euo pipefail

#######################################
# User-configurable defaults
#######################################
DEFAULT_CRF=27                # Default Constant Rate Factor (lower = better quality, 20–30 typical)
PRESET="faster"                 # Preset: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
AUDIO_BITRATE="192k"          # Audio bitrate (""=copy audio, "0", or "0k" = strip audio)
SUFFIX_PROCESSED="_processed" # Default suffix for processed files (only used if not overwriting)
CODEC="libx264"               # Video codec
MUSIC_FOLDER="$HOME/Musik"    # Root folder to search for music tracks
OUTPUT_FOLDER="$HOME/Videos/Output"              # Leave empty to use input folder
FADE_IN_TIME=3.0
FADE_OUT_TIME=3.0              # Time (s) to fade out video (to black) and music (to silent)
INTRO_VIDEO="$HOME/Videos/Intro_Sparks.mp4"  # Introductory video sequence (optional)
THUMBNAIL_TIME=5.0          # Time when reference thumbnail snapshot is taken. -1.0 means: No thumbnail

PRESERVE_LRF=0                # Set to 1 if you want to keep original LRF format, otherwise output MP4
TEXT_SIZE=20           # Text height in percent of video height (e.g. 5 = 5%)
LIMIT_HEIGHT=720     # 0 = keep original height, otherwise max output height
TEXT_MARGIN=3         # Margin in percent of video height

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
# Extract DJI timestamp (filename or metadata fallback)
#######################################
extract_datetime_text() {

    local file="$1"
    local base ts year month day hour

    base=$(basename "$file")

    ###################################
    # 1. Try DJI filename format
    ###################################
    if [[ $base =~ DJI_([0-9]{14})_ ]]; then
        ts="${BASH_REMATCH[1]}"

        year=${ts:0:4}
        month=${ts:4:2}
        day=${ts:6:2}
        hour=${ts:8:2}

        echo "${day}.${month}.${year} - ${hour} Uhr"
        return 0
    fi

    ###################################
    # 2. Fallback: read metadata creation_time
    ###################################
    ts=$(ffprobe -v error \
        -select_streams v:0 \
        -show_entries stream_tags=creation_time \
        -of default=noprint_wrappers=1:nokey=1 \
        "$file" 2>/dev/null | head -n1)

    # fallback to container metadata if stream tag missing
    if [[ -z "$ts" ]]; then
        ts=$(ffprobe -v error \
            -show_entries format_tags=creation_time \
            -of default=noprint_wrappers=1:nokey=1 \
            "$file" 2>/dev/null | head -n1)
    fi

    ###################################
    # 3. Parse ISO timestamp
    # Example: 2025-10-13T15:09:04.000000Z
    ###################################
    if [[ $ts =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}) ]]; then
        year="${BASH_REMATCH[1]}"
        month="${BASH_REMATCH[2]}"
        day="${BASH_REMATCH[3]}"
        hour="${BASH_REMATCH[4]}"

        echo "${day}.${month}.${year} - ${hour} Uhr"
        return 0
    fi

    ###################################
    # 4. Nothing found
    ###################################
    echo ""
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
# Optional custom video name
#######################################
read -p "Optional video name (ENTER to skip): " VIDEO_TITLE

VIDEO_TITLE_SANITIZED=""
if [[ -n "${VIDEO_TITLE// }" ]]; then
    VIDEO_TITLE_SANITIZED=$(echo "$VIDEO_TITLE" | tr ' ' '_')
fi

#######################################
# Processing values
#######################################
AUDIO_OPTS=$(get_audio_opts)

VIDEO_DURATION=$(get_duration "$INPUT_FOR_FFMPEG")

VIDEO_HEIGHT=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=height \
    -of csv=p=0 "$INPUT_FOR_FFMPEG")

fade_start_video=$(LC_NUMERIC=C awk -v vd="$VIDEO_DURATION" -v ft="$FADE_OUT_TIME" \
'BEGIN{printf "%.3f",(vd-ft>0)?vd-ft:0}')

fade_start_audio="$fade_start_video"

#######################################
# Optional trimming
#######################################
echo "Start time? [total duration ${VIDEO_DURATION}s]"
read -p "> " START_TIME_INPUT

START_TIME="${START_TIME_INPUT:-0}"

REMAINING_DURATION=$(LC_NUMERIC=C awk \
    -v total="$VIDEO_DURATION" \
    -v start="$START_TIME" \
    'BEGIN{printf "%.2f",(total-start>0)?total-start:0}')

echo "Duration? [remaining duration ${REMAINING_DURATION}s]"
read -p "> " DURATION_INPUT

if [[ -n "$DURATION_INPUT" ]]; then
    OUTPUT_DURATION="$DURATION_INPUT"
else
    OUTPUT_DURATION="$REMAINING_DURATION"
fi

#######################################
# Date overlay
#######################################
DATETIME_TEXT=$(extract_datetime_text "$VIDEO_FILE")
TEXT_DURATION=$(LC_NUMERIC=C awk -v f="$FADE_IN_TIME" 'BEGIN{printf "%.3f",f*1.2}')

FONT_SIZE=$(LC_NUMERIC=C awk \
    -v h="$VIDEO_HEIGHT" \
    -v p="$TEXT_SIZE" \
    'BEGIN{printf "%d",(h*p/100)}')

DATE_FONT_SIZE=$(LC_NUMERIC=C awk \
    -v fs="$FONT_SIZE" \
    'BEGIN{printf "%d",(fs*0.5)}')

TEXT_MARGIN_PX=$(LC_NUMERIC=C awk \
    -v h="$VIDEO_HEIGHT" \
    -v p="$TEXT_MARGIN" \
    'BEGIN{printf "%d",(h*p/100)}')

#######################################
# Fade timing
#######################################
TEXT_FADE_OUT=$(LC_NUMERIC=C awk \
    -v td="$TEXT_DURATION" \
    -v fi="$FADE_IN_TIME" \
    'BEGIN{printf "%.3f",td+(0.3*fi)}')

ALPHA_EXPR="if(lt(t,$TEXT_DURATION),1, if(lt(t,$TEXT_FADE_OUT),(1-(t-$TEXT_DURATION)/($TEXT_FADE_OUT-$TEXT_DURATION)),0))"

DRAW_TEXT=""

#######################################
# Optional VIDEO_TITLE (top line)
#######################################
if [[ -n "$VIDEO_TITLE" ]]; then

DRAW_TEXT="drawtext=
text='${VIDEO_TITLE}':
fontcolor=white:
fontsize=${FONT_SIZE}:
x=${TEXT_MARGIN_PX}:
y=${TEXT_MARGIN_PX}:
alpha='${ALPHA_EXPR}'"

NAME_BLOCK_HEIGHT=$(LC_NUMERIC=C awk \
    -v fs="$FONT_SIZE" \
    'BEGIN{printf "%d",(fs*1.2)}')

DATE_Y_POS=$(LC_NUMERIC=C awk \
    -v m="$TEXT_MARGIN_PX" \
    -v h="$NAME_BLOCK_HEIGHT" \
    'BEGIN{printf "%d",(m+h)}')

else
DATE_Y_POS=$TEXT_MARGIN_PX
fi

#######################################
# Date line (second line)
#######################################
if [[ -n "$DATETIME_TEXT" ]]; then

DATE_DRAW="drawtext=
text='${DATETIME_TEXT}':
fontcolor=white:
fontsize=${DATE_FONT_SIZE}:
x=${TEXT_MARGIN_PX}:
y=${DATE_Y_POS}:
alpha='${ALPHA_EXPR}'"

if [[ -n "$DRAW_TEXT" ]]; then
    DRAW_TEXT="${DRAW_TEXT},${DATE_DRAW}"
else
    DRAW_TEXT="${DATE_DRAW}"
fi

fi
#######################################
# Filters
#######################################

SCALE_FILTER=""

if [[ "$LIMIT_HEIGHT" -gt 0 ]]; then
    SCALE_FILTER="scale=-2:'min(ih,$LIMIT_HEIGHT)'"
fi

VIDEO_FILTER=""

[[ -n "$SCALE_FILTER" ]] && VIDEO_FILTER="$SCALE_FILTER,"

VIDEO_FILTER="${VIDEO_FILTER}fade=t=in:st=0:d=$FADE_IN_TIME,\
fade=t=out:st=$fade_start_video:d=$FADE_OUT_TIME"

[[ -n "$DRAW_TEXT" ]] && VIDEO_FILTER="$VIDEO_FILTER,$DRAW_TEXT"

AUDIO_FILTER="afade=t=out:st=$fade_start_audio:d=$FADE_OUT_TIME"

#######################################
# Output filename + OUTPUT_FOLDER support
#######################################
INPUT_DIR=$(dirname "$VIDEO_FILE")

if [[ -n "$OUTPUT_FOLDER" ]]; then
    mkdir -p "$OUTPUT_FOLDER"
    TARGET_DIR="$OUTPUT_FOLDER"
else
    TARGET_DIR="$INPUT_DIR"
fi

BASE_NAME=$(basename "${VIDEO_FILE%.*}")

OUT_BASE="${TARGET_DIR}/${BASE_NAME}${SUFFIX_PROCESSED}"

if [[ -n "$VIDEO_TITLE_SANITIZED" ]]; then
    OUT_BASE="${OUT_BASE}_${VIDEO_TITLE_SANITIZED}"
fi

TMP_OUTPUT="${OUT_BASE}.mp4"


#######################################
# Simple processing queue (single instance)
#######################################
LOCKFILE="/tmp/dji_video_processing.lock"

exec 9>"$LOCKFILE"

echo "Waiting for processing queue..."
flock 9
echo "Queue acquired."

#######################################
# Run ffmpeg
#######################################
ffmpeg -y \
    -ss "$START_TIME" \
    -i "$INPUT_FOR_FFMPEG" \
    -i "$MUSIC_FILE" \
    -t "$OUTPUT_DURATION" \
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

