#!/bin/sh
#
# NAS Connection Manager
#
# Features:
#   - Configure systemd automount via /etc/fstab
#   - Mount shares once without persistent configuration
#   - Unmount shares and remove automount configuration
#   - Secure SMB credentials
#   - Backup and atomic replacement of /etc/fstab
#
# Requirements:
#   - Ubuntu / Debian with systemd
#   - cifs-utils
#   - Root privileges
#
# Author: pamagister
# License: MIT

set -eu

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_NAME=$(basename "$0")

NAS_DEFAULT="nas.local"
MOUNT_BASE="/mnt/nas"
CREDENTIALS="/etc/samba/credentials_nas"
FSTAB="/etc/fstab"

SHARES_DEFAULT="book data music photo software video data_encrypt cloud"

FSTAB_BEGIN="# BEGIN NAS AUTOMOUNT CONFIGURATION (managed by ${SCRIPT_NAME})"
FSTAB_END="# END NAS AUTOMOUNT CONFIGURATION"

# UID/GID of the calling user (not root)
UID_VALUE=${SUDO_UID:-1000}
GID_VALUE=${SUDO_GID:-1000}

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

if [ -t 1 ]; then
    RED=$(printf '\033[0;31m')
    GREEN=$(printf '\033[0;32m')
    YELLOW=$(printf '\033[0;33m')
    BLUE=$(printf '\033[0;34m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[0m')
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
fi

info() {
    printf '%s[INFO]%s %s\n' "$BLUE" "$RESET" "$1"
}

success() {
    printf '%s[OK]%s %s\n' "$GREEN" "$RESET" "$1"
}

warning() {
    printf '%s[WARNING]%s %s\n' "$YELLOW" "$RESET" "$1"
}

error() {
    printf '%s[ERROR]%s %s\n' "$RED" "$RESET" "$1" >&2
}

die() {
    error "$1"
    exit 1
}

confirm() {
    printf '\n%s [y/N]: ' "$1"
    read -r answer

    case "$answer" in
        y|Y|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# System checks
# ---------------------------------------------------------------------------

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "Please run this script with sudo: sudo ./$SCRIPT_NAME"
    fi
}

check_dependencies() {
    if ! command -v apt-get >/dev/null 2>&1; then
        die "apt-get not found. Ubuntu/Debian is required."
    fi

    if ! dpkg -s cifs-utils >/dev/null 2>&1; then
        warning "cifs-utils is not installed."

        if confirm "Install cifs-utils now?"; then
            apt-get update
            apt-get install -y cifs-utils
        else
            die "cifs-utils is required."
        fi
    fi

    command -v mount.cifs >/dev/null 2>&1 ||
        die "mount.cifs not found. Please install cifs-utils."

    command -v systemctl >/dev/null 2>&1 ||
        die "systemctl not found. systemd is required."

    success "Dependencies are available."
}

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------

select_operation() {
    printf '\n'
    printf '%s========================================%s\n' "$BOLD" "$RESET"
    printf '%s       NAS CONNECTION MANAGER%s\n' "$BOLD" "$RESET"
    printf '%s========================================%s\n\n' "$BOLD" "$RESET"

    printf "1) Configure automount (default)\n"
    printf "2) Mount shares once (no automount)\n"
    printf "3) Unmount all and remove automount\n"
    printf "4) Exit\n\n"

    printf "Choice [1]: "
    read -r choice

    choice=${choice:-1}

    case "$choice" in
        1) OPERATION="automount" ;;
        2) OPERATION="once" ;;
        3) OPERATION="remove" ;;
        4) exit 0 ;;
        *) die "Invalid selection." ;;
    esac
}

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

get_configuration() {
    printf '\n'
    printf "NAS hostname or IP [%s]: " "$NAS_DEFAULT"
    read -r input
    NAS_HOST=${input:-$NAS_DEFAULT}

    printf "SMB username: "
    read -r SMB_USER

    [ -n "$SMB_USER" ] || die "Username must not be empty."

    printf "Shares [%s]: " "$SHARES_DEFAULT"
    read -r input
    SHARES_INPUT=${input:-$SHARES_DEFAULT}

    # Validate hostname and share names for fstab compatibility
    case "$NAS_HOST" in
        ""|*[!a-zA-Z0-9._:-]*)
            die "Invalid NAS hostname or IP address."
            ;;
    esac

    for share in $SHARES_INPUT; do
        case "$share" in
            ""|*[!a-zA-Z0-9._-]*)
                die "Invalid share name: $share"
                ;;
        esac
    done

    # Remove duplicate shares
    SHARES_INPUT=$(printf '%s\n' $SHARES_INPUT | sort -u | tr '\n' ' ')

    printf '\n'
    info "NAS host     : $NAS_HOST"
    info "SMB username : $SMB_USER"
    info "Shares       : $SHARES_INPUT"
    info "Mount base   : $MOUNT_BASE"
    info "Credentials  : $CREDENTIALS"
    info "UID / GID    : $UID_VALUE / $GID_VALUE"

    confirm "Proceed?" || die "Operation cancelled."
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

