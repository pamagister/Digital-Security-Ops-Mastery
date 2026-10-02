# Image Compression Tool (Linux/Kubuntu)

A simple interactive script to process JPEG and PNG images without resizing. JPEG output is targeted to a selected file size. PNG handling depends on whether `pngquant` is installed: it may create a palette-based PNG, or convert the image to JPEG if `pngquant` is unavailable.

---

## 📦 Requirements

* **Linux (Kubuntu)**
* **Dolphin file manager**
* **ImageMagick** (required for image compression)
* **pngquant** (optional; used for PNG palette compression)
* **Konsole** (used to open the interactive script)

## 📥 Installation

The installation has three separate steps. The code snippets automate each step; a manual alternative is described below each snippet.

### 1. Install dependencies

Install ImageMagick and Konsole. Install `pngquant` as well if you want palette-based PNG compression:

```bash
sudo apt update
sudo apt install -y imagemagick konsole
# Optional, for palette-based PNG compression:
# sudo apt install -y pngquant
```

**Manual:** Install `imagemagick` and `konsole` using your package manager. Install `pngquant` there too if desired; without it, PNG files are converted to JPEG.

### 2. Download the script and Dolphin menu file

This downloads both files from the repository to the user-specific application and Dolphin menu directories:

```bash
set -e
BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/kservices5/ServiceMenus"
curl -fL "$BASE_URL/scripts/compress_images.sh" -o "$HOME/.local/bin/compress_images.sh"
curl -fL "$BASE_URL/scripts/compress_images.desktop" -o "$HOME/.local/share/kservices5/ServiceMenus/compress_images.desktop"
```

**Manual:** Copy [`compress_images.sh`](scripts/compress_images.sh) to `~/.local/bin/` and [`compress_images.desktop`](scripts/compress_images.desktop) to `~/.local/share/kservices5/ServiceMenus/`. Create the destination directories if needed.

### 3. Set the path and activate the integration

This replaces the home-directory placeholder in the menu file, makes the script executable, and refreshes KDE's menu cache:

```bash
sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/kservices5/ServiceMenus/compress_images.desktop"
chmod +x "$HOME/.local/bin/compress_images.sh"
kbuildsycoca5
```

**Manual:** Open `compress_images.desktop` in a text editor and replace `@HOME@` with the full path to your home directory. Then run `chmod +x ~/.local/bin/compress_images.sh` in a terminal and refresh the menu with `kbuildsycoca5`.

---

## 🚀 Usage

### Right-Click Compression

1. Open **Dolphin** and navigate to your images (JPEG or PNG).

2. Right-click on one or multiple files.

3. Select **“Compress Images”** from the context menu.

4. A terminal window will open:

   * Enter the **target file size** in kB (default 500 KB); this applies to JPEG compression.
   * Choose whether to **overwrite originals** (`y`) or create `_compressed` copies.

5. The script will compress each file and display status messages:

```
🔧 Compressing image.jpg -> image_compressed.jpg (target 500kb)...
✅ Done: image_compressed.jpg
```

---

### Terminal Usage (Optional)

You can also run the script manually in a terminal:

```bash
~/.local/bin/compress_images.sh image1.jpg image2.png
```

* Supports multiple files at once.
* Interactive prompts will appear in the terminal.

---

## ⚡ Features

* Process **JPEG and PNG** images without resizing. Without `pngquant`, PNG files are converted to JPEG, which can discard transparency and image data.
* Interactive **target size selection** (default: 500 KB).
* Option to **overwrite originals** or save as `_compressed` copies.
* Skips unsupported files and continues processing remaining files.
* Integrated with Dolphin via **right-click context menu**.

**Warning:** Overwriting replaces the source image, and PNG-to-JPEG conversion is lossy. Keep a backup of originals if you may need them.
