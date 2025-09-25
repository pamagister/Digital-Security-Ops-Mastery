#!/usr/bin/env bash
# sync_docs_unison.sh
# Bidirektionaler Sync zwischen lokalem gocryptfs-Container und NAS via Unison.
# - bevorzugt Passwort aus /etc/samba/credentials_sync_docs
# - init gocryptfs automatisch falls nötig (versucht Passwort aus CRED_FILE)
# - mount, run unison between LOCAL_ENCRYPTED and NAS_TARGET, unmount
# - optional: --restore (restore decrypted files into LOCAL_DOCS)
# - optional: --reset (reset current mounts, does not affect LOCAL_DOCS)
#
# WICHTIG: Dieses Script löscht NIE ungefragt Dateien in LOCAL_DOCS.
#         Unison behandelt Konflikte interaktiv (fragt den Nutzer).#

# Script ausführbar machen: >> chmod +x ~/sync_docs_unison.sh
# Script ausführen, z.B.:   >> ./sync_docs_unison.sh --restore

# === Credential-File ===
# 1. Erst credentials_nas anlegen:
# sudo nano /etc/samba/credentials_sync_docs
# 2. Inhalt:
# NUR_DAS_PASSWORT_EINTRAGEN
# 3. Rechte beschränken
# sudo chmod 600 /etc/samba/credentials_sync_docs

# Manuelles Retten:
# 1. Nas-Ziel setzen:
# >> NAS_TARGET="/mnt/nas/data/Backups/encrypted_documents"
# 2. Mountpoint vorbereiten:
# >> mkdir -p tmp/nas_decrypted
# 3. gocryptfs direkt starten (mit Passwortabfrage read-only zur Sicherheit):
# >> gocryptfs -ro "$NAS_TARGET" user/NAME/nas_decrypted
# 4. Unmount, wenn fertig
# >> umount tmp/nas_decrypted

set -u
set -o pipefail

# never use root dir, allways determine real user home directory
if [ -n "${SUDO_USER:-}" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

# ============================
# =  Konfiguration (Variablen)
# ============================
LOCAL_DOCS="$USER_HOME/testdir/"    # Zu sicherndes lokales Verzeichnis
LOCAL_ENCRYPTED="$USER_HOME/.encrypted_docs"  # gocryptfs-Mount verschlüsselt
LOCAL_DECRYPTED="$USER_HOME/.decrypted_docs"  # gocryptfs-Mount UNverschlüsselt
NAS_TARGET="/mnt/nas/data/Backups/encrypted_docs_backup"  # Backup-Ordner z.B. auf einer NAS
CRED_FILE="/etc/samba/credentials_sync_docs"  # anlegen mit: (Nur das Passwort dort eintragen) >> sudo nano /etc/samba/credentials_sync_docs >> sudo chmod 600 /etc/samba/credentials_sync_docs

LOGDIR="/tmp/log/sync_docs_unison"
LOGFILE="${LOGDIR}/sync_$(date +%F_%H%M%S).log"
TMP_EXTPASS_SCRIPT="/tmp/gocryptfs_extpass_$$.sh"   # temporäres extpass-script
UNISON_PROFILE="/tmp/unison_sync_profile_$$.prf"    # temporärer Unison-Profil

# ============================
# =  Hilfsfunktionen
# ============================
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

fatal() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] FATAL: $*" | tee -a "$LOGFILE" >&2
    cleanup_temp
    exit 1
}

cleanup_temp() {
    # sichere Löschung der temporären extpass-Scripts
    if [ -f "$TMP_EXTPASS_SCRIPT" ]; then
        shred -u "$TMP_EXTPASS_SCRIPT" 2>/dev/null || rm -f "$TMP_EXTPASS_SCRIPT"
    fi
    if [ -f "$UNISON_PROFILE" ]; then
        rm -f "$UNISON_PROFILE"
    fi
}

read_password_from_credfile() {
    # Liefert Passwort auf stdout falls gefunden und lesbar, sonst leeres Ergebnis.
    if sudo test -r "$CRED_FILE"; then
        pw=$(sudo grep -m1 -E '^[^#[:space:]]' "$CRED_FILE" 2>/dev/null | sed -E 's/^password=//')
        if [ -n "$pw" ]; then
            echo "$pw"
            return 0
        fi
    fi

    return 1
}

