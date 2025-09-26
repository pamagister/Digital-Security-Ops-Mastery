#!/usr/bin/env bash
# sync_docs_unison.sh
# Bidirectional sync between local gocryptfs container and NAS via Unison.
# - Prefers password from /etc/samba/credentials_sync_docs
# - Auto-initializes gocryptfs if needed (tries password from CRED_FILE)
# - Mount, run unison between LOCAL_ENCRYPTED and NAS_TARGET, unmount
# - Optional: --restore (restore decrypted files into LOCAL_DOCS)
# - Optional: --reset (reset current mounts, does not affect LOCAL_DOCS)
# - Optional: --init-backup (initial backup when NAS is empty)
#
# IMPORTANT: This script NEVER deletes files in LOCAL_DOCS without asking.
#           Unison handles conflicts interactively (asks the user).

# Make script executable: chmod +x ~/sync_docs_unison.sh
# Run script, e.g.: ./sync_docs_unison.sh --restore

# === Credential File Setup ===
# 1. Create credentials file:
# sudo nano /etc/samba/credentials_sync_docs
# 2. Content (just the password):
# YOUR_PASSWORD_HERE
# 3. Secure permissions:
# sudo chmod 600 /etc/samba/credentials_sync_docs

# Manual recovery:
# 1. Set NAS target:
# NAS_TARGET="/mnt/nas/data/Backups/encrypted_documents"
# 2. Prepare mountpoint:
# mkdir -p tmp/nas_decrypted
# 3. Start gocryptfs directly (with password prompt, read-only for safety):
# gocryptfs -ro "$NAS_TARGET" tmp/nas_decrypted
# 4. Unmount when done:
# fusermount -u tmp/nas_decrypted

set -euo pipefail

# ============================
# Configuration Variables
# ============================

# Determine real user home directory (handle sudo cases)
if [[ -n "${SUDO_USER:-}" ]]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

# Path configuration
LOCAL_DOCS="$USER_HOME/Documents/"                           # Local directory to backup
LOCAL_ENCRYPTED="$USER_HOME/.encrypted_docs"                 # gocryptfs encrypted mount
LOCAL_DECRYPTED="$USER_HOME/.decrypted_docs"                 # gocryptfs decrypted mount
NAS_TARGET="/mnt/nas/data/Backups/encrypted_docs_backup"     # Backup folder on NAS
CRED_FILE="/etc/samba/credentials_sync_docs"                 # Password file

# Logging configuration
LOGDIR="/tmp/log/sync_docs_unison"
LOGFILE="${LOGDIR}/sync_$(date +%F_%H%M%S).log"
TMP_EXTPASS_SCRIPT="/tmp/gocryptfs_extpass_$$.sh"
UNISON_PROFILE="/tmp/unison_sync_profile_$$.prf"

# Script state
CLEANUP_PERFORMED=false

# ============================
# Utility Functions
# ============================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOGFILE" >&2
}

fatal() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] FATAL: $*" | tee -a "$LOGFILE" >&2
    cleanup_temp
    exit 1
}

cleanup_temp() {
    if [[ "$CLEANUP_PERFORMED" == "true" ]]; then
        return 0
    fi

    # Secure deletion of temporary scripts
    if [[ -f "$TMP_EXTPASS_SCRIPT" ]]; then
        shred -u "$TMP_EXTPASS_SCRIPT" 2>/dev/null || rm -f "$TMP_EXTPASS_SCRIPT"
    fi
    if [[ -f "$UNISON_PROFILE" ]]; then
        rm -f "$UNISON_PROFILE"
    fi

    CLEANUP_PERFORMED=true
}

read_password_from_credfile() {
    # Returns password on stdout if found and readable, otherwise fails
    if sudo test -r "$CRED_FILE" 2>/dev/null; then
        local pw
        pw=$(sudo grep -m1 -E '^[^#[:space:]]' "$CRED_FILE" 2>/dev/null | sed -E 's/^password=//' | tr -d '\r\n')
        if [[ -n "$pw" ]]; then
            echo "$pw"
            return 0
        fi
    fi
    return 1
}

make_extpass_script() {
    # Creates a script that outputs the password for gocryptfs -extpass
    local pw="$1"
    cat > "$TMP_EXTPASS_SCRIPT" <<EOF
#!/bin/bash
echo "$pw"
EOF
    chmod 700 "$TMP_EXTPASS_SCRIPT"
}