check_network() {
    printf '\n'
    info "Checking NAS connectivity..."

    if command -v getent >/dev/null 2>&1; then
        getent hosts "$NAS_HOST" >/dev/null 2>&1 ||
            die "Could not resolve NAS hostname: $NAS_HOST"
    fi

    if command -v nc >/dev/null 2>&1; then
        nc -z -w 3 "$NAS_HOST" 445 >/dev/null 2>&1 ||
            die "SMB port 445 is unreachable on $NAS_HOST."
    fi

    success "NAS hostname resolved."
}

# ---------------------------------------------------------------------------
# Credentials
# ---------------------------------------------------------------------------

setup_credentials() {
    printf '\n'

    if [ -f "$CREDENTIALS" ]; then
        if confirm "Credentials already exist. Update them?"; then
            cp -p "$CREDENTIALS" \
                "${CREDENTIALS}.backup.$(date +%Y%m%d%H%M%S)"
        else
            info "Using existing credentials."
            return 0
        fi
    fi

    printf "SMB password (input hidden): "

    # Restore terminal echo even if interrupted
    trap 'stty echo 2>/dev/null || true' EXIT HUP INT TERM

    stty -echo
    read -r SMB_PASSWORD
    stty echo

    trap - EXIT HUP INT TERM

    printf '\n'

    [ -n "$SMB_PASSWORD" ] || die "Password must not be empty."

    mkdir -p "$(dirname "$CREDENTIALS")"

    umask 077

    {
        printf 'username=%s\n' "$SMB_USER"
        printf 'password=%s\n' "$SMB_PASSWORD"
    } > "$CREDENTIALS"

    unset SMB_PASSWORD

    chown root:root "$CREDENTIALS"
    chmod 600 "$CREDENTIALS"

    success "Credentials stored securely."
}

# ---------------------------------------------------------------------------
# Mount points
# ---------------------------------------------------------------------------

create_mountpoints() {
    mkdir -p "$MOUNT_BASE"

    for share in $SHARES_INPUT; do
        mkdir -p "$MOUNT_BASE/$share"
    done
}

# ---------------------------------------------------------------------------
# CIFS mount options
# ---------------------------------------------------------------------------

MOUNT_OPTIONS="credentials=$CREDENTIALS,uid=$UID_VALUE,gid=$GID_VALUE,iocharset=utf8,file_mode=0664,dir_mode=0775"

# ---------------------------------------------------------------------------
# Mount shares once
# ---------------------------------------------------------------------------

mount_shares_once() {
    printf '\n'
    info "Mounting NAS shares for this session..."

    SUCCESS_COUNT=0
    FAILED_COUNT=0

    for share in $SHARES_INPUT; do
        TARGET="$MOUNT_BASE/$share"

        if mountpoint -q "$TARGET"; then
            warning "$share is already mounted. Skipping."
            continue
        fi

        if mount -t cifs "//$NAS_HOST/$share" "$TARGET" \
            -o "$MOUNT_OPTIONS"; then

            success "Mounted: $share"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            error "Failed to mount: $share"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    done

    printf '\n'
    info "Mount results: $SUCCESS_COUNT successful, $FAILED_COUNT failed."

    [ "$FAILED_COUNT" -eq 0 ] ||
        warning "Some shares could not be mounted."
}

# ---------------------------------------------------------------------------
# /etc/fstab
# ---------------------------------------------------------------------------

setup_fstab() {
    printf '\n'
    info "Updating $FSTAB..."

    [ -f "$FSTAB" ] || die "$FSTAB does not exist."

    # Backup
    cp -p "$FSTAB" "${FSTAB}.backup.$(date +%Y%m%d%H%M%S)"

    # Temporary file in the same filesystem
    TEMP_FILE=$(mktemp "${FSTAB}.tmp.XXXXXX")

    # Remove previous managed section
    awk -v begin="$FSTAB_BEGIN" -v end="$FSTAB_END" '
        $0 == begin {
            if (inside) exit 1
            inside = 1
            found_begin++
            next
        }

        $0 == end {
            if (!inside) exit 1
            inside = 0
            found_end++
            next
        }

        !inside { print }

        END {
            if (inside || found_begin != found_end || found_begin > 1)
                exit 1
        }
    ' "$FSTAB" > "$TEMP_FILE" ||
        die "Invalid NAS markers in fstab. Original file unchanged."

    # Append new NAS section
    {
        printf '\n%s\n' "$FSTAB_BEGIN"

        for share in $SHARES_INPUT; do
            printf '//%s/%s %s/%s cifs %s,_netdev,nofail,x-systemd.automount 0 0\n' \
                "$NAS_HOST" \
                "$share" \
                "$MOUNT_BASE" \
                "$share" \
                "$MOUNT_OPTIONS"
        done

        printf '%s\n' "$FSTAB_END"

    } >> "$TEMP_FILE" ||
        die "Could not write new fstab configuration."

    # Basic sanity check
    grep -F "$FSTAB_BEGIN" "$TEMP_FILE" >/dev/null ||
        die "NAS begin marker missing."

    grep -F "$FSTAB_END" "$TEMP_FILE" >/dev/null ||
        die "NAS end marker missing."

    # Set permissions and atomically replace fstab
    chown root:root "$TEMP_FILE"
    chmod 644 "$TEMP_FILE"

    mv -f "$TEMP_FILE" "$FSTAB"

    success "NAS configuration written to fstab."
}