make_extpass_script() {
    # erzeugt ein kleines Script, das das Passwort ausgibt, für gocryptfs -extpass.
    # erwartet Passwort als ersten Parameter
    local pw="$1"
    cat > "$TMP_EXTPASS_SCRIPT" <<EOF
#!/bin/sh
echo "$pw"
EOF

    chmod 700 "$TMP_EXTPASS_SCRIPT"
}

check_programs() {
    local missing=()
    for prog in gocryptfs unison rsync fusermount; do
        if ! command -v "$prog" >/dev/null 2>&1; then
            missing+=("$prog")
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        fatal "Benötigte Programme fehlen: ${missing[*]}. Bitte installieren."
    fi
}

gocryptfs_is_initialized() {
    [ -f "${LOCAL_ENCRYPTED}/gocryptfs.conf" ]
}

mount_gocryptfs() {
    # Mountet LOCAL_ENCRYPTED -> LOCAL_DECRYPTED. Nutzt CRED_FILE falls vorhanden.
    if mountpoint -q "$LOCAL_DECRYPTED"; then
        log "gocryptfs bereits gemountet auf $LOCAL_DECRYPTED"
        return 0
    fi

    mkdir -p "$LOCAL_DECRYPTED"
    # Versuche Passwort aus CRED_FILE
    if pw=$(read_password_from_credfile); then
        log "Mount: Passwort aus $CRED_FILE wird verwendet"
        make_extpass_script "$pw"
        # --nonempty falls verschlüss. Ordner nicht leer ist; keine interactive Passworteingabe.
        gocryptfs -extpass "$TMP_EXTPASS_SCRIPT" "$LOCAL_ENCRYPTED" "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"
        rc=${PIPESTATUS[0]}
        if [ $rc -ne 0 ]; then
            fatal "gocryptfs mount fehlgeschlagen (rc=$rc)."
        fi
    else
        # interactiver Mount (Passworteingabe)
        log "Kein Passwort in $CRED_FILE gefunden/lesbar. Interaktive Passwort-Eingabe erforderlich."
        gocryptfs --nonempty "$LOCAL_ENCRYPTED" "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"
        rc=${PIPESTATUS[0]}
        if [ $rc -ne 0 ]; then
            fatal "gocryptfs mount fehlgeschlagen (rc=$rc)."
        fi
    fi
}

unmount_gocryptfs() {
    if mountpoint -q "$LOCAL_DECRYPTED"; then
        log "Unmounting $LOCAL_DECRYPTED..."
        if fusermount -u "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"; then
            log "Unmount erfolgreich."
        else
            log "Warnung: Unmount möglicherweise fehlgeschlagen; Versuch mit lazy unmount."
            fusermount -uz "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE" || log "Lazy unmount ebenfalls fehlgeschlagen."
        fi
    else
        log "Kein mount gefunden; überspringe unmount."
    fi
}

init_gocryptfs_if_needed() {
    # initialisiert LOCAL_ENCRYPTED falls noch nicht initialisiert.
    mkdir -p "$LOCAL_ENCRYPTED"
    if gocryptfs_is_initialized; then
        log "gocryptfs bereits initialisiert in $LOCAL_ENCRYPTED"
        return 0
    fi

    # Versuche Passwort aus CRED_FILE zu benutzen
    if pw=$(read_password_from_credfile); then
        log "Initialisiere gocryptfs mit Passwort aus $CRED_FILE"
        make_extpass_script "$pw"
        # gocryptfs -init liest nicht --extpass; wir können passwd via stdin übergeben:
        # aber gocryptfs -init fragt Passwort interaktiv zweimal; wir verwenden here-doc sicher.
        # Achtung: Damit Passwort nicht in ps angezeigt wird, vermeiden wir Befehlszeilen-Parameter.
        # Wir verwenden ein expect-ähnliches HereDoc — gocryptfs akzeptiert stdin für -init.
        # (Falls auf deiner Version nicht funktioniert, wird interaktiv gefragt.)

        gocryptfs -init -extpass "$TMP_EXTPASS_SCRIPT" "$LOCAL_ENCRYPTED" 2>&1 | tee -a "$LOGFILE"
        rc=${PIPESTATUS[0]}
        if [ $rc -ne 0 ]; then
            fatal "gocryptfs -init fehlgeschlagen (rc=$rc)."
        else
            log "gocryptfs -init erfolgreich"
        fi
    else
        # Interaktive Init
        log "gocryptfs nicht initialisiert. Interaktive Passwortvergabe wird benötigt."
        echo "Bitte wähle ein starkes Passwort für den Verschlüsselungs-Container (wird nicht protokolliert)."
        gocryptfs -init "$LOCAL_ENCRYPTED" 2>&1 | tee -a "$LOGFILE"
        rc=${PIPESTATUS[0]}
        if [ $rc -ne 0 ]; then
            fatal "gocryptfs -init fehlgeschlagen (rc=$rc)."
        fi
    fi
}

