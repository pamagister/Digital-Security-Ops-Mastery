#!/bin/sh
#
# NAS Share Setup for Linux (Ubuntu/Debian with systemd)
#
# Features:
#   - Interactive configuration
#   - Secure, centralized SMB credentials
#   - CIFS mounts via /etc/fstab
#   - systemd automount enabled by default
#   - Network and dependency checks
#   - Backup of configuration files
#   - Validation and error handling
#
# Requirements:
#   - systemd
#   - cifs-utils
#   - root privileges
#
# Author: pamagister
# License: MIT
#

set -eu

# ---------------------------------------------------------------------------
# Configuration defaults
# ---------------------------------------------------------------------------

SCRIPT_NAME=$(basename "$0")

DEFAULT_MOUNT_BASE="/mnt/nas"
DEFAULT_CREDENTIALS="/etc/samba/credentials_nas"

DEFAULT_SHARES='book data music photo software video data_encrypt cloud'

FSTAB_FILE="/etc/fstab"

FSTAB_BEGIN="# BEGIN NAS AUTOMOUNT CONFIGURATION (managed by ${SCRIPT_NAME})"
FSTAB_END="# END NAS AUTOMOUNT CONFIGURATION"

# ---------------------------------------------------------------------------
# Colors
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

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

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

ask() {
    printf '%s' "$1"
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

confirm() {
    printf '\n%s [y/N]: ' "$1"
    read -r answer

    case "$answer" in
        y|Y|yes|YES|Yes)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

backup_file() {
    file="$1"

    if [ -f "$file" ]; then
        backup="${file}.backup.$(date +%Y%m%d%H%M%S)"

        cp -p "$file" "$backup" ||
            die "Failed to create backup of $file"

        success "Backup created: $backup"
    fi
}

# ---------------------------------------------------------------------------
# Initial checks
# ---------------------------------------------------------------------------

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "Please run this script with sudo: sudo ./$SCRIPT_NAME"
    fi

    success "Running with root privileges."
}

check_system() {
    if ! check_command systemctl; then
        die "systemctl not found. This script requires systemd."
    fi

    if ! check_command mount; then
        die "mount command not found."
    fi

    if ! check_command mount.cifs; then
        die "mount.cifs not found. Please install cifs-utils."
    fi

    success "Required system components are available."
}

install_dependencies() {
    if check_command apt-get; then
        if ! dpkg -s cifs-utils >/dev/null 2>&1; then
            warning "The package cifs-utils is not installed."

            if confirm "Install cifs-utils now?"; then
                apt-get update
                apt-get install -y cifs-utils ||
                    die "Failed to install cifs-utils."
            else
                die "cifs-utils is required. Installation cancelled."
            fi
        fi
    else
        warning "Could not detect apt-get. Please ensure cifs-utils is installed."
    fi

    success "CIFS utilities are installed."
}

# ---------------------------------------------------------------------------
# Interactive configuration
# ---------------------------------------------------------------------------

get_configuration() {
    printf '\n'
    printf '%s========================================%s\n' "$BOLD" "$RESET"
    printf '%s       NAS SHARE CONFIGURATION%s\n' "$BOLD" "$RESET"
    printf '%s========================================%s\n\n' "$BOLD" "$RESET"

    # NAS hostname or IP
    while :; do
        ask "NAS hostname or IP address [nas4ever.local]: "
        read -r NAS_HOST

        NAS_HOST=${NAS_HOST:-nas4ever.local}

        case "$NAS_HOST" in
            *[!a-zA-Z0-9._:-]*)
                warning "Invalid hostname/IP format. Please try again."
                ;;
            *)
                break
                ;;
        esac
    done

    # SMB username
    while :; do
        ask "SMB username: "
        read -r SMB_USER

        if [ -n "$SMB_USER" ]; then
            break
        fi

        warning "Username must not be empty."
    done

    # SMB password (hidden)
    while :; do
        printf "SMB password (input hidden): "
        stty -echo
        read -r SMB_PASSWORD
        stty echo
        printf '\n'

        if [ -n "$SMB_PASSWORD" ]; then
            break
        fi

        warning "Password must not be empty."
    done

    # Shares
    printf '\n'
    info "Enter the share names separated by spaces."
    info "Example: documents media backup"
    ask "Shares [$DEFAULT_SHARES]: "
    read -r SHARES_INPUT

    SHARES_INPUT=${SHARES_INPUT:-$DEFAULT_SHARES}

    # Mount base
    ask "Mount base directory [$DEFAULT_MOUNT_BASE]: "
    read -r MOUNT_BASE_INPUT

    MOUNT_BASE=${MOUNT_BASE_INPUT:-$DEFAULT_MOUNT_BASE}

    # Credentials path
    ask "Credentials file [$DEFAULT_CREDENTIALS]: "
    read -r CREDENTIALS_INPUT

    CREDENTIALS=${CREDENTIALS_INPUT:-$DEFAULT_CREDENTIALS}

    # User ID / Group ID
    SUDO_USER_NAME=${SUDO_USER:-}

    if [ -n "$SUDO_USER_NAME" ] &&
       id "$SUDO_USER_NAME" >/dev/null 2>&1; then

        USER_UID=$(id -u "$SUDO_USER_NAME")
        USER_GID=$(id -g "$SUDO_USER_NAME")
    else
        USER_UID=1000
        USER_GID=1000
    fi

    printf '\n'
    info "Configuration summary:"
    printf '  NAS host       : %s\n' "$NAS_HOST"
    printf '  SMB username   : %s\n' "$SMB_USER"
    printf '  Shares         : %s\n' "$SHARES_INPUT"
    printf '  Mount base     : %s\n' "$MOUNT_BASE"
    printf '  Credentials    : %s\n' "$CREDENTIALS"
    printf '  UID / GID      : %s / %s\n' "$USER_UID" "$USER_GID"
    printf '  Automount      : enabled\n'
    printf '\n'

    confirm "Proceed with this configuration?" ||
        die "Configuration cancelled."
}

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

