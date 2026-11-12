# Play DVDs on Linux

Commercial DVDs are copy-protected with CSS. Ubuntu does not ship the required decryption library, `libdvdcss`, for legal reasons. Without it, every player fails: VLC, mpv, and Totem may show an error or open the DVD as an empty folder.

The `libdvd-pkg` package downloads the source code and builds `libdvdcss` locally. This takes about one to two minutes and requires an internet connection.

> **Legal note:** Check whether using or installing CSS decryption software is permitted in your jurisdiction. This guide describes a technical procedure; it does not provide legal advice.

## ✨ Features

- Installs the `libdvdcss` CSS decryption library on Ubuntu/Debian.
- Enables playback of commercial DVDs in VLC and other media players.
- Includes checks for the most common playback problems.
- Does not change the DVD region unless you explicitly run `regionset`.

## ⚙️ Set-Up

### 📋 Requirements

- Ubuntu or an Ubuntu-based distribution with APT.
- A DVD drive, usually `/dev/sr0`.
- `sudo` privileges.
- An internet connection; the build tools are installed automatically.
- VLC or another optical-media-capable player.

### 📦 Installation

Install the package:

```bash
sudo apt install libdvd-pkg
```

Build the library:

```bash
sudo dpkg-reconfigure libdvd-pkg
```

When asked **"Do you want to build libdvdcss?"**, select **Yes** and confirm. Enter your login password when prompted. The build takes one to two minutes.

### 🔍 Verify the installation

```bash
dpkg -l libdvdcss2
```

The first column must show `ii`, for example:

```text
ii  libdvdcss2  1.5.0-1~local  amd64  library for accessing encrypted DVDs
```

If the package is not found, the build step did not complete. Repeat the `dpkg-reconfigure` command and confirm the build prompt.

## 🚀 Usage

1. Insert the DVD and wait until the drive settles.
2. Open VLC.
3. Choose **Media → Open Disc → DVD**, select the drive (usually `/dev/sr0`), and click **Play**.

Or start playback from the terminal:

```bash
vlc dvd:///dev/sr0
```

> **Important:** Do not open the DVD from the file manager and click the `.VOB` files in `VIDEO_TS`. That does not work reliably for copy-protected DVDs, even after installing `libdvdcss`. Always open the disc as a DVD.

## 🔧 Troubleshooting

### Green, flickering, or flashing frames

This is usually a video-output or hardware-acceleration problem, not a damaged DVD. It is most common on Ubuntu with Wayland.

1. Open **Tools → Preferences → Video** in VLC.
2. Set **Output** to **X11 video output (XCB)** instead of **Automatic**.
3. Close and reopen VLC, then start the DVD again.

If the problem remains:

1. Open **Tools → Preferences → Input/Codecs**.
2. Set **Hardware-accelerated decoding** to **Disable**.
3. Restart VLC.

DVD video is easy to decode on the CPU. These settings do not noticeably increase CPU usage and remain saved.

### Region-code message

DVDs and drives are assigned regions; Europe is usually region 2. A message such as `region mismatch` can be checked with:

```bash
sudo apt install regionset
sudo regionset /dev/sr0
```

`regionset` displays the current drive region.

> **Warning:** A drive's region can only be changed a few times, usually five. After that, the change is permanent. Only change it when the displayed region really differs from the DVD (Europe = 2).

### Playback stutters or stops

This is usually a dirty or scratched disc. Wipe the disc with a soft cloth from the center outward, not in circles. Do not use alcohol or abrasive cleaners.

## 🗑️ Uninstall

```bash
sudo apt remove libdvd-pkg libdvdcss2
```

## 📝 Quick reference

```bash
sudo apt install libdvd-pkg
sudo dpkg-reconfigure libdvd-pkg     # Answer "Yes" to "build libdvdcss?"
dpkg -l libdvdcss2                   # Must show "ii"
vlc dvd:///dev/sr0                   # Start the DVD
```

For green or flickering frames, also set **Tools → Preferences → Video → Output** to **X11 video output (XCB)**.

## 📝 Notes / Warnings

- The procedure was tested on Ubuntu 26.04 with VLC 3.0.23 and libdvdcss 1.5.0.
- Menu names can differ slightly between VLC versions and desktop themes.
- A commercial DVD may still use additional copy protection or a region mismatch that `libdvdcss` cannot bypass.
- Removing the packages does not delete the downloaded source or build cache.
- Do not change the drive region unless the current setting is actually wrong.