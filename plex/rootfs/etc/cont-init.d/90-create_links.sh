#!/usr/bin/env bashio

set -Eeuo pipefail

##################
# SYMLINK CONFIG #
##################

# Helper: Fix ownership only if needed (on folder, not all files)
fix_owner_if_needed() {
    local path="$1"
    local want_uid="$2"
    local want_gid="$3"
    local curr_uid curr_gid

    if [ -e "$path" ]; then
        curr_uid=$(stat -c '%u' "$path")
        curr_gid=$(stat -c '%g' "$path")
        if [ "$curr_uid" -ne "$want_uid" ] || [ "$curr_gid" -ne "$want_gid" ]; then
            echo "Fixing ownership: $path ($curr_uid:$curr_gid -> $want_uid:$want_gid)"
            chown -R "$want_uid:$want_gid" "$path"
        fi
    fi
}

# Helper: Fix mode only if needed (on folder, not all files)
fix_mode_if_needed() {
    local path="$1"
    local want_mode="$2"
    local curr_mode

    if [ -e "$path" ]; then
        curr_mode=$(stat -c '%a' "$path")
        if [ "$curr_mode" -ne "$want_mode" ]; then
            echo "Fixing mode: $path ($curr_mode -> $want_mode)"
            chmod -R "$want_mode" "$path"
        fi
    fi
}

# Ensure /share/plex exists
if [ ! -d /share/plex ]; then
    echo "Creating /share/plex"
    mkdir -p /share/plex
fi

# Library folder move/link
mkdir -p /config/Library
if [ ! -d /share/plex/Library ]; then
    echo "Moving Library folder"
    mv /config/Library /share/plex
    ln -s /share/plex/Library /config
    echo "Links done"
else
    rm -rf /config/Library
    ln -s /share/plex/Library /config
    echo "Using existing config"
fi

# Only fix ownership/mode if needed (top-level only—*not* blindly every file)
PUID="$(bashio::config "PUID")"
PGID="$(bashio::config "PGID")"

# Only run fixes if not root (UID/GID != 0)
if [ "$PUID" != "0" ] && [ "$PGID" != "0" ]; then
    fix_owner_if_needed "/share/plex" "$PUID" "$PGID"
    fix_owner_if_needed "/share/plex/Library" "$PUID" "$PGID"
    fix_mode_if_needed "/share/plex" 777
fi
