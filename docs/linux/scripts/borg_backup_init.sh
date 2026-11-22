#!/usr/bin/env bash
#
# Interactive first-time setup for Borg Backup.
# Supports local repositories on a mounted filesystem and Borg SSH repository URLs.
# Design target: Borg 1.x (preferably 1.4.x). Borg 2 is not supported yet.

set -Eeuo pipefail
IFS=$'\n\t'

PROGNAME="${0##*/}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/borg-backup"
CONFIG_FILE="$CONFIG_DIR/config"
PASSPHRASE_FILE="$CONFIG_DIR/passphrase"
ENCRYPTION="repokey-blake2"

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
info() { printf '\n==> %s\n' "$*"; }

prompt() {
    local __var="$1" __label="$2" __default="${3:-}" __value
    if [[ -n "$__default" ]]; then
        read -r -p "$__label [$__default]: " __value
        __value="${__value:-$__default}"
    else
        read -r -p "$__label: " __value
    fi
    printf -v "$__var" '%s' "$__value"
}

confirm() {
    local answer
    read -r -p "$1 [y/N]: " answer
    [[ "$answer" =~ ^([yY]|[yY][eE][sS])$ ]]
}

require_borg() {
    command -v borg >/dev/null 2>&1 || die "Borg is missing. Install it with: sudo apt install borgbackup"
    local version
    version="$(borg --version)"
    printf 'Detected: %s\n' "$version"
    [[ "$version" =~ ^borg[[:space:]]+1\. ]] ||
        die "These scripts currently target Borg 1.x. Borg 2 is not supported."
}

write_config() {
    local tmp source
    tmp="$(mktemp "$CONFIG_DIR/config.XXXXXX")"
    {
        printf '# Borg Backup configuration. Keep this file private (mode 600).\n'
        printf 'REPOSITORY_TYPE=%q\n' "$REPOSITORY_TYPE"
        printf 'BORG_REPO=%q\n' "$BORG_REPO"
        printf 'MOUNTPOINT=%q\n' "$MOUNTPOINT"
        printf 'ARCHIVE_PREFIX=%q\n' "$ARCHIVE_PREFIX"
        printf 'KEEP_DAILY=%q\n' "$KEEP_DAILY"
        printf 'KEEP_WEEKLY=%q\n' "$KEEP_WEEKLY"
        printf 'KEEP_MONTHLY=%q\n' "$KEEP_MONTHLY"
        printf 'COMPACT_AFTER_PRUNE=%q\n' "$COMPACT_AFTER_PRUNE"
        printf 'PASSPHRASE_FILE=%q\n' "$PASSPHRASE_FILE"
        printf 'SOURCES=('
        for source in "${SOURCES[@]}"; do printf ' %q' "$source"; done
        printf ' )\n'
    } > "$tmp"
    chmod 600 "$tmp"
    mv -f "$tmp" "$CONFIG_FILE"
}

info "Borg Backup – interactive setup"
require_borg

if [[ -e "$CONFIG_FILE" ]]; then
    die "Configuration already exists: $CONFIG_FILE. This initializer only creates a new repository/configuration; move the existing configuration aside or choose a separate XDG_CONFIG_HOME."
fi

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
[[ ! -e "$PASSPHRASE_FILE" ]] || die "Passphrase file already exists: $PASSPHRASE_FILE. Refusing to overwrite it."
[[ ! -e "$CONFIG_DIR/repository-key.txt" ]] || die "Recovery key file already exists. Refusing to overwrite it."

info "Choose directories to back up"
printf 'Enter one directory per prompt. Leave empty when finished.\n'
SOURCES=()
while true; do
    local_source=""
    prompt local_source "Source directory (empty to finish)"
    [[ -z "$local_source" ]] && break
    [[ -d "$local_source" ]] || { printf 'Not a directory: %s\n' "$local_source" >&2; continue; }
    resolved="$(realpath "$local_source")"
    duplicate=0
    for existing in "${SOURCES[@]}"; do
        [[ "$existing" == "$resolved" ]] && duplicate=1
    done
    if (( duplicate )); then printf 'Already selected: %s\n' "$resolved"; continue; fi
    SOURCES+=("$resolved")
    printf 'Added: %s\n' "$resolved"
done
(("${#SOURCES[@]}" > 0)) || die "At least one source directory is required."

info "Choose the repository destination"
printf '1) Local path on a mounted NAS/filesystem\n'
printf '2) Remote repository via SSH\n'
read -r -p "Destination type [1]: " destination_choice
destination_choice="${destination_choice:-1}"

