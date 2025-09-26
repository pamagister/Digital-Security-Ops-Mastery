# 🎬 Video Compression Script for Linux

This script recursively compresses videos in a given folder using **ffmpeg**.  
It maintains high quality (H.264 codec) while reducing file size, and offers flexible options for audio handling, suffixes, and dry runs.

---

## ✨ Features
- Recursively compress all videos in a folder and its subfolders.
- Uses **ffmpeg** with `libx264`, CRF, and preset for high-quality compression.
- Configurable **CRF**, **preset**, and **suffixes**.
- Handles **audio streams** flexibly:
  - Re-encode audio at given bitrate.
  - Copy audio unchanged.
  - Strip audio completely.
- **Dry run mode** to preview actions without running ffmpeg.
- Optionally rename originals with a custom processed suffix.

---

## 📥 Installation

Download and make the script executable:

```bash
# 1. Go to your home folder (or any directory you prefer)
cd ~

# 2. Download the script from GitHub
curl -o compress_videos.sh \
  https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/ubuntu-linux-automations/scripts/compress_videos.sh

# 3. Make the script executable
chmod +x compress_videos.sh

# 4. Run the script
./compress_videos.sh
````

To run from anywhere, move it into your `$PATH`:

```bash
sudo mv compress_videos.sh /usr/local/bin/compress_videos
compress_videos
```

---

## ⚙️ Configuration

Inside the script, adjust these variables as needed:

```bash
VIDEO_FOLDER=""               # Root folder to search ("" = script's location)
CRF=23                        # Constant Rate Factor (18 = high quality, 28 = lower quality)
PRESET="slow"                 # ffmpeg preset: ultrafast ... veryslow
AUDIO_BITRATE="192k"          # Audio bitrate
SUFFIX="_comp"                # Suffix for compressed files
SUFFIX_PROCESSED=""           # Suffix for marking original files as processed
CODEC="libx264"               # Video codec
DRY_RUN=false                 # true = test mode (no ffmpeg executed)
```

---

## 🎚️ Audio Handling

* `AUDIO_BITRATE="192k"` → re-encode audio at 192 kbps.
* `AUDIO_BITRATE=""` → copy audio unchanged.
* `AUDIO_BITRATE="0"` or `"0k"` → remove audio track.

---

## 🚀 Usage Examples

### Run in script folder (default)

```bash
./compress_videos.sh
```

### Run with dry run (preview only)

```bash
DRY_RUN=true ./compress_videos.sh
```

### Compress and mark originals as processed

```bash
SUFFIX_PROCESSED="_old" ./compress_videos.sh
```

---

## 📝 Notes

* Works on Linux (tested on Ubuntu).
* Requires **ffmpeg** to be installed:

  ```bash
  sudo apt install ffmpeg
  ```
* Skips files already containing the compressed suffix.
* Skips if a compressed version already exists.

---
