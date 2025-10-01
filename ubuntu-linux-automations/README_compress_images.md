# Image Compression Tool (Linux/Kubuntu)

A simple interactive script to compress JPEG and PNG images to a target file size without resizing. Integrated into Dolphin via a right-click context menu.

---

## 📦 Requirements

* **Linux (Kubuntu)**
* **Dolphin file manager**
* **ImageMagick** (for image compression)

Install ImageMagick if not already installed:

```bash
sudo apt install imagemagick
```

---

## ⚙️ Setup

### 1. Place the script

Put the script somewhere convenient, e.g.:

```text
/home/username/scripts/compress_images.sh
```

Make it executable:

```bash
chmod +x /home/username/scripts/compress_images.sh
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

   * Enter the **target file size** in kB (default 500 KB).
   * Choose whether to **overwrite originals** (`y`) or create prefixed copies (`compressed_`).

5. The script will compress each file and display status messages:

```
🔧 Compressing image.jpg -> compressed_image.jpg (target 500kb)...
✅ Done: compressed_image.jpg
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

* Compress **JPEG and PNG** images without resizing.
* Interactive **target size selection** (default: 500 KB).
* Option to **overwrite originals** or save as `compressed_` copies.
* Skips unsupported files and continues processing remaining files.
* Integrated with Dolphin via **right-click context menu**.
