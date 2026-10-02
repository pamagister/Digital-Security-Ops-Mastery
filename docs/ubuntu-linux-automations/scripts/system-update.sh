#!/usr/bin/env bash

set -Eeuo pipefail

PAUSE_ON_EXIT=false

usage() {
    printf 'Usage: %s [--pause]\n' "${0##*/}"
    printf '  --pause  Wait for Enter before closing (useful from a desktop launcher).\n'
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
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

pause_on_exit() {
    if [[ "$PAUSE_ON_EXIT" == true && -t 0 ]]; then
        printf '\nPress Enter to close...'
        read -r || true
    fi
}
trap pause_on_exit EXIT

printf '%s\n' '=================================' '       Ubuntu System Update' '================================='

if ! command -v apt >/dev/null 2>&1; then
    printf 'Error: apt is not available on this system.\n' >&2
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    printf 'Error: sudo is not installed or not available in PATH.\n' >&2
    exit 1
fi

printf '\nAuthenticating with sudo...\n'
sudo -v

run_step() {
    local description=$1
    shift

    printf '\n>>> %s\n' "$description"
    if "$@"; then
        return
    else
        local status=$?
        printf 'Error: %s failed (exit status %d).\n' "$description" "$status" >&2
        exit "$status"
    fi
}

run_step 'Refresh APT package lists' sudo apt update
run_step 'Upgrade Ubuntu packages' sudo apt full-upgrade -y
run_step 'Remove unneeded packages' sudo apt autoremove -y
run_step 'Clean the APT cache' sudo apt autoclean

if command -v snap >/dev/null 2>&1; then
    run_step 'Update Snap packages' sudo snap refresh
else
    printf '\n>>> Snap is not installed; skipping Snap updates.\n'
fi

if command -v flatpak >/dev/null 2>&1; then
    run_step 'Update Flatpak packages' flatpak update -y
else
    printf '\n>>> Flatpak is not installed; skipping Flatpak updates.\n'
fi

printf '\n=================================\n       Update completed\n=================================\n'

if [[ -f /var/run/reboot-required ]]; then
    printf '\nA reboot is recommended to complete the updates.\n'
fi
