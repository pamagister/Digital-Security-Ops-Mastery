# Image Compression Tool (Linux/Kubuntu)

A simple interactive script to process JPEG and PNG images without resizing. JPEG output is targeted to a selected file size. PNG handling depends on whether `pngquant` is installed: it may create a palette-based PNG, or convert the image to JPEG if `pngquant` is unavailable.

---

## 📦 Requirements

* **Linux (Kubuntu)**
* **Dolphin file manager**
* **ImageMagick** (for image compression)
* **pngquant** (optional; used for PNG palette compression)

Install ImageMagick if not already installed:

```bash
sudo apt install imagemagick
```

---

## ⚙️ Setup

### 1. Download the script

Download it to a convenient location, for example:

```bash
mkdir -p ~/scripts
curl -fL -o ~/scripts/compress_images.sh https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations/scripts/compress_images.sh
chmod +x ~/scripts/compress_images.sh
```

---

### 2. Create a Dolphin Service Menu

1. Create the service menu folder if it doesn’t exist:

```bash
mkdir -p ~/.local/share/kservices5/ServiceMenus
```

2. Create a file named `compress_images.desktop`:

```bash
nano ~/.local/share/kservices5/ServiceMenus/compress_images.desktop
```

3. Paste the following content (update the path to your script):

```ini
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=image/jpeg;image/png;
Actions=compressimages;
X-KDE-Priority=TopLevel

[Desktop Action compressimages]
Name=Compress Images
Exec=konsole -e /home/username/scripts/compress_images.sh %F
Icon=image
Terminal=true
```

4. Reload KDE services:

```bash
kbuildsycoca5
```

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
./compress_images.sh image1.jpg image2.png
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
