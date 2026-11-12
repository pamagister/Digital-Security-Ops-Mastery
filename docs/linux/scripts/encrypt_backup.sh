#!/usr/bin/env bash
#
# Create a password-protected tar.gz backup of a directory.
#
# The passphrase is written to a temporary file with restrictive permissions
# and removed on exit. It is never passed on the command line, where other
# users could read it from the process list.
#
# Usage:
#   ./encrypt_backup.sh [SOURCE_DIR] [OUTPUT_FILE]
#
# Restore:
#   openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -salt \
#     -pass stdin -in BACKUP.tar.gz.enc | tar -xzf -

set -Eeuo pipefail

PROGNAME="${0##*/}"
ITERATIONS=600000

usage() {
    cat <<EOF
Usage: $PROGNAME [SOURCE_DIR] [OUTPUT_FILE]

Create a password-protected tar.gz backup of SOURCE_DIR.

Arguments:
  SOURCE_DIR   Directory to back up. Default: current directory.
  OUTPUT_FILE  Encrypted output file.
               Default: ./<source-name>_backup_<timestamp>.tar.gz.enc

Requirements:
  tar, openssl

Security notes:
  - Use a long, unique passphrase and store it in a password manager.
  - The encrypted file is only as safe as the passphrase.
  - Removing the backup file does not securely erase it from all storage media.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

if [[ $# -gt 2 ]]; then
    usage >&2
    exit 2
fi

SOURCE_DIR="${1:-$PWD}"
OUTPUT_FILE="${2:-}"

command -v tar >/dev/null 2>&1 || die "tar is required."
command -v openssl >/dev/null 2>&1 || die "openssl is required."

[[ -d "$SOURCE_DIR" ]] || die "Source directory does not exist: $SOURCE_DIR"
SOURCE_DIR="$(realpath "$SOURCE_DIR")"
SOURCE_NAME="$(basename "$SOURCE_DIR")"

if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="$PWD/${SOURCE_NAME}_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz.enc"
fi

[[ -e "$OUTPUT_FILE" ]] && die "Output file already exists: $OUTPUT_FILE"
mkdir -p "$(dirname "$OUTPUT_FILE")" || die "Cannot create output directory."

read -r -s -p "Enter backup passphrase: " PASSWORD
printf '\n'
read -r -s -p "Confirm passphrase: " PASSWORD_CONFIRM
printf '\n'

[[ -n "$PASSWORD" ]] || die "Passphrase must not be empty."
[[ "$PASSWORD" == "$PASSWORD_CONFIRM" ]] || die "Passphrases do not match."

if (( ${#PASSWORD} < 12 )); then
    printf 'Warning: the passphrase is shorter than 12 characters.\n' >&2
fi

umask 077
PASS_FILE="$(mktemp "${TMPDIR:-/tmp}/${PROGNAME}.XXXXXX")"
trap 'rm -f "$PASS_FILE"' EXIT

printf '%s\n' "$PASSWORD" > "$PASS_FILE"

if ! tar -czf - -C "$(dirname "$SOURCE_DIR")" "$SOURCE_NAME" \
    | openssl enc -aes-256-cbc -pbkdf2 -iter "$ITERATIONS" -salt \
        -pass "file:$PASS_FILE" -out "$OUTPUT_FILE"; then
    rm -f "$OUTPUT_FILE"
    die "Backup failed."
fi

printf 'Encrypted backup created: %s\n' "$OUTPUT_FILE"
printf 'Store the passphrase separately and test the restore before relying on it.\n'
