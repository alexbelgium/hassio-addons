#!/usr/bin/env bashio
# shellcheck shell=bash

set -euo pipefail

##################
# SYMLINK CONFIG #
##################

DATA_LOCATION="$(bashio::config 'data_location')"
TARGET_DIR="${DATA_LOCATION%/}/Plex Media Server"

APP_SUPPORT_BASE="/config/Library/Application Support"
LINK_PATH="${APP_SUPPORT_BASE}/Plex Media Server"

LAST_FILE="/config/.plex_data_location_last"

bashio::log.info "Database stored in ${TARGET_DIR}"

# Returns 0 if directory looks like it contains real Plex library data
is_plex_populated() {
    local d="$1"

    [[ -d "$d" ]] || return 1

    # Strong indicators Plex has real state here
    [[ -f "${d}/Preferences.xml" ]] && return 0
    [[ -f "${d}/Plug-in Support/Databases/com.plexapp.plugins.library.db" ]] && return 0

    return 1
}

copy_tree() {
    local src="$1"
    local dst="$2"

    if command -v rsync >/dev/null 2>&1; then
        # Trailing slashes are important: copy contents into dst
        rsync -aH --numeric-ids --inplace --info=progress2 "${src%/}/" "${dst%/}/"
    else
        # Fallback (may be slower / less robust than rsync for huge libs)
        mkdir -p "$dst"
        cp -a "${src%/}/." "$dst"
    fi
}

#########################
# Detect & run migration #
#########################

LAST_LOCATION=""
if [[ -f "$LAST_FILE" ]]; then
    LAST_LOCATION="$(cat "$LAST_FILE" 2>/dev/null || true)"
fi

OLD_DIR=""
if [[ -n "$LAST_LOCATION" && "$LAST_LOCATION" != "$DATA_LOCATION" ]]; then
    OLD_DIR="${LAST_LOCATION%/}/Plex Media Server"
elif [[ -d "$LINK_PATH" && ! -L "$LINK_PATH" ]]; then
    # If link path exists as a real directory (not symlink), treat it as the old location
    OLD_DIR="$LINK_PATH"
fi

mkdir -p "$TARGET_DIR"

if [[ -n "$OLD_DIR" && "$OLD_DIR" != "$TARGET_DIR" ]]; then
    if is_plex_populated "$OLD_DIR" && ! is_plex_populated "$TARGET_DIR"; then
        bashio::log.warning "Detected data_location change. Migrating Plex data:"
        bashio::log.warning "  from: ${OLD_DIR}"
        bashio::log.warning "  to:   ${TARGET_DIR}"
        copy_tree "$OLD_DIR" "$TARGET_DIR"
        bashio::log.info "Migration completed."
    else
        bashio::log.info "No migration needed (source not populated or destination already populated)."
    fi
fi

# Record current location for next boot
printf '%s' "$DATA_LOCATION" > "$LAST_FILE"

#################
# Create symlink #
#################

mkdir -p "$APP_SUPPORT_BASE"

# If there is an existing path at LINK_PATH:
# - if it's the correct symlink, keep it
# - otherwise, remove only that path (no wildcards) and recreate
if [[ -L "$LINK_PATH" ]]; then
    # If it's a symlink but points elsewhere, replace it
    if [[ "$(readlink "$LINK_PATH")" != "$TARGET_DIR" ]]; then
        rm -f "$LINK_PATH"
        ln -s "$TARGET_DIR" "$LINK_PATH"
    fi
elif [[ -e "$LINK_PATH" ]]; then
    # File or directory: remove it safely and replace
    rm -rf "$LINK_PATH"
    ln -s "$TARGET_DIR" "$LINK_PATH"
else
    ln -s "$TARGET_DIR" "$LINK_PATH"
fi

#############################
# Adapt permissions if needed #
#############################

if ! bashio::config.true "skip_permissions_check" && [[ "${PUID:-0}" != "0" && "${PGID:-0}" != "0" ]]; then
    bashio::log.info "Setting permissions on ${TARGET_DIR} (can take time on large libraries)"
    chmod -R 755 "$TARGET_DIR"
    chown -R "$PUID:$PGID" "$TARGET_DIR"
elif bashio::config.true "skip_permissions_check"; then
    bashio::log.warning "Skipping permissions check as 'skip_permissions_check' is set"
fi

############################
# Clear Codecs folder option #
############################

if bashio::config.true "clear_codecs_folder" && [[ -d "${TARGET_DIR}/Codecs" ]]; then
    bashio::log.warning "Deleting codecs folder: ${TARGET_DIR}/Codecs"
    rm -rf "${TARGET_DIR}/Codecs"
fi
