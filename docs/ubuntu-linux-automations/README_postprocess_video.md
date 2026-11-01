# 🎬 Video Postprocessing Script

A Bash script for post-processing video with FFmpeg. It can add music and an intro, trim the input, overlay a recording timestamp/title, limit output height, and apply fade effects. The current defaults are configured near the top of `scripts/postprocess_video.sh`.

## Features

- 🎵 Replace the source audio with a selected music track; audio is trimmed or padded to fit.
- 🎞️ Optionally prepend an intro video.
- 🕒 Overlay a timestamp derived from DJI filenames or video metadata, plus an optional title.
- ✂️ Select a start time and duration; configure fade, encoding, output resolution, and thumbnail settings.
- 💾 Save output to the configured output directory (default: `~/Videos/Output_small`).
- 🖱️ Optional integration with **Kubuntu Dolphin right-click menu**.

## Set-Up

### Requirements

- `ffmpeg`
- `ffprobe`
- `konsole` (used for the Dolphin integration).
- Bash shell.

### Installation

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/kservices5/ServiceMenus"

sudo apt install -y ffmpeg konsole

curl -fL "$BASE_URL/scripts/postprocess_video.sh" -o "$HOME/.local/bin/postprocess_video.sh"
curl -fL "$BASE_URL/scripts/postprocess_video.desktop" -o "$HOME/.local/share/kservices5/ServiceMenus/postprocess_video.desktop"

sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/kservices5/ServiceMenus/postprocess_video.desktop"
chmod +x "$HOME/.local/bin/postprocess_video.sh"
kbuildsycoca5
```

### Manual installation

1. Install `ffmpeg` and `konsole` using your package manager. `ffprobe` is included with the `ffmpeg` package.
2. Copy [`postprocess_video.sh`](scripts/postprocess_video.sh) to `~/.local/bin/` and [`postprocess_video.desktop`](scripts/postprocess_video.desktop) to `~/.local/share/kservices5/ServiceMenus/`. Create the destination directories if needed.
3. Replace `@HOME@` in the desktop file with the full path to your home directory.
4. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/postprocess_video.sh
   ```

5. Refresh the KDE menu cache:

   ```bash
   kbuildsycoca5
   ```

## Usage

### Basic command

```bash
~/.local/bin/postprocess_video.sh <video_file> [--music <audio_file>] [--intro <video_file>] [--title <text>] [--start <seconds>] [--duration <seconds>]
```

### Parameters

* `<video_file>` is required. DJI `.LRF` input is supported; the default output is MP4.
* `--music <audio_file>` selects a music track. Without it, the script prompts from `MUSIC_FOLDER`.
* `--intro <video_file>` adds an intro; `--title <text>` adds a title.
* `--start <seconds>` and `--duration <seconds>` select the source segment. A duration of `0` means the remaining duration.
* The script can still prompt for values not supplied on the command line. Quote paths and titles containing spaces.

## Configuration

Inside the script you can adjust defaults:

```bash
DEFAULT_CRF=27
PRESET="Slow"
AUDIO_BITRATE="160k"
SUFFIX_PROCESSED=""
CODEC="libx264"
MUSIC_FOLDER="$HOME/Music/Ambient"
VIDEO_INTRO_FOLDER="$HOME/Videos/Intros"
OUTPUT_FOLDER="$HOME/Videos/Output_small"
LIMIT_HEIGHT=1080
PRESERVE_LRF=false
```

## Examples

### 1. Auto-select music interactively

```bash
~/.local/bin/postprocess_video.sh holiday.mp4
```

The script lists supported audio files in `$HOME/Music/Ambient` and lets you choose one.

### 2. Provide music directly

```bash
~/.local/bin/postprocess_video.sh holiday.mp4 --music "$HOME/Music/Ambient/song.mp3" --start 0 --duration 0
```

### 3. With Dolphin file explorer (Kubuntu)

After installation, right-click a single video in Dolphin and select **Post Process Video**. The service-menu entry passes the selected file to the script.

## Output

* The default output directory is `~/Videos/Output_small`; change `OUTPUT_FOLDER` in the script to use another location.
* `SUFFIX_PROCESSED` is empty by default. Set it in the script if you want a filename suffix. FFmpeg is run with overwrite enabled, so an existing output with the same name can be replaced; back up files or choose a distinct suffix/output directory.
* The script also writes/reuses `video_processing.sh` beside itself as a batch of replay commands. Review it before running; it may contain local file paths and titles.

## License

MIT License. Free to use and modify.