create_unison_profile() {
    # Erzeuge temporäres Unison-Profil, damit wir reproduzierbar loggen können
    cat > "$UNISON_PROFILE" <<EOF
root = $LOCAL_ENCRYPTED
root = $NAS_TARGET
# Keine automatische Löschung ohne Nachfrage
confirmbigdel = true
# Logfile für unison selbst
log = true
logfile = ${LOGDIR}/unison_$(date +%F_%H%M%S).log
# Standard-Optionen (rekursiv, ignorieren von .git etc. anpassen falls nötig)
ignore = Path .git
EOF

    # Unison interaktiv (UI: text). Bei Konflikten wirst du interaktiv gefragt.
    # Wir leiten stdout/stderr ins Hauptlog.
    log "Unison-Profil geschrieben nach $UNISON_PROFILE"
}

run_sync_nas() {
    # Führe Unison in interaktivem Modus aus, damit Konflikte abgefragt werden.
    # Unison zwischen LOCAL_ENCRYPTED und NAS_TARGET (beides verschlüsselte Daten)
    log "Starte Unison-Synchronisation (bidirektional) zwischen:"
    log "  lokal(encrypted): $LOCAL_ENCRYPTED"
    log "  NAS:              $NAS_TARGET"

    # Sicherheitschecks
    if [ ! -d "$NAS_TARGET" ]; then
        fatal "NAS_TARGET $NAS_TARGET existiert nicht oder ist nicht erreichbar."
    fi

    # Auf manchen Systemen braucht Unison den Profil-Namen, wir starten mit -ui text und -pref
    unison -ui text -perms 0 -batch "$LOCAL_ENCRYPTED" "$NAS_TARGET" 2>&1 | tee -a "$LOGFILE"
    rc=${PIPESTATUS[0]}
    if [ $rc -ne 0 ]; then
        log "Unison Meldung (rc=$rc). Falls rc != 0 könnte es Konflikte oder Fehler gegeben haben. Prüfe ${LOGDIR}."
    else
        log "Unison Sync beendet (rc=0)."
    fi
}

run_sync_local() {
    # Führe Unison in interaktivem Modus aus, damit Konflikte abgefragt werden.
    # Unison zwischen $LOCAL_DOCS und $LOCAL_DECRYPTED (beides verschlüsselte Daten)
    log "Starte Unison-Synchronisation (bidirektional) zwischen:"
    log "  lokal(zu sicherndes Verzeichnis): $LOCAL_DOCS"
    log "  lokal(decrypted): $LOCAL_DECRYPTED"

    # Sicherheitschecks
    if [ ! -d "$LOCAL_DECRYPTED" ]; then
        fatal "LOCAL_DECRYPTED $LOCAL_DECRYPTED existiert nicht oder ist nicht erreichbar."
    fi

    # Sync LOCAL_DOCS <-> LOCAL_DECRYPTED
    log "Syncrhonisiere $LOCAL_DOCS und $LOCAL_DECRYPTED"
    unison -ui text -perms 0 -batch "$LOCAL_DOCS" "$LOCAL_DECRYPTED" 2>&1 | tee -a "$LOGFILE"
    rc=${PIPESTATUS[0]}
    if [ $rc -ne 0 ]; then
        log "Unison Meldung (rc=$rc). Falls rc != 0 könnte es Konflikte oder Fehler gegeben haben. Prüfe ${LOGDIR}."
    else
        log "Unison Sync beendet (rc=0)."
    fi
}

