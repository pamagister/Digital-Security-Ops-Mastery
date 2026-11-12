#!/usr/bin/env bash

set -Eeuo pipefail

# ==============================================================================
# Ubuntu / Kubuntu System Maintenance
#
# Features:
#   - System and distribution detection
#   - APT repository validation
#   - Duplicate repository detection
#   - Full system upgrade
#   - Optional system cleanup
#   - Snap and Flatpak updates
#   - Reboot notification
#
# Compatible with Ubuntu-based distributions using APT.
# ==============================================================================

SCRIPT_NAME="${0##*/}"
PAUSE_ON_EXIT=false
DO_CLEANUP=false
APT_LOG=""

# ------------------------------------------------------------------------------
# Command-line arguments
# ------------------------------------------------------------------------------

usage() {
    printf 'Usage: %s [--pause]\n' "$SCRIPT_NAME"
    printf '  --pause  Wait for Enter before closing.\n'
}

while (($#)); do
    case "$1" in
        --pause)
            PAUSE_ON_EXIT=true
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'Error: Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

# ------------------------------------------------------------------------------
# Exit handling
# ------------------------------------------------------------------------------

on_exit() {
    local exit_status=$?

    if [[ -n "$APT_LOG" && -f "$APT_LOG" ]]; then
        rm -f "$APT_LOG"
    fi

    if [[ "$PAUSE_ON_EXIT" == true && -t 0 ]]; then
        printf '\nPress Enter to close...'
        read -r || true
    fi

    exit "$exit_status"
}

trap on_exit EXIT

# ------------------------------------------------------------------------------
# Output helpers
# ------------------------------------------------------------------------------

print_header() {
    printf '\n'
    printf '%s\n' '=================================================='
    printf '%s\n' '             LINUX SYSTEM MAINTENANCE'
    printf '%s\n' '=================================================='
}

print_section() {
    printf '\n>>> %s\n' "$1"
}

print_info() {
    printf '    %s\n' "$1"
}

print_warning() {
    printf '\nWARNING: %s\n' "$1" >&2
}

die() {
    printf '\nERROR: %s\n' "$1" >&2
    exit "${2:-1}"
}

run_step() {
    local description="$1"
    shift

    print_section "$description"

    if "$@"; then
        return 0
    else
        local status=$?
        printf '\nERROR: %s failed (exit status %d).\n' \
            "$description" "$status" >&2
        exit "$status"
    fi
}

# ------------------------------------------------------------------------------
# System detection
# ------------------------------------------------------------------------------

check_system() {
    print_section "Detecting system"

    [[ -r /etc/os-release ]] ||
        die "/etc/os-release not found."

    # shellcheck disable=SC1091
    source /etc/os-release

    if [[ "${ID:-}" != "ubuntu" &&
          " ${ID_LIKE:-} " != *" ubuntu "* ]]; then
        die "Unsupported distribution: ${PRETTY_NAME:-unknown}. Ubuntu-based system required."
    fi

    command -v apt-get >/dev/null 2>&1 ||
        die "apt-get is not available."

    command -v sudo >/dev/null 2>&1 ||
        die "sudo is not installed or unavailable."

    printf '    Distribution : %s\n' "${PRETTY_NAME:-unknown}"
    printf '    Release      : %s\n' "${VERSION_ID:-unknown}"
    printf '    Codename     : %s\n' "${VERSION_CODENAME:-unknown}"
    printf '    Architecture : %s\n' "$(dpkg --print-architecture)"

    if [[ -n "${UBUNTU_CODENAME:-}" &&
          "${UBUNTU_CODENAME}" != "${VERSION_CODENAME:-}" ]]; then
        print_info "Ubuntu base: ${UBUNTU_CODENAME}"
    fi
}

# ------------------------------------------------------------------------------
# Optional cleanup
# ------------------------------------------------------------------------------

ask_cleanup() {
    print_section "Optional system cleanup"

    if [[ ! -t 0 ]]; then
        print_info "Non-interactive mode: cleanup disabled."
        return
    fi

    printf '%s\n' \
        "The following cleanup operations can be performed:" \
        "  - Remove automatically installed, unused APT packages" \
        "  - Remove obsolete APT cache files" \
        "  - Remove unused Flatpak runtimes" \
        ""

    local answer

    if read -r -p "Perform system cleanup? [y/N] " answer; then
        case "$answer" in
            [yY]|[yY][eE][sS]|[jJ]|[jJ][aA])
                DO_CLEANUP=true
                ;;
            *)
                DO_CLEANUP=false
                ;;
        esac
    fi

    if [[ "$DO_CLEANUP" == true ]]; then
        print_info "Cleanup enabled."
    else
        print_info "Cleanup skipped."
    fi
}

# ------------------------------------------------------------------------------
# APT repository validation
# ------------------------------------------------------------------------------


