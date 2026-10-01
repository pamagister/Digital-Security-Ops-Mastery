# sync_dir.sh Documentation

## ✨ Overview
`sync_dir.sh` is a bidirectional synchronization script that keeps a local gocryptfs-encrypted container in sync with a NAS target using **Unison**.  

It automates:
- Mounting/unmounting encrypted containers.
- Initializing `gocryptfs` if needed.
- Bidirectional sync between:
  - `LOCAL_DOCS` ↔ `LOCAL_DECRYPTED` (plain text files).
  - `LOCAL_ENCRYPTED` ↔ `NAS_TARGET` (encrypted files).
- Optional restore and reset workflows.

⚠️ **Important**:
- Synchronization can propagate file deletions and changes. Keep a separate backup and test recovery before relying on this script.
- The script runs Unison in batch mode; conflict handling is not interactive. Review its behavior with test data before using it on important files.
- `--reset` deletes the local encrypted container directory (`LOCAL_ENCRYPTED`) and its logs. Do not use it as routine cleanup; make sure another valid copy exists first.

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


---

## ⚙️ Requirements
The following tools must be installed and available in `PATH`:
- `gocryptfs`
- `unison`
- `rsync`
- `fusermount`

Check installation:
```bash
command -v gocryptfs unison rsync fusermount
````

---

## 📥 Setup

### 1. Download the script
```bash
curl -fL -o ~/sync_dir.sh https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations/scripts/sync_dir.sh
```
   
### 2. Make the script executable

```bash
chmod +x ~/sync_dir.sh
```

### 3. Configure paths

The script defaults to the current user's `~/Documents` and a NAS directory mounted at `/mnt/nas/data/Backups/encrypted_docs_backup`. Edit these variables near the top of the script if your paths differ:

```bash
LOCAL_DOCS="$HOME/Documents/"
LOCAL_ENCRYPTED="$HOME/.encrypted_docs"
LOCAL_DECRYPTED="$HOME/.decrypted_docs"
NAS_TARGET="/mnt/nas/data/Backups/encrypted_docs_backup"
CRED_FILE="/etc/samba/credentials_sync_docs"
```

### 4. Set up the credential file

```bash
sudo nano /etc/samba/credentials_sync_docs
```

The file contains the gocryptfs container passphrase on its first non-empty line. Protect it carefully and do not reuse your NAS login password:

```
YOUR_PASSWORD_HERE
```

Secure it:

```bash
sudo chmod 600 /etc/samba/credentials_sync_docs
```

---

## 🚀 Usage

### Normal Sync (default)

Mount the encrypted directory and synchronize it with the NAS target:

```bash
./sync_dir.sh
```

### Restore Local Documents

Restore decrypted files from NAS into `LOCAL_DOCS`:

```bash
./sync_dir.sh --restore
```

### Initial Backup

Use only after confirming that `NAS_TARGET` is mounted, points to the intended directory, and contains no data that must be preserved. The script does not verify that the target is empty:

```bash
./sync_dir.sh --init-backup
```

### Reset Environment

Unmount the decrypted mount and delete the local encrypted container directory and logs. `LOCAL_DOCS` and the NAS target are not deleted:

```bash
./sync_dir.sh --reset
```

### Help

```bash
./sync_dir.sh --help
```

---

## 🟢 Recovery (Manual)

If needed, manually access the encrypted NAS backup (use the actual mounted NAS path):

```bash
# Example NAS target
NAS_TARGET="/mnt/nas/data/Backups/encrypted_docs_backup"

# Create a mountpoint
mkdir -p "$HOME/tmp/nas_decrypted"

# Mount (read-only for safety, password prompt)
gocryptfs -ro "$NAS_TARGET" "$HOME/tmp/nas_decrypted"

# After work, unmount
fusermount -u "$HOME/tmp/nas_decrypted"
```

---

## 📝 Logging

Logs are written to:

```
/tmp/log/sync_dir/sync_<DATE>_<TIME>.log
```

---

## ℹ️ Examples

```bash
./sync_dir.sh                # Normal sync
./sync_dir.sh --restore      # Restore local documents from NAS
./sync_dir.sh --init-backup  # Push initial encrypted backup to NAS
./sync_dir.sh --reset        # Reset mounts and cleanup logs
```

---

## 📝 Notes

* Unison is called with `-batch`; do not expect interactive conflict resolution.
* Restore uses `rsync --update --backup` and prompts before copying. Older/overwritten destination files are placed in a timestamped sibling backup directory.
* `--reset` removes the local encrypted container; it does not securely erase storage or remove the NAS copy.
* Temporary password helper files are removed on exit. This does not replace protecting the credential file itself.