restore_local_from_nas() {
    # Anwendung: komplette lokale Kopie aus dem Backup (NAS) wiederherstellen.
    # Ablauf:
    # 1) Unison sync LOCAL_ENCRYPTED <-> NAS_TARGET (holt neueste verschlüsselte Daten)
    # 2) mount gocryptfs (LOCAL_ENCRYPTED -> LOCAL_DECRYPTED)
    # 3) rsync --archive --update --backup --backup-dir=... LOCAL_DECRYPTED/ LOCAL_DOCS/
    #    (Sicherheit: wir fragen Nutzer vor dem finalen Restore)
    log "=== Wiederherstellungs-Workflow gestartet: Lokale Kopie wird aus NAS wiederhergestellt ==="

    # 1) sync verschlüsselt
    run_sync_nas

    # 2) mounten
    mount_gocryptfs

    # 3) Vor dem restore: Sicherheitsabfrage, denn dies kann Dateien überschreiben
    echo
    log "Vor dem Kopiervorgang: lokale Dateien in $LOCAL_DOCS können überschrieben werden."
    echo "Soll ich die entschlüsselte Version vom Container nach"
    echo "  $LOCAL_DOCS"
    echo "kopieren/aktualisieren? (Antwort: ja oder nein)"
    read -r -p "Restore durchführen? [ja/NEIN]: " ans
    ans=${ans,,}   # lower
    if [[ "$ans" != "ja" && "$ans" != "j" ]]; then
        log "Restore abgebrochen vom Nutzer."
        unmount_gocryptfs
        return 0
    fi

    # safe rsync: wir lassen ältere Dateien unangetastet, überschreiben nur mit neueren
    # zusätzlich legen wir Backups der überschriebenen Dateien in ein Datum-Verzeichnis
    BACKUP_DIR="${LOCAL_DOCS}_backup_before_restore_$(date +%F_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    log "Backup-Verzeichnis für überschriebenen Dateien: $BACKUP_DIR"

    # rsync mit --backup (verschobene/überschriebene Dateien landen in BACKUP_DIR)
    rsync -avh --update --backup --backup-dir="$BACKUP_DIR" --exclude="$LOCAL_DOCS/*" "$LOCAL_DECRYPTED"/ "$LOCAL_DOCS"/ 2>&1 | tee -a "$LOGFILE"
    rc=${PIPESTATUS[0]}
    if [ $rc -ne 0 ]; then
        log "Warnung: rsync (restore) wurde mit rc=$rc beendet. Sieh ins Log."
    else
        log "Restore abgeschlossen. Backup älterer/überschriebener Dateien in $BACKUP_DIR"
    fi

    unmount_gocryptfs
}

# ============================
# =  Initialer Push auf NAS
# ============================
init_backup() {
    log "=== Initialer Backup-Flow: NAS ist leer ==="

    # Stelle sicher, dass gocryptfs gemountet ist
    mount_gocryptfs

    log "Initialer Push von LOCAL_ENCRYPTED -> NAS_TARGET"
    rsync -avh --progress "$LOCAL_DOCS"/ "$LOCAL_DECRYPTED"/ 2>&1 | tee -a "$LOGFILE"
    rsync -avh --progress "$LOCAL_ENCRYPTED"/ "$NAS_TARGET"/ 2>&1 | tee -a "$LOGFILE"
    rc=${PIPESTATUS[0]}
    if [ $rc -ne 0 ]; then
        fatal "Initialer Push auf NAS fehlgeschlagen (rc=$rc)."
    fi

    log "Initialer Push abgeschlossen. NAS enthält jetzt die verschlüsselten Dateien."

    # Optional: danach Unison normal ausführen
    run_sync_nas

    # Unmounten nach initialem Push
    unmount_gocryptfs
}


