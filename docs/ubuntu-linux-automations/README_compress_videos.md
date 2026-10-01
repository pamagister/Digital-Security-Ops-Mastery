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

Requires **ffmpeg**:

```bash
sudo apt install ffmpeg
```

Download and make the script executable:

```bash
# 1. Go to your home folder (or any directory you prefer)
cd ~

# 2. Download the script from GitHub
curl -o compress_videos.sh \
  https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations/scripts/compress_videos.sh

# 3. Make the script executable
chmod +x compress_videos.sh

# 4. Run the script
./compress_videos.sh
```


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
./compress_videos.sh
```

* Prompts for CRF (default 27).
* Prompts whether to overwrite originals or save as `*_compressed.mp4`.

### Compress specific files

```bash
./compress_videos.sh movie1.mp4 clip.avi
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

To integrate with the KDE context menu, create a `compress_videos.desktop` file in:

```
~/.local/share/kservices5/ServiceMenus/
```

### `compress_videos.desktop`

```ini
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=video/mp4;video/x-matroska;video/avi;video/x-msvideo;video/webm;
Actions=compressvideos;
X-KDE-Priority=TopLevel

[Desktop Action compressvideos]
Name=Compress Videos
Exec=konsole -e /home/username/scripts/compress_videos.sh %F
Icon=video
Terminal=true
```

Now you can **right-click on videos in Dolphin** → **Compress Videos**.

---

## 📝 Notes

* Skips files already containing the compressed suffix.
* Skips if a compressed version already exists (unless overwrite mode is chosen).
* Works on Linux (tested on Ubuntu + KDE Dolphin integration).