check_apt_repositories() {
    print_section "Checking APT repositories"

    APT_LOG=$(mktemp)

    printf '    Refreshing package lists...\n\n'

    local status=0

    sudo apt-get update 2>&1 | tee "$APT_LOG" || status=$?

    if ((status != 0)); then
        print_warning "APT update failed."
        print_warning "Check repository URLs, signatures and network connectivity."
        exit "$status"
    fi

    # Detect duplicate repository definitions.
    if grep -Eiq \
        'configured multiple times|mehrfach konfiguriert' \
        "$APT_LOG"; then

        print_warning "Duplicate APT repository entries detected!"

        grep -Ei \
            'configured multiple times|mehrfach konfiguriert' \
            "$APT_LOG" || true

        printf '\n'
        print_warning "Review the affected source files before continuing."
        exit 2
    fi

    # Detect repositories with failed downloads or invalid signatures.
    if grep -Eiq \
        'Failed to fetch|konnte nicht heruntergeladen werden|does not have a Release file|NO_PUBKEY|EXPKEYSIG|BADSIG|not signed|nicht signiert|Some index files failed to download|Einige Indexdateien konnten nicht heruntergeladen werden' \
        "$APT_LOG"; then

        print_warning "Repository errors detected!"

        printf '\n'
        grep -Ei \
            'Failed to fetch|konnte nicht heruntergeladen werden|does not have a Release file|NO_PUBKEY|EXPKEYSIG|BADSIG|not signed|nicht signiert|Some index files failed to download|Einige Indexdateien konnten nicht heruntergeladen werden' \
            "$APT_LOG" || true

        printf '\n'
        print_warning "System upgrade aborted. Check the affected repositories."
        exit 3
    fi

    print_info "No duplicate repository warnings detected."
    print_info "No known repository download or signature errors detected."
    print_info "APT package lists successfully refreshed."
}


# ------------------------------------------------------------------------------
# Package consistency
# ------------------------------------------------------------------------------

check_package_integrity() {
    run_step \
        "Checking package dependencies" \
        sudo apt-get check
}

# ------------------------------------------------------------------------------
# System upgrade
# ------------------------------------------------------------------------------

upgrade_system() {
    run_step \
        "Upgrading system packages" \
        sudo apt-get full-upgrade -y
}

# ------------------------------------------------------------------------------
# Snap updates
# ------------------------------------------------------------------------------

update_snap() {
    if command -v snap >/dev/null 2>&1; then
        run_step \
            "Updating Snap packages" \
            sudo snap refresh
    else
        print_section "Snap not installed - skipping."
    fi
}

# ------------------------------------------------------------------------------
# Flatpak updates
# ------------------------------------------------------------------------------

update_flatpak() {
    if command -v flatpak >/dev/null 2>&1; then
        run_step \
            "Updating Flatpak packages" \
            flatpak update --assumeyes
    else
        print_section "Flatpak not installed - skipping."
    fi
}

check_flatpak_eol() {
    command -v flatpak >/dev/null 2>&1 || return 0

    print_section "Checking Flatpak end-of-life runtimes"

    local output

    output=$(flatpak list --runtime --columns=application,branch 2>/dev/null || true)

    if [[ -z "$output" ]]; then
        print_info "No installed Flatpak runtimes found."
        return 0
    fi

    local found=false

    while IFS=$'\t' read -r runtime branch; do
        [[ -n "$runtime" ]] || continue

        local info

        info=$(flatpak info "$runtime//$branch" 2>&1 || true)

        if grep -Eiq 'end-of-life|end of life|nicht mehr unterstützt' <<< "$info"; then
            if [[ "$found" == false ]]; then
                print_warning "End-of-life Flatpak runtimes detected:"
                found=true
            fi

            printf '    %s (%s)\n' "$runtime" "$branch"
        fi
    done <<< "$output"

    if [[ "$found" == false ]]; then
        print_info "No end-of-life Flatpak runtimes detected."
    else
        print_warning "Some Flatpak applications may require attention."
    fi
}

# ------------------------------------------------------------------------------
# Cleanup operations
# ------------------------------------------------------------------------------

cleanup_system() {
    [[ "$DO_CLEANUP" == true ]] || return 0

    run_step \
        "Removing unused APT packages" \
        sudo apt-get autoremove -y

    run_step \
        "Cleaning obsolete APT cache files" \
        sudo apt-get autoclean

    if command -v flatpak >/dev/null 2>&1; then
        run_step \
            "Removing unused Flatpak runtimes" \
            flatpak uninstall --unused --assumeyes
    fi
}

# ------------------------------------------------------------------------------
# Reboot status
# ------------------------------------------------------------------------------

check_reboot() {
    print_section "Checking reboot status"

    if [[ -e /run/reboot-required ]]; then
        print_warning "A system reboot is required."

        if [[ -r /run/reboot-required.pkgs ]]; then
            printf '\nPackages requesting reboot:\n'
            cat /run/reboot-required.pkgs
        fi
    else
        print_info "No reboot requirement detected."
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    print_header

    check_system
    ask_cleanup

    print_section "Authenticating"
    sudo -v

    check_apt_repositories
    check_package_integrity
    upgrade_system

    update_snap
    update_flatpak
    check_flatpak_eol

    cleanup_system
    check_reboot

    printf '\n'
    printf '%s\n' '=================================================='
    printf '%s\n' '             MAINTENANCE COMPLETED'
    printf '%s\n' '=================================================='
    printf '\n'
}

main "$@"
