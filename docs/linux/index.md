# Linux &amp; automation

Guides and scripts for Ubuntu/Kubuntu setup, system maintenance, network storage, encrypted synchronization, media processing, and map data. Most scripts are Bash and target the user's local desktop; several require `sudo` or change system configuration.

## 🛠️ Setup and system

<div class="dsom-grid">
  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/kubuntu-setup/">
    <img src="../_static/img/ubuntu.png" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Setup</span><br>
    <strong>Kubuntu setup</strong><br>
    <span>Automated application groups, security settings, and desktop configuration.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/system-update/">
    <img src="../_static/img/icons/gear.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Maintenance</span><br>
    <strong>System update</strong><br>
    <span>Update APT, Snap, and Flatpak packages with optional cleanup.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/auto-update/">
    <img src="../_static/img/icons/sync.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Maintenance</span><br>
    <strong>Automatic updates</strong><br>
    <span>Configure unattended upgrades, including automatic reboots.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/kde-language/">
    <img src="../_static/img/icons/tools.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Desktop</span><br>
    <strong>KDE language</strong><br>
    <span>Use one language for the interface and another for regional formats.</span>
  </a>
</div>

## 🌐 Network and storage

<div class="dsom-grid">
  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/nas-mount/">
    <img src="../_static/img/icons/cloud.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">NAS</span><br>
    <strong>Mount NAS shares</strong><br>
    <span>Mount CIFS/SMB shares once or configure systemd automount.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/encrypted-sync/">
    <img src="../_static/img/icons/sync.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Sync</span><br>
    <strong>Encrypted sync</strong><br>
    <span>Bidirectional Unison sync with a gocryptfs-encrypted container.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/encrypt-backup/">
    <img src="../_static/img/icons/tools.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Backup</span><br>
    <strong>Encrypt a directory</strong><br>
    <span>Create a password-protected tar.gz backup with OpenSSL.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/printer-scan-samba/">
    <img src="../_static/img/icons/printer.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Printer</span><br>
    <strong>Printer scan to Samba</strong><br>
    <span>Configure a Brother MFC-9332CDW to scan into a Linux Samba share.</span>
  </a>
</div>

## 🎬 Media processing

<div class="dsom-grid">
  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/dvd-playback/">
    <img src="../_static/img/icons/dvd.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Optical media</span><br>
    <strong>Play DVDs</strong><br>
    <span>Install libdvdcss and play commercial DVDs in VLC.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/compress-images/">
    <img src="../_static/img/icons/image.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Images</span><br>
    <strong>Compress images</strong><br>
    <span>Compress JPEG/PNG files from the Dolphin context menu.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/compress-videos/">
    <img src="../_static/img/icons/film.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Video</span><br>
    <strong>Compress videos</strong><br>
    <span>Recursively compress videos with FFmpeg, with audio and quality options.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/postprocess-video/">
    <img src="../_static/img/icons/film.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Video</span><br>
    <strong>Post-process video</strong><br>
    <span>Add music, an intro, a title, fades, and a timestamp overlay.</span>
  </a>
</div>

## 🗺️ Navigation and map data

<div class="dsom-grid">
  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/gpx-kml/">
    <img src="../_static/img/gpx.png" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">GPX/KML</span><br>
    <strong>Process GPX/KML files</strong><br>
    <span>Compress, merge, or extract POIs from GPX/KML files in Dolphin.</span>
  </a>

  <a class="dsom-card" href="https://digital-security-ops-mastery.readthedocs.io/en/latest/linux/gpx-pois-from-yaml/">
    <img src="../_static/img/icons/pushpin.svg" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">POI</span><br>
    <strong>GPX POIs from YAML</strong><br>
    <span>Turn a YAML place list into GPX waypoints with a geocoding MCP server.</span>
  </a>
</div>

## 🚧 Planned

<div class="dsom-grid">
  <div class="dsom-card">
    <img src="../_static/img/ubuntu-children.png" alt="" width="48" height="48"><br>
    <span class="dsom-kicker">Planned</span><br>
    <strong>Child-proof Ubuntu PC</strong><br>
    <span>A planned guide for a safer, child-friendly Ubuntu desktop. Not yet available.</span>
  </div>
</div>

## 📝 Safety notes

- Read the requirements and the script before running it. Several guides install packages, change system settings, or mount shares.
- Use `--help` where available and test scripts with disposable data first.
- `--reset`, `--init-backup`, restore, and overwrite modes can delete or replace data. Keep a separate backup.
- Some scripts target Kubuntu/Ubuntu with KDE Plasma. Commands such as `kwriteconfig5` and `kbuildsycoca5` are version-dependent.