# ---------------------------------------------------------------------------
# systemd automount
# ---------------------------------------------------------------------------

activate_automount() {
    printf '\n'
    info "Reloading systemd configuration..."

    systemctl daemon-reload

    for share in $SHARES_INPUT; do
        UNIT=$(systemd-escape --path --suffix=automount "$MOUNT_BASE/$share")

        systemctl start "$UNIT" ||
            warning "Could not start automount unit: $UNIT"
    done

    success "Automount configuration activated."
}

# ---------------------------------------------------------------------------
# Remove automount configuration and unmount shares
# ---------------------------------------------------------------------------

remove_automount_configuration() {
    printf '\n'
    warning "This will unmount NAS shares and remove their fstab configuration."

    confirm "Continue?" || die "Operation cancelled."

    # Stop automount units first
    for share in $SHARES_DEFAULT; do
        UNIT=$(systemd-escape --path --suffix=automount "$MOUNT_BASE/$share")

        systemctl stop "$UNIT" 2>/dev/null || true
    done

    # Unmount configured shares
    for share in $SHARES_DEFAULT; do
        TARGET="$MOUNT_BASE/$share"
        UNIT=$(systemd-escape --path --suffix=mount "$TARGET")

        if mountpoint -q "$TARGET"; then
            info "Unmounting $TARGET"

            if ! umount "$TARGET"; then
                die "Unmount failed: $TARGET. Close programs using this mount and retry."
            fi
        fi

        systemctl stop "$UNIT" 2>/dev/null || true
    done

    # Remove managed fstab section
    if grep -F "$FSTAB_BEGIN" "$FSTAB" >/dev/null 2>&1; then
        cp -p "$FSTAB" "${FSTAB}.backup.$(date +%Y%m%d%H%M%S)"

        TEMP_FILE=$(mktemp "${FSTAB}.tmp.XXXXXX")

        awk -v begin="$FSTAB_BEGIN" -v end="$FSTAB_END" '
            $0 == begin {
                if (inside) exit 1
                inside = 1
                found_begin++
                next
            }

            $0 == end {
                if (!inside) exit 1
                inside = 0
                found_end++
                next
            }

            !inside { print }

            END {
                if (inside || found_begin != found_end || found_begin > 1)
                    exit 1
            }
        ' "$FSTAB" > "$TEMP_FILE" ||
            die "Invalid NAS markers. fstab was not changed."

        chown root:root "$TEMP_FILE"
        chmod 644 "$TEMP_FILE"

        mv -f "$TEMP_FILE" "$FSTAB"

        systemctl daemon-reload

        success "NAS configuration removed from fstab."
    else
        info "No NAS automount configuration found in fstab."
    fi

    success "NAS cleanup completed."
    info "Credentials were preserved: $CREDENTIALS"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

show_summary() {
    printf '\n'
    printf '%s========================================%s\n' "$BOLD" "$RESET"
    printf '%s          OPERATION COMPLETED%s\n' "$BOLD" "$RESET"
    printf '%s========================================%s\n\n' "$BOLD" "$RESET"

    info "NAS host: $NAS_HOST"

    for share in $SHARES_INPUT; do
        printf '  %-20s -> %s/%s\n' \
            "$share" "$MOUNT_BASE" "$share"
    done

    printf '\n'
    info "Credentials: $CREDENTIALS"
    info "Check active CIFS mounts with: findmnt -t cifs"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    check_root
    select_operation

    case "$OPERATION" in

        automount)
            check_dependencies
            get_configuration
            check_network
            setup_credentials
            create_mountpoints
            setup_fstab
            activate_automount
            show_summary
            ;;

        once)
            check_dependencies
            get_configuration
            check_network
            setup_credentials
            create_mountpoints
            mount_shares_once
            show_summary
            ;;

        remove)
            remove_automount_configuration
            ;;

    esac
}

main "$@"