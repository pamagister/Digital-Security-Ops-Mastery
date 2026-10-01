# 🎬 Video Postprocessing Script

A Bash script for post-processing video with FFmpeg. It can add music and an intro, trim the input, overlay a recording timestamp/title, limit output height, and apply fade effects. The current defaults are configured near the top of `scripts/postprocess_video.sh`.

---

## ✨ Features
- 🎵 Replace the source audio with a selected music track; audio is trimmed or padded to fit.
- 🎞️ Optionally prepend an intro video.
- 🕒 Overlay a timestamp derived from DJI filenames or video metadata, plus an optional title.
- ✂️ Select a start time and duration; configure fade, encoding, output resolution, and thumbnail settings.
- 💾 Save output to the configured output directory (default: `~/Videos/Output_small`).
- 🖱️ Optional integration with **Kubuntu Dolphin right-click menu**.  

---

## 📦 Installation
1. Download the script and make it executable:
   ```bash
   mkdir -p ~/scripts
   curl -fL -o ~/scripts/postprocess_video.sh https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations/scripts/postprocess_video.sh
   chmod +x ~/scripts/postprocess_video.sh
    ```

2. Make sure you have **ffmpeg** and **ffprobe** installed:

   ```bash
   sudo apt install ffmpeg
   ```

---

## 🚀 Usage

### Basic command

```bash
~/scripts/postprocess_video.sh <video_file> [--music <audio_file>] [--intro <video_file>] [--title <text>] [--start <seconds>] [--duration <seconds>]
```

### Parameters

* `<video_file>` is required. DJI `.LRF` input is supported; the default output is MP4.
* `--music <audio_file>` selects a music track. Without it, the script prompts from `MUSIC_FOLDER`.
* `--intro <video_file>` adds an intro; `--title <text>` adds a title.
* `--start <seconds>` and `--duration <seconds>` select the source segment. A duration of `0` means the remaining duration.
* The script can still prompt for values not supplied on the command line. Quote paths and titles containing spaces.

---

## ⚙️ Configuration

Inside the script you can adjust defaults:

```bash
DEFAULT_CRF=27
PRESET="Slow"
AUDIO_BITRATE="160k"
SUFFIX_PROCESSED=""
CODEC="libx264"
MUSIC_FOLDER="$HOME/Musik/Ambient"
VIDEO_INTRO_FOLDER="$HOME/Videos/Intros"
OUTPUT_FOLDER="$HOME/Videos/Output_small"
LIMIT_HEIGHT=1080
PRESERVE_LRF=false
```

---

## 💡 Examples

### 1. Auto-select music interactively

```bash
~/scripts/postprocess_video.sh holiday.mp4
```

The script lists supported audio files in `$HOME/Musik/Ambient` and lets you choose one.

---

### 2. Provide music directly

```bash
~/scripts/postprocess_video.sh holiday.mp4 --music "$HOME/Musik/Ambient/song.mp3" --start 0 --duration 0
```

---

### 3. With Dolphin file explorer (Kubuntu)

You can integrate the script into **KDE Dolphin** for right-click usage.

Create the service menu file:

```ini
# ~/.local/share/kservices5/ServiceMenus/postprocess_video.desktop
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=video/mp4;video/x-matroska;video/avi;video/x-msvideo;video/webm;
Actions=postprocessvideo;
X-KDE-Priority=TopLevel

[Desktop Action postprocessvideo]
Name=Post Process Video
Exec=konsole -e /home/username/scripts/postprocess_video.sh %f
Icon=video
Terminal=true
```

Now, update the menu:

```bash
kbuildsycoca5
```

Now you can right-click a single video in Dolphin → **Post Process Video**. This service-menu example passes one selected file.

---

## 🛠️ Requirements

* `ffmpeg`
* `ffprobe`
* Bash shell

---

## ✅ Output

* The default output directory is `~/Videos/Output_small`; change `OUTPUT_FOLDER` in the script to use another location.
* `SUFFIX_PROCESSED` is empty by default. Set it in the script if you want a filename suffix. FFmpeg is run with overwrite enabled, so an existing output with the same name can be replaced; back up files or choose a distinct suffix/output directory.
* The script also writes/reuses `video_processing.sh` beside itself as a batch of replay commands. Review it before running; it may contain local file paths and titles.

---

## 📜 License

MIT License. Free to use and modify.
