# NAS Mount Script (`mount_nas.sh`)

This script allows you to mount, unmount, and configure automatic mounting of NAS shares on Ubuntu Linux.

## ✨ Features

- Mount and unmount multiple CIFS/SMB shares.
- Check NAS reachability before mounting.
- Enable automount on restart by writing entries to `/etc/fstab`.
- Set file and directory permissions (`0664` / `0775`).

## ⚙️ Set-Up

### Requirements

- `cifs-utils`
- Root/sudo privileges (mounting requires elevated permissions).

### Installation

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"

mkdir -p "$HOME/.local/bin"

sudo apt install -y cifs-utils

curl -fL "$BASE_URL/scripts/mount_nas.sh" -o "$HOME/.local/bin/mount_nas.sh"
chmod +x "$HOME/.local/bin/mount_nas.sh"
```

### Manual installation

1. Install `cifs-utils`:

   ```bash
   sudo apt install -y cifs-utils
   ```

2. Download [`mount_nas.sh`](scripts/mount_nas.sh) to `~/.local/bin/`.
3. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/mount_nas.sh
   ```

4. Create a credentials file:

   ```bash
   sudo nano /etc/samba/credentials_nas
   ```

   Contents:

   ```
   username=YOUR_NAS_USERNAME
   password=YOUR_NAS_PASSWORD
   ```

5. Restrict permissions:

   ```bash
   sudo chmod 600 /etc/samba/credentials_nas
   ```

## 🚀 Usage

Configure `NAS_HOST`, `MOUNT_BASE`, `CREDENTIALS`, and the share names in the script first. Then run it with `sudo`:

```bash
sudo $HOME/.local/bin/mount_nas.sh
```

You will be prompted to select an action:

| Option | Description                                          |
| ------ | ---------------------------------------------------- |
| 1      | Mount all shares (default)                           |
| 2      | Unmount all shares                                   |
| 3      | Enable automount on restart (writes to `/etc/fstab`) |

### Automount details

When choosing option 3:

- The script backs up `/etc/fstab` automatically.
- Old NAS entries are removed.
- New entries are added with UID and GID from the invoking user (when run through `sudo`).
- Shares will mount automatically at system boot via systemd.

The script removes `/etc/fstab` content from its `# Synology NAS - Automount Shares` marker to the end of the file before writing new entries. Review and back up `/etc/fstab`; keep unrelated custom entries before that marker.

Test the new fstab entries:

```bash
sudo mount -a
```

## 💡 Examples

Mount all shares manually:

```bash
sudo $HOME/.local/bin/mount_nas.sh
# Select 1
```

Enable automount:

```bash
sudo $HOME/.local/bin/mount_nas.sh
# Select 3
sudo mount -a   # optional test
```

## 📝 Notes

- The script checks if the NAS host is reachable before mounting.
- Existing mounts are unmounted first to avoid conflicts.
- File and directory permissions are set to `0664` and `0775`, respectively.
- The script requests SMB 2.0 (`vers=2.0`). Confirm that the NAS supports it; do not enable SMB1 just to make a connection work.
- Keep the credentials file readable only by root, and do not expose SMB/CIFS to the public internet.