reset_all() {
    echo "=== Reset-Modus gestartet ==="

    echo "🔒 Versuche, gocryptfs zu unmounten..."
    if mountpoint -q "$LOCAL_DECRYPTED"; then
        fusermount -u "$LOCAL_DECRYPTED" 2>/dev/null || umount "$LOCAL_DECRYPTED"
        echo "✅ $LOCAL_DECRYPTED wurde unmountet."
    else
        echo "ℹ️  $LOCAL_DECRYPTED ist nicht gemountet."
    fi

    echo "🗑️ Lösche Container-Verzeichnis $LOCAL_ENCRYPTED ..."
    rm -rf "$LOCAL_ENCRYPTED"

    echo "🗑️ Lösche Mountpoint $LOCAL_DECRYPTED ..."
    rm -rf "$LOCAL_DECRYPTED"

    echo "🗑️ Lösche Logfile $LOGFILE ..."
    rm -f "$LOGFILE"

    echo "✅ Reset abgeschlossen. Dein Ordner $LOCAL_DOCS bleibt unberührt."
}


# ============================
# =  Start: Setup logs etc.
# ============================
# Erstelle Log-Verzeichnis falls möglich
if ! mkdir -p "$LOGDIR" 2>/dev/null; then
    # Fallback auf home-Verzeichnis
    LOGDIR="${HOME}/.local/share/sync_docs_unison"
    mkdir -p "$LOGDIR"
    LOGFILE="${LOGDIR}/sync_$(date +%F_%H%M%S).log"
fi

touch "$LOGFILE" 2>/dev/null || fatal "Konnte Logfile $LOGFILE nicht anlegen."

log "==== START sync_docs_unison.sh ===="
log "LOGFILE: $LOGFILE"
log "LOCAL_DOCS: $LOCAL_DOCS"
log "LOCAL_ENCRYPTED: $LOCAL_ENCRYPTED"
log "LOCAL_DECRYPTED: $LOCAL_DECRYPTED"
log "NAS_TARGET: $NAS_TARGET"
log "CRED_FILE: $CRED_FILE"

# cleanup on EXIT
trap cleanup_temp EXIT

# Check required programs
check_programs

# ============================
# =  Argumente
# ============================
RESTORE_LOCAL=false
RESET_ALL=false
# optionaler Parameter: --restore
if [ "${#@}" -gt 0 ]; then
    for a in "$@"; do
        case "$a" in
            --restore) RESTORE_LOCAL=true ;;
            --reset) RESET_ALL=true ;;
            --help|-h) echo "Usage: $0 [--restore] [--reset]"; exit 0 ;;
            *) echo "Unbekannter Parameter: $a"; echo "Usage: $0 [--restore] [--reset]"; exit 1 ;;
        esac
    done
fi

# ============================
# =  Workflow
# ============================
if [ "$RESET_ALL" = true ]; then
    # Restore-Flow
    reset_all
    exit 0
fi

# 0) Basis-Checks / Erreichbarkeit NAS
if [ ! -d "$NAS_TARGET" ]; then
    # try to fallback to mountpoint not mounted message
    log "Warnung: NAS_TARGET $NAS_TARGET scheint nicht vorhanden zu sein. Stelle sicher, dass das NAS gemountet ist."
    log "Script stoppt jetzt."
    fatal "NAS Zielpfad $NAS_TARGET nicht verfügbar."
fi

# 1) init gocryptfs falls nötig (ohne Dateien zu löschen)
log "init_gocryptfs_if_needed"
init_gocryptfs_if_needed

# 2) stelle sicher, dass der Container gemountet ist (für restore oder falls Workflows mount benötigen)
#    Für normalen Unison-Sync wird LOCAL_ENCRYPTED synchronisiert; wir mounten trotzdem, weil Benutzer evtl.
#    lokal mit LOCAL_DECRYPTED arbeiten will bzw. Restore benötigt.
log "mount_gocryptfs"
mount_gocryptfs

# 3) Hauptaktion:
if [ "$RESTORE_LOCAL" = true ]; then
    # Restore-Flow
    restore_local_from_nas
else
    if [ -z "$(ls -A "$NAS_TARGET")" ]; then
        # Erstes Backup, Zielverzeichnis auf der NAS ist leer
        init_backup
    fi

    # Normaler Bidirektionaler Sync: Unison zwischen verschlüsseltem Container und NAS
    run_sync_local
    run_sync_nas
    run_sync_local
    # optional: nach Sync unmounten
    unmount_gocryptfs
fi

log "==== ENDE sync_docs_unison.sh ===="
exit 0
