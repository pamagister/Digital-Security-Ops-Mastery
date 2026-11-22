# Borg backup to a NAS repository

[Borg](https://www.borgbackup.org/) is a deduplicating backup program. It stores only changed blocks, compresses them, and encrypts and authenticates every archive. This guide sets up a repository on a mounted NAS share and shows how to create, inspect, restore, and prune backups. It also installs a small wrapper script and an optional KDE launcher.

## ✨ Features

- Incremental, deduplicated backups of a directory.
- Compression (`lz4` by default) and authenticated encryption (`repokey-blake2`).
- Retention rules for daily, weekly, and monthly archives.
- Repository check and restore instructions.
- `borg_backup.sh` wrapper with a default source, repository, and retention policy.
- Optional KDE launcher that runs the backup in a terminal window.

## ⚙️ Set-Up

### 📋 Requirements

- `borgbackup` (package `borgbackup` on Ubuntu/Kubuntu).
- Bash.
- A mounted, writable target. This guide uses the NAS share at `/mnt/nas/data_encrypt/Borg-Backup`.
- `konsole` only for the optional KDE launcher.
- A long, unique repository passphrase stored in a password manager.

Check the target first:

```bash
borg --version
mountpoint /mnt/nas
test -w /mnt/nas/data_encrypt/Borg-Backup && echo writable
```

See [NAS mount](nas-mount.md) if the share is not mounted yet.

### 📦 Installation

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/linux"

sudo apt install -y borgbackup

mkdir -p "$HOME/.local/bin"

curl -fL "$BASE_URL/scripts/borg_backup.sh" \
    -o "$HOME/.local/bin/borg_backup.sh"
chmod +x "$HOME/.local/bin/borg_backup.sh"
```

Optional KDE launcher:

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/linux"

mkdir -p "$HOME/.local/share/applications"

curl -fL "$BASE_URL/scripts/borg_backup.desktop" \
    -o "$HOME/.local/share/applications/borg_backup.desktop"

sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/applications/borg_backup.desktop"
```

### 🔩 Manual installation

1. Install Borg:

   ```bash
   sudo apt install -y borgbackup
   ```

2. Download [`borg_backup.sh`](scripts/borg_backup.sh) to `~/.local/bin/` and make it executable:

   ```bash
   chmod +x ~/.local/bin/borg_backup.sh
   ```

3. Optional: download [`borg_backup.desktop`](scripts/borg_backup.desktop) to `~/.local/share/applications/` and replace `@HOME@` with your home directory.

### 🔐 Create the repository

Borg refuses to write into a non-empty directory. Create the repository once, before the first backup:

```bash
mkdir -p /mnt/nas/data_encrypt/Borg-Backup

borg init --encryption=repokey-blake2 \
    /mnt/nas/data_encrypt/Borg-Backup
```

Borg asks for a repository passphrase twice. With `repokey-blake2` the encryption key is stored inside the repository and protected by that passphrase. Export the key and store it offline, separately from the repository:

```bash
borg key export /mnt/nas/data_encrypt/Borg-Backup \
    > "$HOME/borg-repo-key.txt"
chmod 600 "$HOME/borg-repo-key.txt"
```

Without the passphrase, and on another machine without the exported key, the repository cannot be read. Store both in your password manager.

### 🔑 Passphrase handling

For interactive use, set the passphrase once per shell:

```bash
read -r -s BORG_PASSPHRASE
export BORG_PASSPHRASE
```

For scripts and automation, use a permission-restricted file:

```bash
install -m 600 /dev/null "$HOME/.config/borg/passphrase"
nano "$HOME/.config/borg/passphrase"

export BORG_PASSCOMMAND="cat $HOME/.config/borg/passphrase"
```

`BORG_PASSCOMMAND` is evaluated by Borg; the command string should not contain spaces in the file path. Put the export line in your shell profile or in the automation environment, not in a script that is stored with the repository.

## 🚀 Usage

### The wrapper script

Create a backup with the defaults (`~/Documents` into `/mnt/nas/data_encrypt/Borg-Backup`):

```bash
~/.local/bin/borg_backup.sh
```

Create the repository on the first run:

```bash
~/.local/bin/borg_backup.sh --init
```

Back up a different directory:

```bash
~/.local/bin/borg_backup.sh /home/paul/Dokumente
```

Override the repository or archive prefix:

```bash
BORG_REPO=/mnt/backup/borg \
BORG_ARCHIVE_PREFIX=laptop-docs \
    ~/.local/bin/borg_backup.sh /home/paul/Dokumente
```

The script creates one archive per run, named `<hostname>-documents-<timestamp>`, then applies the retention policy. If neither `BORG_PASSPHRASE` nor `BORG_PASSCOMMAND` is set, it asks for the passphrase once.

Show the options:

```bash
~/.local/bin/borg_backup.sh --help
```

### Borg commands directly

List repositories and archives:

```bash
borg list /mnt/nas/data_encrypt/Borg-Backup
borg info /mnt/nas/data_encrypt/Borg-Backup
```

Create an archive:

```bash
borg create \
    --stats \
    --show-rc \
    --compression lz4 \
    --exclude-caches \
    /mnt/nas/data_encrypt/Borg-Backup::docs-2026-11-22 \
    /home/paul/Dokumente
```

Borg stores absolute paths without the leading slash. List the content of one archive:

```bash
borg list /mnt/nas/data_encrypt/Borg-Backup::docs-2026-11-22
```

Compare two archives:

```bash
borg diff \
    /mnt/nas/data_encrypt/Borg-Backup::docs-2026-11-20 \
    /mnt/nas/data_encrypt/Borg-Backup::docs-2026-11-22
```

Check the repository for damage:

```bash
borg check /mnt/nas/data_encrypt/Borg-Backup
```

## 🔓 Restore

Always restore into a dedicated directory and compare before replacing live data.

List available archives and pick one:

```bash
borg list /mnt/nas/data_encrypt/Borg-Backup
```

Restore a single directory into `~/borg-restore`:

```bash
mkdir -p "$HOME/borg-restore"
cd "$HOME/borg-restore"

borg extract \
    /mnt/nas/data_encrypt/Borg-Backup::docs-2026-11-22 \
    home/paul/Dokumente
```

Restore the whole archive:

```bash
borg extract /mnt/nas/data_encrypt/Borg-Backup::docs-2026-11-22
```

Browse an archive read-only without extracting it:

```bash
mkdir -p "$HOME/borg-mount"
borg mount /mnt/nas/data_encrypt/Borg-Backup::docs-2026-11-22 \
    "$HOME/borg-mount"

# Work on the files, then unmount
fusermount -u "$HOME/borg-mount"
```

To restore on another machine, install Borg, import the exported key, and set the passphrase:

```bash
borg key import /mnt/nas/data_encrypt/Borg-Backup \
    < "$HOME/borg-repo-key.txt"
```

## 🔄 Retention and automation

### Retention policy

The wrapper script prunes after every successful backup with these defaults:

| Archive interval | Keep |
|---|---|
| Daily | 7 |
| Weekly | 4 |
| Monthly | 6 |

Run pruning manually:

```bash
borg prune --list --show-rc \
    --keep-daily=7 --keep-weekly=4 --keep-monthly=6 \
    /mnt/nas/data_encrypt/Borg-Backup
```

`borg prune` deletes archives. Review the `--list` output and the retention values before running it on the only copy of important data.

### Scheduled backup with cron

Make sure the NAS is mounted, `~/.cache` exists, and the passphrase is available non-interactively:

```cron
0 2 * * * flock -n "$HOME/.cache/borg_backup.lock" BORG_PASSCOMMAND="cat $HOME/.config/borg/passphrase" "$HOME/.local/bin/borg_backup.sh" >> "$HOME/.local/share/borg_backup.log" 2>&1
```

`flock` prevents overlapping runs. Check the log if a scheduled backup fails.

### Free space

Borg keeps deleted and replaced chunks until the repository is compacted:

```bash
borg compact /mnt/nas/data_encrypt/Borg-Backup
```

Run `borg compact` only when the repository needs space, and keep a second copy of important data while doing so.

## 💡 Examples

Nightly backup of the documents directory into the NAS repository:

```bash
~/.local/bin/borg_backup.sh /home/paul/Dokumente
```

Inspect the newest archive before a restore:

```bash
borg list --sort=timestamp /mnt/nas/data_encrypt/Borg-Backup | tail -3
```

Restore one folder from a specific archive:

```bash
borg extract /mnt/nas/data_encrypt/Borg-Backup::docs-2026-11-22 \
    home/paul/Dokumente/Steuer
```

## 📝 Notes / Warnings

- The repository directory must be mounted and writable before a backup. A backup into the mount point directory on the local disk is not a backup.
- `repokey-blake2` stores the key inside the repository. Export it with `borg key export` and keep a copy outside the repository.
- The passphrase is not recoverable. If it is lost, the repository is unreadable.
- Borg uses file locks. Some SMB/CIFS versions do not handle them reliably; test `borg check` and `borg create` on your share before relying on scheduled backups. If locking fails, mount the share differently or use an SSH repository.
- The NAS share name `data_encrypt` suggests encryption at the storage layer. Borg encryption is independent of that; keep both layers if the threat model requires it.
- `borg prune`, `borg compact`, and `--init` can remove or change data. Do not point them at a repository that holds the only copy.
- Test the restore before relying on the backup. A backup that has never been restored is an assumption, not a backup.
- On German systems the documents folder is usually `~/Dokumente` instead of `~/Documents`. Adjust the source path accordingly.
- The KDE launcher runs the script in `konsole` and uses `@HOME@` as a placeholder. Replace it during installation.