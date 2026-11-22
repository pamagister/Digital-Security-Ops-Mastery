#!/usr/bin/env bash
#
# Create an incremental Borg backup of a source directory into a Borg repository.
#
# The repository is expected to be mounted already (for example a NAS share
# under /mnt/nas). Borg stores only changed blocks, so every run creates a new
# archive while reusing unchanged data.
#
# Usage:
#   ./borg_backup.sh [SOURCE_DIR]
#   ./borg_backup.sh --init [SOURCE_DIR]
#
# Environment variables:
#   BORG_REPO              Repository path or URL. Default: /mnt/nas/data_encrypt/Borg-Backup
#   BORG_ARCHIVE_PREFIX    Archive name prefix. Default: <hostname>-documents
#   BORG_KEEP_DAILY        Daily archives to keep. Default: 7
#   BORG_KEEP_WEEKLY       Weekly archives to keep. Default: 4
#   BORG_KEEP_MONTHLY      Monthly archives to keep. Default: 6
#   BORG_PASSPHRASE        Repository passphrase (preferred for scripts).
#   BORG_PASSCOMMAND       Command that prints the passphrase (alternative).
#
# If neither BORG_PASSPHRASE nor BORG_PASSCOMMAND is set, the passphrase is
# requested interactively and kept only for this run.
#
# Examples:
#   ./borg_backup.sh ~/Documents
#   BORG_REPO=/mnt/backup/borg ./borg_backup.sh ~/Documents --init

set -Eeuo pipefail

PROGNAME="${0##*/}"
BORG_REPO="${BORG_REPO:-/mnt/nas/data_encrypt/Borg-Backup}"
BORG_ARCHIVE_PREFIX="${BORG_ARCHIVE_PREFIX:-$(hostname)-documents}"
BORG_KEEP_DAILY="${BORG_KEEP_DAILY:-7}"
BORG_KEEP_WEEKLY="${BORG_KEEP_WEEKLY:-4}"
BORG_KEEP_MONTHLY="${BORG_KEEP_MONTHLY:-6}"
ENCRYPTION="repokey-blake2"

usage() {
    cat <<EOF
Usage: $PROGNAME [--init] [SOURCE_DIR]

Create an incremental Borg backup of SOURCE_DIR in a Borg repository.

Arguments:
  --init        Initialize the repository before the first backup.
  SOURCE_DIR    Directory to back up. Default: \$HOME/Documents

Environment:
  BORG_REPO             Repository path. Default: $BORG_REPO
  BORG_ARCHIVE_PREFIX   Archive prefix. Default: $BORG_ARCHIVE_PREFIX
  BORG_KEEP_DAILY/WEEKLY/MONTHLY
                        Retention after a successful backup.
  BORG_PASSPHRASE       Repository passphrase.
  BORG_PASSCOMMAND      Command that prints the passphrase.

Notes:
  - The repository must be mounted and writable.
  - Borg encrypts and authenticates the repository content.
  - Export the repository key (borg key export) and keep it offline.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

INIT=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --init)
            INIT=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            usage >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

SOURCE_DIR="${1:-$HOME/Documents}"

command -v borg >/dev/null 2>&1 || die "borg is required. Install it with: sudo apt install borgbackup"

[[ -d "$SOURCE_DIR" ]] || die "Source directory does not exist: $SOURCE_DIR"
SOURCE_DIR="$(realpath "$SOURCE_DIR")"

[[ -d "$BORG_REPO" ]] || die "Repository directory does not exist (is the NAS mounted?): $BORG_REPO"
[[ -w "$BORG_REPO" ]] || die "Repository directory is not writable: $BORG_REPO"

if [[ -z "${BORG_PASSPHRASE:-}" && -z "${BORG_PASSCOMMAND:-}" ]]; then
    read -r -s -p "Repository passphrase: " BORG_PASSPHRASE
    printf '\n'
    export BORG_PASSPHRASE
fi

if (( INIT )); then
    if [[ -n "$(find "$BORG_REPO" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
        die "Repository directory is not empty, refusing to initialize: $BORG_REPO"
    fi
    printf 'Initializing Borg repository: %s\n' "$BORG_REPO"
    borg init --encryption="$ENCRYPTION" "$BORG_REPO"
fi

ARCHIVE="${BORG_ARCHIVE_PREFIX}-$(date +%Y-%m-%dT%H%M%S)"

printf 'Creating archive %s from %s\n' "$ARCHIVE" "$SOURCE_DIR"

borg create \
    --stats \
    --show-rc \
    --compression lz4 \
    --exclude-caches \
    "$BORG_REPO::$ARCHIVE" \
    "$SOURCE_DIR"

printf 'Applying retention policy (daily=%s, weekly=%s, monthly=%s)\n' \
    "$BORG_KEEP_DAILY" "$BORG_KEEP_WEEKLY" "$BORG_KEEP_MONTHLY"

borg prune \
    --list \
    --show-rc \
    --keep-daily="$BORG_KEEP_DAILY" \
    --keep-weekly="$BORG_KEEP_WEEKLY" \
    --keep-monthly="$BORG_KEEP_MONTHLY" \
    "$BORG_REPO"

printf 'Backup finished. Verify with:\n  borg check %s\n' "$BORG_REPO"