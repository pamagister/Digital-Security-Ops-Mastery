# NAS Mount Script (`mount_nas.sh`)

This script allows you to mount, unmount, and configure automatic mounting of NAS shares on Ubuntu Linux.

---

## Prerequisites

0. Download script file:

```bash
wget https://github.com/pamagister/Digital-Security-Ops-Mastery/blob/main/ubuntu-linux-automations/scripts/mount_nas.sh
```

1. Create a credentials file:

```bash
sudo nano /etc/samba/credentials_nas
````

Contents:

```
username=YOUR_NAS_USERNAME
password=YOUR_NAS_PASSWORD
```

2. Restrict permissions:

```bash
sudo chmod 600 /etc/samba/credentials_nas
```

3. Make the script executable:

```bash
chmod +x mount_nas.sh
```

---

## Configuration

Edit the script variables as needed:

```bash
NAS_HOST="NAS_HOST_NAME.local"
MOUNT_BASE="/mnt/nas"
CREDENTIALS="/etc/samba/credentials_nas"

# Shares to mount
SHARES=("book" "data" "music" "photo" "software" "video" "data_encrypt" "cloud")
```

---

## Usage

Run the script with `sudo`:

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

## Automount Details

When choosing option 3:

* The script backs up `/etc/fstab` automatically.
* Old NAS entries are removed.
* New entries are added with dynamic UID and GID based on the calling user.
* Shares will mount automatically at system boot via systemd.

Test the new fstab entries:

```bash
sudo mount -a
```

---

## Notes

* The script checks if the NAS host is reachable before mounting.
* Existing mounts are unmounted first to avoid conflicts.
* File and directory permissions are set to `0664` and `0775`, respectively.
* Compatible with CIFS/SMBv2.

---

## Example

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

