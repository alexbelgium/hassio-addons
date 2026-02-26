#!/bin/bash
# shellcheck shell=bash

# DO NOT use set -e here — we want graceful degradation

JELLYFIN_USER=abc

log() {
    echo "[render-fix] $*"
}

# Ensure user exists
if ! id "$JELLYFIN_USER" >/dev/null 2>&1; then
    log "User $JELLYFIN_USER not found — skipping"
    exit 0
fi

# Ensure render devices are accessible by detecting actual device GID
if [ -d /dev/dri ]; then
    # Make all render devices world-accessible
    for dev in /dev/dri/renderD*; do
        if [ -e "$dev" ]; then
            log "Setting permissions on $dev"
            chmod 666 "$dev" 2>/dev/null || log "chmod failed on $dev"
        fi
    done

    # Detect the actual GID of the render device
    RENDER_GID="$(stat -c '%g' /dev/dri/renderD128 2>/dev/null || true)"
    if [ -z "$RENDER_GID" ]; then
        # Fallback: try any render device
        for dev in /dev/dri/renderD*; do
            if [ -e "$dev" ]; then
                RENDER_GID="$(stat -c '%g' "$dev" 2>/dev/null || true)"
                break
            fi
        done
    fi
    # Fallback to common render GID if no device found
    if [ -z "$RENDER_GID" ]; then
        RENDER_GID=104
    fi

    GROUP_NAME="$(getent group "$RENDER_GID" | cut -d: -f1 || true)"

    if [ -z "$GROUP_NAME" ]; then
        GROUP_NAME="render${RENDER_GID}"
        log "Creating group $GROUP_NAME with GID $RENDER_GID"
        if ! groupadd -g "$RENDER_GID" "$GROUP_NAME" 2>/dev/null; then
            log "Group creation failed (probably already exists). Continuing."
        fi
    else
        log "Group with GID $RENDER_GID already exists: $GROUP_NAME"
    fi

    # Add user to render group if not already a member
    if id "$JELLYFIN_USER" | grep -qw "$GROUP_NAME"; then
        log "User $JELLYFIN_USER already in group $GROUP_NAME"
    else
        log "Adding user $JELLYFIN_USER to group $GROUP_NAME"
        if ! usermod -aG "$GROUP_NAME" "$JELLYFIN_USER" 2>/dev/null; then
            log "usermod failed — probably read-only user or already applied"
        fi
    fi
else
    log "No /dev/dri directory found — skipping render device setup"
fi
