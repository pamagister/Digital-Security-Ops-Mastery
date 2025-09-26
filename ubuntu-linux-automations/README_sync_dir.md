# sync_dir.sh Documentation

## Overview
`sync_dir.sh` is a bidirectional synchronization script that keeps a local gocryptfs-encrypted container in sync with a NAS target using **Unison**.  

It automates:
- Mounting/unmounting encrypted containers.
- Initializing `gocryptfs` if needed.
- Bidirectional sync between:
  - `LOCAL_DOCS` ↔ `LOCAL_DECRYPTED` (plain text files).
  - `LOCAL_ENCRYPTED` ↔ `NAS_TARGET` (encrypted files).
- Optional restore and reset workflows.

⚠️ **Important**:  
- This script **never deletes files in `LOCAL_DOCS` without confirmation**.  
- File conflicts are handled interactively by **Unison**.

---

## Requirements
The following tools must be installed:
- `gocryptfs`
- `unison`
- `rsync`
- `fusermount`

Check installation:
```bash
which gocryptfs unison rsync fusermount
````

---

## Setup

### 0. Download the script
```bash
wget https://github.com/pamagister/Digital-Security-Ops-Mastery/blob/main/ubuntu-linux-automations/scripts/sync_dir.sh
```
   
### 1. Make the Script Executable

```bash
chmod +x ~/sync_dir.sh
```

### 2. Configure Paths

Inside the script, edit these variables as needed:

```bash
LOCAL_DOCS="$HOME/Documents/"
LOCAL_ENCRYPTED="$HOME/.encrypted_docs"
LOCAL_DECRYPTED="$HOME/.decrypted_docs"
NAS_TARGET="/mnt/nas/data/Backups/encrypted_docs_backup"
CRED_FILE="/etc/samba/credentials_sync_docs"
```

### 3. Setup Credential File

```bash
sudo nano /etc/samba/credentials_sync_docs
```

Content (password only):

```
YOUR_PASSWORD_HERE
```

Secure it:

```bash
sudo chmod 600 /etc/samba/credentials_sync_docs
```

---

## Usage

### Normal Sync (default)

Bidirectional sync between local documents and NAS backup:

```bash
./sync_dir.sh
```

### Restore Local Documents

Restore decrypted files from NAS into `LOCAL_DOCS`:

```bash
./sync_dir.sh --restore
```

### Initial Backup

Use when NAS target is empty:

```bash
./sync_dir.sh --init-backup
```

### Reset Environment

Unmount, remove containers, and cleanup logs (does **not** delete `LOCAL_DOCS`):

```bash
./sync_dir.sh --reset
```

### Help

```bash
./sync_dir.sh --help
```

---

## Recovery (Manual)

If needed, you can manually access encrypted NAS backups:

```bash
# Example NAS target
NAS_TARGET="/mnt/nas/data/Backups/encrypted_documents"

# Create a mountpoint
mkdir -p tmp/nas_decrypted

# Mount (read-only for safety, password prompt)
gocryptfs -ro "$NAS_TARGET" tmp/nas_decrypted

# After work, unmount
fusermount -u tmp/nas_decrypted
```

---

## Logging

Logs are written to:

```
/tmp/log/sync_dir/sync_<DATE>_<TIME>.log
```

---

## Examples

```bash
./sync_dir.sh                # Normal sync
./sync_dir.sh --restore      # Restore local documents from NAS
./sync_dir.sh --init-backup  # Push initial encrypted backup to NAS
./sync_dir.sh --reset        # Reset mounts and cleanup logs
```

---

## Notes

* Conflicts are resolved interactively by **Unison**.
* `rsync` is used for safe restores and backups.
* On exit, temporary scripts are securely deleted.

