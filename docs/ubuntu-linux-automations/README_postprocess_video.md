# 🎬 Video Postprocessing Script

A simple **Ubuntu/Linux shell script** for merging a video file with a background music track.  
It automatically trims/pads audio to match video length and applies a smooth fade-out at the end of both video and audio.  

---

## ✨ Features
- 🎵 Merge video with background music (choose via `--music` or interactively).  
- ⏳ Automatically trims audio if longer than video, or pads silence if shorter.  
- 🌗 Fade-out effect for both video and audio (`FADEOUT_TIME` configurable).  
- ⚙️ Configurable encoding options (CRF, preset, codec, audio bitrate).  
- 💾 Output saved next to input video with `_processed` suffix.  
- 🖱️ Optional integration with **Kubuntu Dolphin right-click menu**.  

---

## 📦 Installation
1. Clone or copy the script to your system, e.g.:
   ```bash
   mkdir -p ~/scripts
   cp postprocess_video.sh ~/scripts/
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
./postprocess_video.sh <video_file> [--music <music_file>]
```

### Parameters

* `<video_file>` → main video input.
* `--music <music_file>` → optional audio track (if omitted, script will show a numbered list of files in `MUSIC_FOLDER`).

---

## ⚙️ Configuration

Inside the script you can adjust defaults:

```bash
DEFAULT_CRF=27         # Quality (lower = better, 20–30 typical)
PRESET="slow"          # Encoding speed (faster = lower compression)
AUDIO_BITRATE="192k"   # Audio bitrate ("0" or "" to disable/copy)
SUFFIX_PROCESSED="_processed"
CODEC="libx264"        # Video codec
MUSIC_FOLDER="$HOME/Music"
FADEOUT_TIME=2.5       # Fade-out duration in seconds
```

---

## 💡 Examples

### 1. Auto-select music interactively

```bash
./postprocess_video.sh holiday.mp4
```

👉 Script lists all audio files in `$HOME/Music` and lets you pick one.

---

### 2. Provide music directly

```bash
./postprocess_video.sh holiday.mp4 --music ~/Music/song.mp3
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
Exec=konsole -e /home/username/scripts/postprocess_video.sh %F
Icon=video
Terminal=true
```

Now, update the menu:

```bash
kbuildsycoca5
```

Now you can right-click any video in Dolphin → **Post Process Video**.

---

## 🛠️ Requirements

* `ffmpeg`
* `ffprobe`
* Bash shell

---

## ✅ Output

* Resulting file is saved in the **same directory as the input video**.
* Example: `holiday.mp4` → `holiday_processed.mp4`

---

## 📜 License

MIT License. Free to use and modify.
