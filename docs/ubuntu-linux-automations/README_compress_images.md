# Image Compression Tool (Linux/Kubuntu)

A simple interactive script to process JPEG and PNG images without resizing. JPEG output is targeted to a selected file size. PNG handling depends on whether `pngquant` is installed: it may create a palette-based PNG, or convert the image to JPEG if `pngquant` is unavailable.

## ✨ Features

- Process **JPEG and PNG** images without resizing.
- Interactive **target size selection** (default: 500 KB).
- Option to **overwrite originals** or save as `_compressed` copies.
- Skips unsupported files and continues processing remaining files.
- Integrated with Dolphin via **right-click context menu**.
- Without `pngquant`, PNG files are converted to JPEG, which can discard transparency and image data.

## ⚙️ Set-Up

### Requirements

- ImageMagick (required for image compression).
- `pngquant` (optional; used for PNG palette compression).
- `konsole` (used to open the interactive script).

### Installation

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/kservices5/ServiceMenus"

sudo apt install -y imagemagick konsole
# Optional, for palette-based PNG compression:
# sudo apt install -y pngquant

curl -fL "$BASE_URL/scripts/compress_images.sh" -o "$HOME/.local/bin/compress_images.sh"
curl -fL "$BASE_URL/scripts/compress_images.desktop" -o "$HOME/.local/share/kservices5/ServiceMenus/compress_images.desktop"

sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/kservices5/ServiceMenus/compress_images.desktop"
chmod +x "$HOME/.local/bin/compress_images.sh"
kbuildsycoca5
```

### Manual installation

1. Install `imagemagick` and `konsole` using your package manager. Install `pngquant` there too if desired; without it, PNG files are converted to JPEG.
2. Copy [`compress_images.sh`](scripts/compress_images.sh) to `~/.local/bin/` and [`compress_images.desktop`](scripts/compress_images.desktop) to `~/.local/share/kservices5/ServiceMenus/`. Create the destination directories if needed.
3. Replace `@HOME@` in the desktop file with the full path to your home directory.
4. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/compress_images.sh
   ```

5. Refresh the KDE menu cache:

   ```bash
   kbuildsycoca5
   ```

## 🚀 Usage

### Right-click compression

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

### Terminal usage (optional)

You can also run the script manually in a terminal:

```bash
~/.local/bin/compress_images.sh image1.jpg image2.png
```

* Supports multiple files at once.
* Interactive prompts will appear in the terminal.

## 📝 Notes

**Warning:** Overwriting replaces the source image, and PNG-to-JPEG conversion is lossy. Keep a backup of originals if you may need them.