check_programs() {
    local missing=()
    local required_programs=("gocryptfs" "unison" "rsync" "fusermount")

    for prog in "${required_programs[@]}"; do
        if ! command -v "$prog" >/dev/null 2>&1; then
            missing+=("$prog")
        fi
    done

    if [[ ${#missing[@]} -ne 0 ]]; then
        fatal "Required programs missing: ${missing[*]}. Please install them."
    fi
}

check_directories() {
    # Create necessary directories
    mkdir -p "$LOCAL_DOCS" "$LOCAL_ENCRYPTED" "$LOCAL_DECRYPTED"

    # Check if LOCAL_DOCS is accessible
    if [[ ! -d "$LOCAL_DOCS" ]] || [[ ! -r "$LOCAL_DOCS" ]]; then
        fatal "LOCAL_DOCS directory $LOCAL_DOCS is not accessible"
    fi
}

gocryptfs_is_initialized() {
    [[ -f "${LOCAL_ENCRYPTED}/gocryptfs.conf" ]]
}

is_mounted() {
    local mountpoint="$1"
    mountpoint -q "$mountpoint" 2>/dev/null
}

mount_gocryptfs() {
    # Mount LOCAL_ENCRYPTED -> LOCAL_DECRYPTED using CRED_FILE if available
    if is_mounted "$LOCAL_DECRYPTED"; then
        log "gocryptfs already mounted at $LOCAL_DECRYPTED"
        return 0
    fi

    mkdir -p "$LOCAL_DECRYPTED"

    # Try password from CRED_FILE
    local pw
    if pw=$(read_password_from_credfile); then
        log "Mounting with password from $CRED_FILE"
        make_extpass_script "$pw"

        if gocryptfs -extpass "$TMP_EXTPASS_SCRIPT" "$LOCAL_ENCRYPTED" "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"; then
            log "gocryptfs mount successful"
        else
            fatal "gocryptfs mount failed"
        fi
    else
        # Interactive mount (password prompt)
        log "No password found in $CRED_FILE. Interactive password input required."
        echo "Please enter the gocryptfs password:"

        if gocryptfs "$LOCAL_ENCRYPTED" "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"; then
            log "gocryptfs mount successful"
        else
            fatal "gocryptfs mount failed"
        fi
    fi
}

unmount_gocryptfs() {
    if is_mounted "$LOCAL_DECRYPTED"; then
        log "Unmounting $LOCAL_DECRYPTED..."

        if fusermount -u "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"; then
            log "Unmount successful"
        else
            log "Warning: Normal unmount failed, trying lazy unmount..."
            if fusermount -uz "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"; then
                log "Lazy unmount successful"
            else
                error "Both normal and lazy unmount failed"
            fi
        fi
    else
        log "No mount found at $LOCAL_DECRYPTED, skipping unmount"
    fi
}

init_gocryptfs_if_needed() {
    # Initialize LOCAL_ENCRYPTED if not already initialized
    mkdir -p "$LOCAL_ENCRYPTED"

    if gocryptfs_is_initialized; then
        log "gocryptfs already initialized in $LOCAL_ENCRYPTED"
        return 0
    fi

    log "Initializing gocryptfs container..."

    # Try password from CRED_FILE
    local pw
    if pw=$(read_password_from_credfile); then
        log "Initializing gocryptfs with password from $CRED_FILE"
        make_extpass_script "$pw"

        if gocryptfs -init -extpass "$TMP_EXTPASS_SCRIPT" "$LOCAL_ENCRYPTED" 2>&1 | tee -a "$LOGFILE"; then
            log "gocryptfs initialization successful"
        else
            fatal "gocryptfs initialization failed"
        fi
    else
        # Interactive initialization
        log "gocryptfs not initialized. Interactive password setup required."
        echo "Please choose a strong password for the encryption container:"

        if gocryptfs -init "$LOCAL_ENCRYPTED" 2>&1 | tee -a "$LOGFILE"; then
            log "gocryptfs initialization successful"
        else
            fatal "gocryptfs initialization failed"
        fi
    fi
}

run_sync_nas() {
    # Run Unison sync between LOCAL_ENCRYPTED and NAS_TARGET (both encrypted data)
    log "Starting Unison synchronization (bidirectional) between:"
    log "  local(encrypted): $LOCAL_ENCRYPTED"
    log "  NAS:              $NAS_TARGET"

    # Safety checks
    if [[ ! -d "$NAS_TARGET" ]]; then
        fatal "NAS_TARGET $NAS_TARGET does not exist or is not accessible"
    fi

    # Run Unison with batch mode for automated operation
    if unison -ui text -batch -perms 0 -times "$LOCAL_ENCRYPTED" "$NAS_TARGET" 2>&1 | tee -a "$LOGFILE"; then
        log "Unison NAS sync completed successfully"
    else
        local rc=${PIPESTATUS[0]}
        if [[ $rc -eq 1 ]]; then
            log "Unison completed with warnings (rc=1) - check log for details"
        else
            error "Unison NAS sync failed (rc=$rc)"
            return $rc
        fi
    fi
}

run_sync_local() {
    # Run Unison sync between LOCAL_DOCS and LOCAL_DECRYPTED
    log "Starting Unison synchronization (bidirectional) between:"
    log "  local(documents): $LOCAL_DOCS"
    log "  local(decrypted): $LOCAL_DECRYPTED"

    # Safety checks
    if [[ ! -d "$LOCAL_DECRYPTED" ]]; then
        fatal "LOCAL_DECRYPTED $LOCAL_DECRYPTED does not exist or is not accessible"
    fi

    # Sync LOCAL_DOCS <-> LOCAL_DECRYPTED
    if unison -ui text -batch -perms 0 -times "$LOCAL_DOCS" "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"; then
        log "Unison local sync completed successfully"
    else
        local rc=${PIPESTATUS[0]}
        if [[ $rc -eq 1 ]]; then
            log "Unison completed with warnings (rc=1) - check log for details"
        else
            error "Unison local sync failed (rc=$rc)"
            return $rc
        fi
    fi
}

restore_local_from_nas() {
    # Restore complete local copy from backup (NAS)
    # Process:
    # 1) Unison sync LOCAL_ENCRYPTED <-> NAS_TARGET (get latest encrypted data)
    # 2) mount gocryptfs (LOCAL_ENCRYPTED -> LOCAL_DECRYPTED)
    # 3) rsync with safety options LOCAL_DECRYPTED/ -> LOCAL_DOCS/

    log "=== Starting restore workflow: Local copy will be restored from NAS ==="

    # 1) Sync encrypted data
    run_sync_nas || fatal "NAS sync failed during restore"

    # 2) Mount if not already mounted
    if ! is_mounted "$LOCAL_DECRYPTED"; then
        mount_gocryptfs
    fi

    # 3) Safety prompt before restore
    echo
    log "Warning: Local files in $LOCAL_DOCS may be overwritten."
    echo "Do you want to copy/update the decrypted version from container to"
    echo "  $LOCAL_DOCS"
    echo "This will create backups of overwritten files."

    local ans
    read -r -p "Perform restore? [yes/NO]: " ans
    ans=${ans,,}  # lowercase

    if [[ "$ans" != "yes" && "$ans" != "y" ]]; then
        log "Restore cancelled by user"
        return 0
    fi

    # Safe rsync: preserve older files, only overwrite with newer ones
    # Create backup directory for overwritten files
    local backup_dir="${LOCAL_DOCS%/}_backup_before_restore_$(date +%F_%H%M%S)"
    mkdir -p "$backup_dir"
    log "Backup directory for overwritten files: $backup_dir"

    # rsync with --backup (overwritten files go to backup_dir)
    if rsync -avh --update --backup --backup-dir="$backup_dir" "$LOCAL_DECRYPTED"/ "$LOCAL_DOCS"/ 2>&1 | tee -a "$LOGFILE"; then
        log "Restore completed successfully"
        log "Backup of older/overwritten files in $backup_dir"
    else
        local rc=${PIPESTATUS[0]}
        error "rsync (restore) completed with rc=$rc. Check log for details."
    fi
}

init_backup() {
    # Initial backup flow: NAS is empty
    log "=== Initial backup flow: NAS is empty ==="

    # Ensure gocryptfs is mounted
    if ! is_mounted "$LOCAL_DECRYPTED"; then
        mount_gocryptfs
    fi

    log "Initial push from LOCAL_DOCS -> LOCAL_DECRYPTED -> NAS_TARGET"

    # First sync local documents to decrypted container
    if rsync -avh --progress "$LOCAL_DOCS"/ "$LOCAL_DECRYPTED"/ 2>&1 | tee -a "$LOGFILE"; then
        log "Local documents synced to decrypted container"
    else
        fatal "Failed to sync local documents to decrypted container"
    fi

    # Then sync encrypted container to NAS
    if rsync -avh --progress "$LOCAL_ENCRYPTED"/ "$NAS_TARGET"/ 2>&1 | tee -a "$LOGFILE"; then
        log "Encrypted container synced to NAS"
    else
        fatal "Initial push to NAS failed"
    fi

    log "Initial backup completed. NAS now contains encrypted files."

    # Run normal Unison sync after initial push
    run_sync_nas
}

reset_all() {
    echo "=== Reset mode started ==="

    echo "🔒 Attempting to unmount gocryptfs..."
    if is_mounted "$LOCAL_DECRYPTED"; then
        unmount_gocryptfs
        echo "✅ $LOCAL_DECRYPTED was unmounted"
    else
        echo "ℹ️  $LOCAL_DECRYPTED is not mounted"
    fi

    echo "🗑️ Removing container directory $LOCAL_ENCRYPTED ..."
    rm -rf "$LOCAL_ENCRYPTED"

    echo "🗑️ Removing mountpoint $LOCAL_DECRYPTED ..."
    rm -rf "$LOCAL_DECRYPTED"

    echo "🗑️ Removing log files..."
    rm -rf "$LOGDIR"

    echo "✅ Reset completed. Your directory $LOCAL_DOCS remains untouched."
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Bidirectional sync script for encrypted document backup using gocryptfs and Unison.

OPTIONS:
    --restore       Restore local documents from NAS backup
    --reset         Reset all mounts and containers (LOCAL_DOCS untouched)
    --init-backup   Force initial backup (use when NAS is empty)
    --help, -h      Show this help message

EXAMPLES:
    $0                   # Normal sync operation
    $0 --restore         # Restore from backup
    $0 --reset          # Clean reset
    $0 --init-backup    # Initial backup setup

CONFIGURATION:
    Edit the variables at the top of this script to customize paths.
    Set up credentials file: $CRED_FILE

EOF
}

setup_logging() {
    # Create log directory
    if ! mkdir -p "$LOGDIR" 2>/dev/null; then
        # Fallback to user directory
        LOGDIR="${USER_HOME}/.local/share/sync_docs_unison"
        mkdir -p "$LOGDIR"
        LOGFILE="${LOGDIR}/sync_$(date +%F_%H%M%S).log"
    fi

    if ! touch "$LOGFILE" 2>/dev/null; then
        fatal "Could not create log file $LOGFILE"
    fi
}

# ============================
# Main Script Logic
# ============================

main() {
    # Setup logging
    setup_logging

    log "==== START sync_docs_unison.sh ===="
    log "LOGFILE: $LOGFILE"
    log "LOCAL_DOCS: $LOCAL_DOCS"
    log "LOCAL_ENCRYPTED: $LOCAL_ENCRYPTED"
    log "LOCAL_DECRYPTED: $LOCAL_DECRYPTED"
    log "NAS_TARGET: $NAS_TARGET"
    log "CRED_FILE: $CRED_FILE"

    # Setup cleanup on exit
    trap cleanup_temp EXIT

    # Check required programs
    check_programs

    # Parse command line arguments
    local restore_local=false
    local reset_all=false
    local init_backup=false

    for arg in "$@"; do
        case "$arg" in
            --restore)
                restore_local=true
                ;;
            --reset)
                reset_all=true
                ;;
            --init-backup)
                init_backup=true
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown parameter: $arg"
                show_help
                exit 1
                ;;
        esac
    done

    # Execute based on arguments
    if [[ "$reset_all" == "true" ]]; then
        reset_all
        exit 0
    fi

    # Check directories and NAS availability
    check_directories

    if [[ ! -d "$NAS_TARGET" ]]; then
        log "Warning: NAS_TARGET $NAS_TARGET is not available. Ensure NAS is mounted."
        fatal "NAS target path $NAS_TARGET not available"
    fi

    # Initialize gocryptfs if needed
    init_gocryptfs_if_needed

    # Mount gocryptfs container
    mount_gocryptfs

    # Execute main workflow
    if [[ "$restore_local" == "true" ]]; then
        restore_local_from_nas
    elif [[ "$init_backup" == "true" ]]; then
        init_backup
    else
        # No arguments: Normal sync operation
        if [[ -z "$(ls -A "$NAS_TARGET" 2>/dev/null)" ]]; then
            log "NAS target $NAS_TARGET is empty, performing initial backup"
            init_backup
            exit 0
        fi
        if [[ -z "$(ls -A "$LOCAL_DOCS" 2>/dev/null)" ]]; then
            log "LOCAL_DOCS target $LOCAL_DOCS is empty, performing restore operation"
            restore_local_from_nas
            exit 0
        fi

        # Standard bidirectional sync
        run_sync_local || error "Local sync failed"
        run_sync_nas || error "NAS sync failed"
        run_sync_local || error "Final local sync failed"


        # Unmount after sync
        unmount_gocryptfs
    fi

    log "==== END sync_docs_unison.sh ===="
}

# Run main function with all arguments
main "$@"