MOUNTPOINT=""
case "$destination_choice" in
    1)
        REPOSITORY_TYPE="local"
        prompt BORG_REPO "Backup target directory (absolute path)" "/mnt/nas/data_encrypt/Borg-Backup"
        [[ "$BORG_REPO" == /* ]] || die "Repository path must be absolute."
        BORG_REPO="$(realpath -m "$BORG_REPO")"
        repo_parent="$(dirname "$BORG_REPO")"
        if [[ ! -d "$repo_parent" ]]; then
            confirm "Create parent directory $repo_parent?" || die "Setup cancelled."
            mkdir -p "$repo_parent" ||
                die "Cannot create directory $repo_parent. Check permissions and that the NAS is mounted."
        fi
        # Trigger automounts (for example autofs shares below /mnt/nas) and verify
        # writability with a real write probe. A plain -w test is unreliable on
        # autofs trigger directories.
        probe_file="$(mktemp "$repo_parent/.borg_write_test.XXXXXX" 2>/dev/null || true)"
        [[ -n "$probe_file" ]] || die "Target directory is not writable: $repo_parent"
        rm -f -- "$probe_file"
        # Resolve the real filesystem mount that backs the target. The deepest mount
        # is used, so nested mounts (for example autofs/CIFS shares below /mnt/nas)
        # are supported. A target on the local root filesystem is rejected.
        actual_mount="$(findmnt -f -T "$repo_parent" -n -o TARGET 2>/dev/null || true)"
        [[ -n "$actual_mount" && "$actual_mount" != "/" ]] ||
            die "$BORG_REPO is not on a mounted NAS/filesystem (found mount point: ${actual_mount:-none}). Mount the NAS first; no local fallback is allowed."
        MOUNTPOINT="$actual_mount"
        [[ ! -e "$BORG_REPO" ]] || die "Repository path already exists. Choose a new path or inspect it manually."
        ;;
    2)
        REPOSITORY_TYPE="ssh"
        prompt BORG_REPO "Borg SSH repository URL (ssh://user@host:port/path)"
        [[ "$BORG_REPO" =~ ^ssh://[^/]+/.+ ]] || die "Expected an ssh://user@host/path repository URL."
        printf 'The first SSH connection may ask you to verify the NAS host key.\n'
        printf 'Do not disable host-key checking; verify the fingerprint if prompted.\n'
        ;;
    *) die "Invalid destination choice." ;;
esac

info "Backup and retention settings"
default_prefix="$(hostname -s)-backup"
prompt ARCHIVE_PREFIX "Archive name prefix (letters, digits, dot, underscore, hyphen)" "$default_prefix"
[[ "$ARCHIVE_PREFIX" =~ ^[a-zA-Z0-9._-]+$ ]] || die "Invalid archive prefix."
prompt KEEP_DAILY "Daily archives to keep" "14"
prompt KEEP_WEEKLY "Weekly archives to keep" "8"
prompt KEEP_MONTHLY "Monthly archives to keep" "12"
for value in "$KEEP_DAILY" "$KEEP_WEEKLY" "$KEEP_MONTHLY"; do
    [[ "$value" =~ ^[0-9]+$ ]] || die "Retention values must be non-negative integers."
done
prompt COMPACT_AFTER_PRUNE "Run borg compact after pruning? (yes/no)" "yes"
case "$COMPACT_AFTER_PRUNE" in
    yes|y|Y) COMPACT_AFTER_PRUNE="yes" ;;
    no|n|N) COMPACT_AFTER_PRUNE="no" ;;
    *) die "Please answer yes or no." ;;
esac

info "Set repository passphrase"
printf 'Use a long, unique passphrase and store it in your password manager.\n'
read -r -s -p "Passphrase: " passphrase; printf '\n'
read -r -s -p "Repeat passphrase: " passphrase_confirm; printf '\n'
[[ -n "$passphrase" ]] || die "Passphrase must not be empty."
[[ "$passphrase" == "$passphrase_confirm" ]] || die "Passphrases do not match."
info "Review setup"
printf 'Repository type : %s\nRepository      : %s\n' "$REPOSITORY_TYPE" "$BORG_REPO"
[[ "$REPOSITORY_TYPE" != "local" ]] || printf 'Mount point     : %s\n' "$MOUNTPOINT"
printf 'Archive prefix  : %s\nSources:\n' "$ARCHIVE_PREFIX"
printf '  - %s\n' "${SOURCES[@]}"
printf 'Retention       : daily=%s weekly=%s monthly=%s\n' "$KEEP_DAILY" "$KEEP_WEEKLY" "$KEEP_MONTHLY"
printf 'Encryption      : %s\n' "$ENCRYPTION"
confirm "Initialize this new repository now?" || die "Setup cancelled."

umask 077
printf '%s\n' "$passphrase" > "$PASSPHRASE_FILE"
unset passphrase passphrase_confirm
chmod 600 "$PASSPHRASE_FILE"

export BORG_PASSPHRASE_FILE="$PASSPHRASE_FILE"
# Borg executes the passcommand without a shell, so expand the path here instead
# of relying on "$BORG_PASSPHRASE_FILE" being substituted at runtime.
printf -v BORG_PASSCOMMAND 'cat -- %q' "$PASSPHRASE_FILE"
export BORG_PASSCOMMAND
info "Initializing repository"
borg init --encryption="$ENCRYPTION" "$BORG_REPO"

write_config

info "Export recovery key"
key_file="$CONFIG_DIR/repository-key.txt"
umask 077
borg key export "$BORG_REPO" "$key_file"
chmod 600 "$key_file"

cat <<EOF

Setup completed.

Configuration : $CONFIG_FILE
Passphrase    : $PASSPHRASE_FILE
Recovery key  : $key_file

IMPORTANT:
- Store the passphrase in your password manager. The passphrase file is plain
  text and protected only by file permissions (0600/0700) and full-disk
  encryption. Keep it out of Git, cloud sync, and unencrypted home backups;
  for stronger protection, read it from a secret manager via BORG_PASSCOMMAND.
- Copy the recovery key to a separate, secure offline location. It is not needed
  for daily operation, so you can delete $key_file afterwards. While the
  repository is accessible, re-export it with: borg key export "$BORG_REPO" <file>
- Do not store the recovery key only on the NAS or in this Git repository.
- For repokey-blake2 the passphrase is the critical secret: without it, neither
  the recovery key nor the repository can be used.
- Test a restore before relying on this backup.

Start a backup with:
  ~/.local/bin/borg_backup.sh
EOF
