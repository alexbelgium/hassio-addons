#!/bin/bash
# shellcheck shell=bash

# DO NOT use set -e here — we want graceful degradation

RENDER_GID=104
JELLYFIN_USER=abc
GROUP_NAME=""

log() {
    echo "[render-fix] $*"
}

# Find group owning GID 104
GROUP_NAME="$(getent group "$RENDER_GID" | cut -d: -f1 || true)"

if [ -z "$GROUP_NAME" ]; then
    GROUP_NAME="render104"
    log "Creating group $GROUP_NAME with GID $RENDER_GID"
    if ! groupadd -g "$RENDER_GID" "$GROUP_NAME" 2>/dev/null; then
        log "Group creation failed (probably already exists). Continuing."
    fi
else
    log "Group with GID $RENDER_GID already exists: $GROUP_NAME"
fi

# Ensure user exists
if ! id "$JELLYFIN_USER" >/dev/null 2>&1; then
    log "User $JELLYFIN_USER not found — skipping"
    exit 0
fi

# Check if already member
if id "$JELLYFIN_USER" | grep -qw "$GROUP_NAME"; then
    log "User $JELLYFIN_USER already in group $GROUP_NAME"
    exit 0
fi

log "Adding user $JELLYFIN_USER to group $GROUP_NAME"
if ! usermod -aG "$GROUP_NAME" "$JELLYFIN_USER" 2>/dev/null; then
    log "usermod failed — probably read-only user or already applied"
fi
