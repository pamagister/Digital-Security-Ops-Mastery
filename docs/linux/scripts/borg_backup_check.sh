#!/usr/bin/env bash
#
# Validate the configured Borg backup target and optionally check repository structure.
# Design target: Borg 1.x.

set -Eeuo pipefail
IFS=$'\n\t'

CONFIG_FILE="\${BORG_BACKUP_CONFIG:-\${XDG_CONFIG_HOME:-$HOME/.config}/borg-backup/config}"
DEEP_CHECK=0

usage() {
    printf 'Usage: %s [--repository-check] [--help]\n' "\${0##*/}"
    printf '  --repository-check  Also run borg check --repository-only (can take time).\n'
}
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

while (($#)); do
    case "$1" in
        --repository-check) DEEP_CHECK=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; die "Unknown option: $1" ;;
    esac
    shift
done

[[ -r "$CONFIG_FILE" ]] || die "Configuration not found: $CONFIG_FILE"
[[ "$(stat -c '%u' "$CONFIG_FILE")" == "$(id -u)" ]] || die "Configuration is not owned by the current user."
mode="$(stat -c '%a' "$CONFIG_FILE")"
(( (8#$mode & 077) == 0 )) || die "Configuration permissions are too broad (expected 600)."
# shellcheck source=/dev/null
source "$CONFIG_FILE"

: "\${REPOSITORY_TYPE:?Missing REPOSITORY_TYPE}"
: "\${BORG_REPO:?Missing BORG_REPO}"
: "\${PASSPHRASE_FILE:?Missing PASSPHRASE_FILE}"
[[ -f "$PASSPHRASE_FILE" && -r "$PASSPHRASE_FILE" ]] || die "Passphrase file missing or unreadable."
[[ "$(stat -c '%u' "$PASSPHRASE_FILE")" == "$(id -u)" ]] || die "Passphrase file is not owned by the current user."
mode="$(stat -c '%a' "$PASSPHRASE_FILE")"
(( (8#$mode & 077) == 0 )) || die "Passphrase file permissions are too broad (expected 600)."

command -v borg >/dev/null 2>&1 || die "Borg is not installed."
version="$(borg --version)"
[[ "$version" =~ ^borg[[:space:]]+1\. ]] || die "Borg 1.x is required; found: $version"

case "$REPOSITORY_TYPE" in
    local)
        : "\${MOUNTPOINT:?Missing MOUNTPOINT}"
        mountpoint -q "$MOUNTPOINT" || die "Mount is not active: $MOUNTPOINT"
        [[ -d "$BORG_REPO" && -r "$BORG_REPO" && -w "$BORG_REPO" ]] ||
            die "Repository directory is not accessible: $BORG_REPO"
        [[ "$(realpath "$BORG_REPO")" == "$(realpath "$MOUNTPOINT")/"* ]] ||
            die "Repository is not below the configured mount point."
        ;;
    ssh)
        [[ "$BORG_REPO" =~ ^ssh://[^/]+/.+ ]] || die "Invalid SSH repository URL."
        ;;
    *) die "Unknown repository type: $REPOSITORY_TYPE" ;;
esac

export BORG_PASSPHRASE_FILE="$PASSPHRASE_FILE"
export BORG_PASSCOMMAND='cat -- "$BORG_PASSPHRASE_FILE"'
printf 'Borg version : %s\nRepository   : %s\nType         : %s\n' "$version" "$BORG_REPO" "$REPOSITORY_TYPE"
printf '\nChecking repository access and authentication...\n'
borg info "$BORG_REPO"

if (( DEEP_CHECK )); then
    printf '\nChecking repository structure (repository-only)...\n'
    borg check --repository-only "$BORG_REPO"
fi

printf '\nAll requested checks passed.\n'
