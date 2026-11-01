# 🎬 Video Compression Script for Linux

This script compresses videos using **ffmpeg**. It supports both direct file arguments and recursive folder scanning, while offering flexible control over quality, audio, and output handling.

## ✨ Features

- **File arguments or folder scanning**:
  - Provide video files directly as arguments.
  - Or run without arguments to compress all videos in `$VIDEO_FOLDER`.
- **Interactive prompts**:
  - Choose a Constant Rate Factor (CRF) at runtime (default = 27).
  - Decide whether to overwrite originals or save with a suffix.
- Uses **ffmpeg** with H.264 (`libx264`), CRF, and preset for efficient compression.
- Flexible **audio handling**:
  - Re-encode at chosen bitrate.
  - Copy audio unchanged.
  - Strip audio completely.
- **Dry run mode** to preview actions without running ffmpeg.
- Optional renaming of originals with a custom processed suffix.
- KDE / Dolphin right-click menu integration via `.desktop` file.

## ⚙️ Set-Up

### Requirements

- `ffmpeg`
- `konsole` (used to open the interactive script from the context menu).

### Installation

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/kservices5/ServiceMenus"

sudo apt install -y ffmpeg konsole

curl -fL "$BASE_URL/scripts/compress_videos.sh" -o "$HOME/.local/bin/compress_videos.sh"
curl -fL "$BASE_URL/scripts/compress_videos.desktop" -o "$HOME/.local/share/kservices5/ServiceMenus/compress_videos.desktop"

sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/kservices5/ServiceMenus/compress_videos.desktop"
chmod +x "$HOME/.local/bin/compress_videos.sh"
kbuildsycoca5
```

### Manual installation

1. Install `ffmpeg` and `konsole` using your package manager.
2. Copy [`compress_videos.sh`](scripts/compress_videos.sh) to `~/.local/bin/` and [`compress_videos.desktop`](scripts/compress_videos.desktop) to `~/.local/share/kservices5/ServiceMenus/`. Create the destination directories if needed.
3. Replace `@HOME@` in the desktop file with the full path to your home directory.
4. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/compress_videos.sh
   ```

5. Refresh the KDE menu cache:

   ```bash
   kbuildsycoca5
   ```

## 🚀 Usage

Run the script directly from a terminal:

```bash
~/.local/bin/compress_videos.sh
```

* Prompts for CRF (default 27).
* Prompts whether to overwrite originals or save as `*_compressed.mp4`.

### Compress specific files

```bash
~/.local/bin/compress_videos.sh movie1.mp4 clip.avi
```

### Enable dry-run mode

`DRY_RUN` is set inside the script, so edit that variable near the top of `compress_videos.sh` before running:

```bash
DRY_RUN=true
```

### Mark originals as processed

Edit `SUFFIX_PROCESSED` near the top of the script; this renames the original after successful compression when a separate compressed file is created:

```bash
SUFFIX_PROCESSED="_old"
```

## ⚙️ Configuration

Inside the script, you can adjust default values for CRF, preset, audio bitrate, suffixes, and more. 

### Audio handling

- `AUDIO_BITRATE="192k"` → re-encode audio at 192 kbps.
- `AUDIO_BITRATE=""` → copy audio unchanged.
- `AUDIO_BITRATE="0"` or `"0k"` → strip audio.

## KDE / Dolphin right-click menu integration

After installation, right-click on videos in Dolphin and select **Compress Videos**.

## 📝 Notes

- Skips files already containing the compressed suffix.
- Skips if a compressed version already exists (unless overwrite mode is chosen).
- Works on Linux (tested on Ubuntu + KDE Dolphin integration).
- The configurable defaults are set inside the script; shell assignments entered separately in a terminal do not change them. Back up important source files before selecting overwrite.