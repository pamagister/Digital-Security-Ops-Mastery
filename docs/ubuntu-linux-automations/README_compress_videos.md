# 🎬 Video Compression Script for Linux

This script compresses videos using **ffmpeg**.
It supports both direct file arguments and recursive folder scanning, while offering flexible control over quality, audio, and output handling.

---

## ✨ Features

* **File arguments or folder scanning**:

  * Provide video files directly as arguments.
  * Or run without arguments to compress all videos in `$VIDEO_FOLDER`.
* **Interactive prompts**:

  * Choose a Constant Rate Factor (CRF) at runtime (default = 27).
  * Decide whether to overwrite originals or save with a suffix.
* Uses **ffmpeg** with H.264 (`libx264`), CRF, and preset for efficient compression.
* Flexible **audio handling**:

  * Re-encode at chosen bitrate.
  * Copy audio unchanged.
  * Strip audio completely.
* **Dry run mode** to preview actions without running ffmpeg.
* Optional renaming of originals with a custom processed suffix.
* KDE / Dolphin right-click menu integration via `.desktop` file.

---

## 📥 Installation

The installation has three separate steps. The code snippets automate each step; a manual alternative is described below each snippet.

### 1. Install dependencies

Install **ffmpeg** and **Konsole** (used to open the interactive script):

```bash
sudo apt update
sudo apt install -y ffmpeg konsole
```

**Manual:** Install `ffmpeg` and `konsole` using your package manager.

### 2. Download the script and Dolphin menu file

This downloads both files from the repository to the user-specific application and Dolphin menu directories:

```bash
set -e
BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/kservices5/ServiceMenus"
curl -fL "$BASE_URL/scripts/compress_videos.sh" -o "$HOME/.local/bin/compress_videos.sh"
curl -fL "$BASE_URL/scripts/compress_videos.desktop" -o "$HOME/.local/share/kservices5/ServiceMenus/compress_videos.desktop"
```

**Manual:** Copy [`compress_videos.sh`](scripts/compress_videos.sh) to `~/.local/bin/` and [`compress_videos.desktop`](scripts/compress_videos.desktop) to `~/.local/share/kservices5/ServiceMenus/`. Create the destination directories if needed.

### 3. Set the path and activate the integration

This replaces the home-directory placeholder in the menu file, makes the script executable, and refreshes KDE's menu cache:

```bash
sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/kservices5/ServiceMenus/compress_videos.desktop"
chmod +x "$HOME/.local/bin/compress_videos.sh"
kbuildsycoca5
```

**Manual:** Open `compress_videos.desktop` in a text editor and replace `@HOME@` with the full path to your home directory. Then run `chmod +x ~/.local/bin/compress_videos.sh` in a terminal and refresh the menu with `kbuildsycoca5`.

Run the script directly from a terminal with `~/.local/bin/compress_videos.sh`.

---

## ⚙️ Configuration

Inside the script, you can adjust these defaults:

```bash
VIDEO_FOLDER="$HOME/Videos"   # Root folder if no input args
DEFAULT_CRF=27                # Default CRF (lower = better quality, 20–30 typical)
PRESET="slow"                 # ffmpeg preset: ultrafast ... veryslow
AUDIO_BITRATE="192k"          # Re-encode audio bitrate
SUFFIX_COMPRESSED="_compressed"  # Default suffix (unused if overwriting)
SUFFIX_PROCESSED=""           # Optional suffix for marking originals
CODEC="libx264"               # Video codec
DRY_RUN=false                 # true = test mode (no ffmpeg executed)
```

---

## 🎚️ Audio Handling

* `AUDIO_BITRATE="192k"` → re-encode audio at 192 kbps.
* `AUDIO_BITRATE=""` → copy audio unchanged.
* `AUDIO_BITRATE="0"` or `"0k"` → strip audio.

---

## 🚀 Usage Examples

### Compress all videos in `$VIDEO_FOLDER`

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

The configurable defaults are set inside the script; shell assignments entered separately in a terminal do not change them. Back up important source files before selecting overwrite.

---

## 📂 KDE / Dolphin Right-Click Menu Integration

After installation, right-click on videos in Dolphin and select **Compress Videos**.

---

## 📝 Notes

* Skips files already containing the compressed suffix.
* Skips if a compressed version already exists (unless overwrite mode is chosen).
* Works on Linux (tested on Ubuntu + KDE Dolphin integration).