validate_configuration() {
    case "$MOUNT_BASE" in
        /*)
            ;;
        *)
            die "Mount base must be an absolute path."
            ;;
    esac

    case "$CREDENTIALS" in
        /*)
            ;;
        *)
            die "Credentials path must be an absolute path."
            ;;
    esac

    # Prevent accidental use of whitespace or special characters
    # in share names that would break /etc/fstab.
    for share in $SHARES_INPUT; do
        case "$share" in
            ""|*[!a-zA-Z0-9._-]*)
                die "Invalid share name: $share"
                ;;
        *)
            ;;
        esac
    done

    # Avoid duplicate share names
    unique_shares=$(printf '%s\n' $SHARES_INPUT | sort -u)

    SHARE_COUNT=$(printf '%s\n' $SHARES_INPUT | wc -l)
    UNIQUE_COUNT=$(printf '%s\n' "$unique_shares" | wc -l)

    if [ "$SHARE_COUNT" -ne "$UNIQUE_COUNT" ]; then
        warning "Duplicate share names detected. Duplicates will be removed."
        SHARES_INPUT=$unique_shares
    fi

    success "Configuration validation completed."
}

# ---------------------------------------------------------------------------
# Network checks
# ---------------------------------------------------------------------------

check_network() {
    printf '\n'
    info "Checking network connectivity to $NAS_HOST ..."

    if check_command ping; then
        if ping -c 1 -W 3 "$NAS_HOST" >/dev/null 2>&1; then
            success "NAS responds to ping."
        else
            warning "NAS does not respond to ping."
            warning "Some NAS devices block ICMP. Continuing with SMB checks."
        fi
    else
        warning "ping is not installed. Skipping ICMP check."
    fi

    # Check DNS resolution when a hostname was provided
    case "$NAS_HOST" in
        *[!0-9.]*)
            if check_command getent; then
                if getent hosts "$NAS_HOST" >/dev/null 2>&1; then
                    success "Hostname resolution successful."
                else
                    die "Could not resolve NAS hostname: $NAS_HOST"
                fi
            else
                warning "getent not found. Skipping hostname resolution check."
            fi
            ;;
        *)
            info "NAS address appears to be an IPv4 address."
            ;;
    esac

    # Check SMB TCP port
    if check_command nc; then
        if nc -z -w 3 "$NAS_HOST" 445 >/dev/null 2>&1; then
            success "SMB TCP port 445 is reachable."
        else
            die "SMB port 445 is unreachable on $NAS_HOST."
        fi
    elif check_command timeout; then
        warning "nc not found. Skipping TCP port check."
    else
        warning "Neither nc nor timeout is available. Skipping TCP port check."
    fi
}

# ---------------------------------------------------------------------------
# Credentials
# ---------------------------------------------------------------------------

setup_credentials() {
    printf '\n'
    info "Setting up SMB credentials ..."

    credentials_dir=$(dirname "$CREDENTIALS")

    mkdir -p "$credentials_dir" ||
        die "Could not create credentials directory."

    backup_file "$CREDENTIALS"

    # Write credentials without exposing password in command arguments
    umask 077

    {
        printf 'username=%s\n' "$SMB_USER"
        printf 'password=%s\n' "$SMB_PASSWORD"
    } > "$CREDENTIALS" ||
        die "Failed to write credentials file."

    unset SMB_PASSWORD

    chown root:root "$CREDENTIALS" ||
        die "Failed to set credentials ownership."

    chmod 600 "$CREDENTIALS" ||
        die "Failed to set credentials permissions."

    if [ "$(stat -c '%a' "$CREDENTIALS")" != "600" ]; then
        die "Credentials file permissions are not 600."
    fi

    success "Credentials stored securely in $CREDENTIALS."
}

# ---------------------------------------------------------------------------
# Mount point preparation
# ---------------------------------------------------------------------------

setup_mountpoints() {
    printf '\n'
    info "Creating mount directories ..."

    mkdir -p "$MOUNT_BASE" ||
        die "Could not create mount base directory."

    for share in $SHARES_INPUT; do
        mountpoint="$MOUNT_BASE/$share"

        mkdir -p "$mountpoint" ||
            die "Could not create mount point: $mountpoint"

        success "Mount point ready: $mountpoint"
    done
}

# ---------------------------------------------------------------------------
# /etc/fstab management
# ---------------------------------------------------------------------------

setup_fstab() {
    printf '\n'
    info "Updating $FSTAB_FILE ..."

    [ -f "$FSTAB_FILE" ] ||
        die "$FSTAB_FILE does not exist."

    # Create a backup before making any changes.
    backup_file "$FSTAB_FILE"

    # Create the temporary file in /etc to ensure atomic replacement.
    TEMP_FILE=$(mktemp "${FSTAB_FILE}.tmp.XXXXXX") ||
        die "Could not create temporary fstab file."

    # Remove the previously managed NAS section.
    # Detect incomplete or duplicated configuration markers.
    if ! awk \
        -v begin="$FSTAB_BEGIN" \
        -v end="$FSTAB_END" '
        BEGIN {
            skip = 0
            bad = 0
            seen_begin = 0
            seen_end = 0
        }

        $0 == begin {
            if (skip || seen_begin) {
                bad = 1
                exit
            }

            skip = 1
            seen_begin = 1
            next
        }

        $0 == end {
            if (!skip || seen_end) {
                bad = 1
                exit
            }

            skip = 0
            seen_end = 1
            next
        }

        !skip {
            print
        }

        END {
            if (skip || seen_begin != seen_end) {
                bad = 1
            }

            if (bad) {
                exit 2
            }
        }
        ' "$FSTAB_FILE" > "$TEMP_FILE"; then

        rm -f "$TEMP_FILE"
        die "Existing NAS configuration markers are invalid."
    fi

    # Append the new NAS configuration.
    {
        printf '\n'
        printf '%s\n' "$FSTAB_BEGIN"
        printf '%s\n' "# NAS host: $NAS_HOST"
        printf '%s\n' "# SMB automount entries"

        for share in $SHARES_INPUT; do
            printf '//%s/%s %s/%s cifs credentials=%s,uid=%s,gid=%s,iocharset=utf8,file_mode=0664,dir_mode=0775,_netdev,nofail,x-systemd.automount 0 0\n' \
                "$NAS_HOST" \
                "$share" \
                "$MOUNT_BASE" \
                "$share" \
                "$CREDENTIALS" \
                "$USER_UID" \
                "$USER_GID"
        done

        printf '%s\n' "$FSTAB_END"

    } >> "$TEMP_FILE" || {
        rm -f "$TEMP_FILE"
        die "Failed to write NAS configuration."
    }

    # Count expected shares.
    EXPECTED_COUNT=$(printf '%s\n' $SHARES_INPUT | wc -l)

    # Validate the generated NAS section.
    if ! awk \
        -v begin="$FSTAB_BEGIN" \
        -v end="$FSTAB_END" \
        -v expected="$EXPECTED_COUNT" '
        BEGIN {
            inside = 0
            count = 0
            bad = 0
            seen_begin = 0
            seen_end = 0
        }

        $0 == begin {
            if (inside || seen_begin) {
                bad = 1
                exit
            }

            inside = 1
            seen_begin = 1
            next
        }

        $0 == end {
            if (!inside || seen_end) {
                bad = 1
                exit
            }

            inside = 0
            seen_end = 1
            next
        }

        inside && $0 !~ /^#/ && NF > 0 {
            if (NF != 6 || $3 != "cifs") {
                bad = 1
            }

            count++
        }

        END {
            if (inside || !seen_begin || !seen_end) {
                bad = 1
            }

            if (count != expected) {
                bad = 1
            }

            if (bad) {
                exit 1
            }
        }
        ' "$TEMP_FILE"; then

        rm -f "$TEMP_FILE"
        die "NAS fstab validation failed. Original fstab remains unchanged."
    fi

    success "NAS configuration validated successfully."

    # Set correct ownership and permissions.
    chown root:root "$TEMP_FILE" ||
        die "Could not set temporary fstab ownership."

    chmod 644 "$TEMP_FILE" ||
        die "Could not set temporary fstab permissions."

    # Atomically replace the original fstab.
    mv -f "$TEMP_FILE" "$FSTAB_FILE" ||
        die "Failed to install new fstab."

    # Verify that the new configuration is present.
    if ! grep -F "$FSTAB_BEGIN" "$FSTAB_FILE" >/dev/null; then
        die "NAS configuration marker missing after installation."
    fi

    if ! grep -F "$FSTAB_END" "$FSTAB_FILE" >/dev/null; then
        die "NAS configuration end marker missing after installation."
    fi

    success "NAS entries successfully written to $FSTAB_FILE."
}

# ---------------------------------------------------------------------------
# systemd automount activation
# ---------------------------------------------------------------------------

activate_automount() {
    printf '\n'
    info "Reloading systemd configuration ..."

    systemctl daemon-reload ||
        die "systemd daemon-reload failed."

    systemctl reset-failed ||
        warning "Could not reset failed systemd units."

    for share in $SHARES_INPUT; do
        unit_name=$(systemd-escape --path --suffix=automount "$MOUNT_BASE/$share")

        info "Starting automount: $unit_name"

        if ! systemctl start "$unit_name"; then
            warning "Failed to start $unit_name."
            warning "Checking whether systemd generated the unit ..."

            if ! systemctl status "$unit_name" --no-pager; then
                die "Automount unit unavailable: $unit_name"
            fi
        fi

        success "Automount started: $MOUNT_BASE/$share"
    done

    # Verify that all automount units are active.
    for share in $SHARES_INPUT; do
        unit_name=$(systemd-escape --path --suffix=automount "$MOUNT_BASE/$share")

        if ! systemctl is-active --quiet "$unit_name"; then
            die "Automount unit is not active: $unit_name"
        fi
    done

    success "All NAS automount units are active."
}

# ---------------------------------------------------------------------------
# Optional SMB authentication test
# ---------------------------------------------------------------------------

test_smb_authentication() {
    printf '\n'

    if ! check_command smbclient; then
        warning "smbclient is not installed. Skipping authentication test."
        return 0
    fi

    if confirm "Test SMB authentication using smbclient?"; then
        info "Testing SMB authentication ..."

        if smbclient -L "//$NAS_HOST" \
            -A "$CREDENTIALS" \
            >/dev/null 2>&1; then

            success "SMB authentication successful."
        else
            warning "SMB authentication test failed."
            warning "Automount configuration is installed, but credentials may need checking."
        fi
    fi
}

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------

show_summary() {
    printf '\n'
    printf '%s========================================%s\n' "$BOLD" "$RESET"
    printf '%s          SETUP COMPLETED%s\n' "$BOLD" "$RESET"
    printf '%s========================================%s\n\n' "$BOLD" "$RESET"

    success "NAS automount configuration installed."
    info "Run 'sudo systemctl daemon-reload' if you do not yet see the automount units."

    printf '\nConfigured shares:\n'

    for share in $SHARES_INPUT; do
        printf '  %-20s -> %s/%s\n' \
            "$share" "$MOUNT_BASE" "$share"
    done

    printf '\n'
    info "Automount is enabled. Shares are mounted on first access."
    info "To test a share, run:"
    printf '\n  ls -la %s/<share>\n' "$MOUNT_BASE"

    printf '\n'
    info "To check mounted shares:"
    printf '\n  findmnt -t cifs\n'

    printf '\n'
    info "To inspect a systemd mount unit:"
    printf '\n  systemctl status %s/<share>.mount\n' "$MOUNT_BASE"

    printf '\n'
    info "Credentials are stored in:"
    printf '\n  %s\n' "$CREDENTIALS"

    printf '\n'
    warning "Keep the credentials file private. Do not upload it to Git."
    printf '\n'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    check_root
    check_system
    install_dependencies

    get_configuration
    validate_configuration

    check_network

    setup_credentials
    setup_mountpoints
    setup_fstab
    activate_automount

    test_smb_authentication
    show_summary
}

main "$@"