# sync_dir.sh (`sync_dir.sh`)

Bidirectional synchronization between a local `gocryptfs`-encrypted container and a NAS target using **Unison**. The script mounts/unmounts the encrypted container, initializes `gocryptfs` if needed, and keeps `LOCAL_DOCS` in sync with `NAS_TARGET`.

## Features

- Mount and unmount `gocryptfs`-encrypted containers.
- Initialize `gocryptfs` automatically when the container does not yet exist.
- Bidirectional Unison sync between `LOCAL_DOCS` and `LOCAL_DECRYPTED` (plain text).
- Bidirectional Unison sync between `LOCAL_ENCRYPTED` and `NAS_TARGET` (encrypted files).
- Optional restore of local documents from NAS.
- Optional reset of mounts, container directory, and logs.
- Optional initial backup push to an empty NAS target.

## Set-Up

### Requirements

The following tools must be installed and available in `PATH`:

- `gocryptfs`
- `unison`
- `rsync`
- `fusermount`

Check installation:

```bash
command -v gocryptfs unison rsync fusermount
```

### Installation

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations"

mkdir -p "$HOME/.local/bin"

curl -fL "$BASE_URL/scripts/sync_dir.sh" \
    -o "$HOME/.local/bin/sync_dir.sh"

chmod +x "$HOME/.local/bin/sync_dir.sh"
```

### Manual installation

1. Download [`scripts/sync_dir.sh`](scripts/sync_dir.sh) to `~/.local/bin/sync_dir.sh`.
2. Make the script executable:

   ```bash
   chmod +x ~/.local/bin/sync_dir.sh
   ```

### Configuration

Edit the variables near the top of the script if your paths differ:

```bash
LOCAL_DOCS="$HOME/Documents/"
LOCAL_ENCRYPTED="$HOME/.encrypted_docs"
LOCAL_DECRYPTED="$HOME/.decrypted_docs"
NAS_TARGET="/mnt/nas/data/Backups/encrypted_docs_backup"
CRED_FILE="/etc/samba/credentials_sync_docs"
```

Set up the credential file:

```bash
sudo nano /etc/samba/credentials_sync_docs
```

The file contains the `gocryptfs` container passphrase on its first non-empty line (a leading `password=` prefix is stripped). Protect it carefully and do not reuse your NAS login password:

```
YOUR_PASSWORD_HERE
```

Secure it:

```bash
sudo chmod 600 /etc/samba/credentials_sync_docs
```

## Sync Architecture Diagram

               ┌────────────────────┐
               │ 📂 LOCAL_DOCS      │
               │ ~/Documents/       │
               └─────────▲──────────┘
                         │
                         │ 🔄 Unison (bidirectional sync)
                         │
               ┌─────────▼──────────┐
               │ 📂 LOCAL_DECRYPTED │
               │ ~/.decrypted_docs  │
               └─────────▲──────────┘
                         │
                         │ 🔐 gocryptfs (encryption/decryption)
                         │
               ┌─────────▼──────────┐
               │ 📦 LOCAL_ENCRYPTED │
               │ ~/.encrypted_docs  │
               └─────────▲──────────┘
                         │
                         │ 🔄 Unison (bidirectional sync)
                         │
               ┌─────────▼──────────┐
               │ 💾 NAS_TARGET      │
               │ /mnt/nas/...backup │
               └────────────────────┘

## Usage

Run the script from a terminal:

```bash
~/.local/bin/sync_dir.sh
```

### Normal Sync (default)

Mounts the encrypted directory and synchronizes it with the NAS target:

```bash
~/.local/bin/sync_dir.sh
```

If `NAS_TARGET` is empty, an initial backup is performed automatically. If `LOCAL_DOCS` is empty, a restore from NAS is performed automatically. Otherwise a standard bidirectional sync runs (local ↔ decrypted ↔ NAS ↔ decrypted ↔ local), then the container is unmounted.

### Restore Local Documents

Restores decrypted files from NAS into `LOCAL_DOCS`:

```bash
~/.local/bin/sync_dir.sh --restore
```

The script first syncs `LOCAL_ENCRYPTED` ↔ `NAS_TARGET`, mounts the container, then prompts before copying. Older/overwritten destination files are moved to a timestamped backup directory sibling to `LOCAL_DOCS`.

### Initial Backup

Use only after confirming that `NAS_TARGET` is mounted, points to the intended directory, and contains no data that must be preserved:

```bash
~/.local/bin/sync_dir.sh --init-backup
```

### Reset Environment

Unmounts the decrypted mount and deletes the local encrypted container directory (`LOCAL_ENCRYPTED`), its mountpoint (`LOCAL_DECRYPTED`), and logs. `LOCAL_DOCS` and the NAS target are not deleted:

```bash
~/.local/bin/sync_dir.sh --reset
```

### Help

```bash
~/.local/bin/sync_dir.sh --help
```

## Notes / Warnings

- **Destructive operations**: `--reset` deletes the local encrypted container directory, its mountpoint, and its logs. It does not securely erase storage and does not remove the NAS copy. `--restore` may overwrite files in `LOCAL_DOCS`; backups of overwritten files are created first.
- Synchronization can propagate file deletions and changes. Keep a separate backup and test recovery before relying on this script.
- Unison runs in batch mode (`-batch`); conflict handling is not interactive. Review its behavior with test data before using it on important files.
- Restore uses `rsync --update --backup` and prompts before copying.
- Temporary password helper files are removed on exit. This does not replace protecting the credential file itself.
- Logs are written to `/tmp/log/sync_dir/sync_<DATE>_<TIME>.log` (falls back to `~/.local/share/sync_dir` if `/tmp/log` is not writable).

### Manual Recovery (Read-Only)

If needed, manually access the encrypted NAS backup (use the actual mounted NAS path):

```bash
NAS_TARGET="/mnt/nas/data/Backups/encrypted_docs_backup"

mkdir -p "$HOME/tmp/nas_decrypted"

gocryptfs -ro "$NAS_TARGET" "$HOME/tmp/nas_decrypted"

# After work, unmount
fusermount -u "$HOME/tmp/nas_decrypted"
```
