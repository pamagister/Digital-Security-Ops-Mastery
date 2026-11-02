# NAS Mount Script (`mount_nas.sh`)

This script allows you to mount, unmount, and configure automatic mounting of NAS shares on Ubuntu Linux.

## ✨ Features

- Mount and unmount multiple CIFS/SMB shares interactively.
- Check NAS reachability before mounting.
- Configure persistent automount via `/etc/fstab` with systemd.
- Mount shares once without persistent configuration.
- Remove automount configuration and unmount shares.
- Secure credential handling with restrictive permissions.
- Atomic `/etc/fstab` updates with timestamped backups.
- Set file and directory permissions (`0664` / `0775`).

## ⚙️ Set-Up

### Requirements

- `cifs-utils`
- Root/sudo privileges (mounting requires elevated permissions).
- Ubuntu/Debian with systemd.

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

## 🚀 Script Operation

Run the script with `sudo`:

```bash
sudo $HOME/.local/bin/mount_nas.sh
```

The script provides an interactive menu with four options:

| Option | Description |
|:---:|---|
| **1** | Configure automatic mounting via `/etc/fstab` (default). |
| **2** | Mount all configured shares once, without enabling automount. |
| **3** | Unmount NAS shares and remove the script-managed automount configuration. |
| **4** | Exit without making changes. |

### Option 1: Configure Automount (Default)

Configures persistent NAS mounting using `/etc/fstab` and systemd automount.

1. Prompt for NAS host, SMB username, and shares.
2. Create or update the credentials file.
3. Create mount points under `/mnt/nas`.
4. Back up `/etc/fstab`.
5. Replace the script-managed configuration block.
6. Reload systemd and activate automount units.

NAS shares mount automatically when their mount points are accessed, avoiding startup delays if the NAS is unreachable.

### Option 2: Mount Shares Once

Mounts configured NAS shares immediately without modifying `/etc/fstab`.

- Existing mounts are detected and skipped.
- Each share is processed independently.
- Failures for individual shares do not block others.
- Mounts persist until manually unmounted or system restart.

### Option 3: Remove Automount Configuration

Removes script-managed automount configuration and unmounts shares.

1. Stop associated systemd automount units.
2. Unmount NAS shares.
3. Remove the managed block from `/etc/fstab`.
4. Reload systemd configuration.

The credentials file is preserved. Other `/etc/fstab` entries remain untouched.

### `/etc/fstab` Safety

The script manages only the section enclosed by its markers:

```text
# BEGIN NAS AUTOMOUNT CONFIGURATION (managed by mount_nas.sh)
...
# END NAS AUTOMOUNT CONFIGURATION
```

- A timestamped backup is created before changes.
- Previous managed entries are replaced, not duplicated.
- Content outside the managed section is preserved.
- The updated file is written atomically.

### Credentials

Stored by default in `/etc/samba/credentials_nas` with secure permissions:

```bash
sudo chown root:root /etc/samba/credentials_nas
sudo chmod 600 /etc/samba/credentials_nas
```

### SMB Protocol

The script does not force an SMB version. CIFS negotiates the highest mutually supported version between client and NAS.

## 💡 Examples

Configure automount (interactive, run with sudo):

```bash
sudo $HOME/.local/bin/mount_nas.sh
# Select 1, then follow prompts
```

Mount shares once (no persistence):

```bash
sudo $HOME/.local/bin/mount_nas.sh
# Select 2
```

Remove automount and unmount:

```bash
sudo $HOME/.local/bin/mount_nas.sh
# Select 3
```

Check active CIFS mounts:

```bash
findmnt -t cifs
```

## 📝 Notes

- The script checks NAS reachability (DNS resolution and port 445) before mounting.
- Mount points are created automatically under `/mnt/nas/`.
- File and directory permissions are set to `0664` and `0775`.
- UID/GID are taken from the invoking user via `SUDO_UID`/`SUDO_GID`.
- Keep the credentials file readable only by root.
- Do not expose SMB/CIFS to the public internet.