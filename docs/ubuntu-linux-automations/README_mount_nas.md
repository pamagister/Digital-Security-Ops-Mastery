# NAS Mount Script (`mount_nas.sh`)

This script allows you to mount, unmount, and configure automatic mounting of NAS shares on Ubuntu Linux.

---

## 📥 Prerequisites

1. Install the CIFS utilities and download the script:

```bash
sudo apt install cifs-utils
curl -fL -o mount_nas.sh https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations/scripts/mount_nas.sh
```

2. Create a credentials file:

```bash
sudo nano /etc/samba/credentials_nas
````

Contents:

```
username=YOUR_NAS_USERNAME
password=YOUR_NAS_PASSWORD
```

Replace the second placeholder line with `password=YOUR_NAS_PASSWORD`; CIFS credential files require both `username=` and `password=` entries.

3. Restrict permissions:

```bash
sudo chmod 600 /etc/samba/credentials_nas
```

4. Make the script executable:

```bash
chmod +x mount_nas.sh
```

---

## ⚙️ Configuration

Edit the script variables as needed:

```bash
NAS_HOST="NAS_HOST_NAME.local"
MOUNT_BASE="/mnt/nas"
CREDENTIALS="/etc/samba/credentials_nas"

# Shares to mount
SHARES=("book" "data" "music" "photo" "software" "video" "data_encrypt" "cloud")
```

---

## 🚀 Usage

Configure `NAS_HOST`, `MOUNT_BASE`, `CREDENTIALS`, and the share names in the script first. Then run it with `sudo`:

```bash
sudo ./mount_nas.sh
```

You will be prompted to select an action:

| Option | Description                                          |
| ------ | ---------------------------------------------------- |
| 1      | Mount all shares (default)                           |
| 2      | Unmount all shares                                   |
| 3      | Enable automount on restart (writes to `/etc/fstab`) |

---

## ⚙️ Automount Details

When choosing option 3:

* The script backs up `/etc/fstab` automatically.
* Old NAS entries are removed.
* New entries are added with UID and GID from the invoking user (when run through `sudo`).
* Shares will mount automatically at system boot via systemd.

The script removes `/etc/fstab` content from its `# Synology NAS - Automount Shares` marker to the end of the file before writing new entries. Review and back up `/etc/fstab`; keep unrelated custom entries before that marker.

Test the new fstab entries:

```bash
sudo mount -a
```

---

## 📝 Notes

* The script checks if the NAS host is reachable before mounting.
* Existing mounts are unmounted first to avoid conflicts.
* File and directory permissions are set to `0664` and `0775`, respectively.
* The script requests SMB 2.0 (`vers=2.0`). Confirm that the NAS supports it; do not enable SMB1 just to make a connection work.
* Keep the credentials file readable only by root, and do not expose SMB/CIFS to the public internet.

---

## 🚀 Example

Mount all shares manually:

```bash
sudo ./mount_nas.sh
# Select 1
```

Enable automount:

```bash
sudo ./mount_nas.sh
# Select 3
sudo mount -a   # optional test
```
