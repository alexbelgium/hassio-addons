#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# 20-folders.sh is shared with the Webtop add-ons and historically redirects
# XDG_CACHE_HOME to /tmp/cache. This Claude-specific follow-up runs before the
# graphical longruns and moves general application caches back under the
# persistent home. Removing config.yaml's `tmpfs: true` then ensures Chromium,
# Electron, Mesa and other cache pages are reclaimable filesystem cache instead
# of permanently charged cgroup shmem.
LOCATION="$(getent passwd abc 2> /dev/null | cut -d: -f6 || true)"
if [ -z "$LOCATION" ] || [ "$LOCATION" = "/" ]; then
    bashio::log.warning "Unable to resolve abc home; leaving XDG cache configuration unchanged"
    exit 0
fi

CACHE_DIR="$LOCATION/.cache"
if [ -L "$CACHE_DIR" ]; then
    rm -f "$CACHE_DIR"
fi
mkdir -p "$CACHE_DIR"
chown "$(id -u abc):$(id -g abc)" "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

CACHE_DIR="$CACHE_DIR" LOCATION="$LOCATION" python3 - <<'PY'
import os
import re
from pathlib import Path

cache = os.environ["CACHE_DIR"]
quoted = cache.replace("\\", "\\\\").replace('"', '\\"')
replacement = f'export XDG_CACHE_HOME="{quoted}"'

for path in Path("/etc/s6-overlay/s6-rc.d").glob("*/run"):
    try:
        text = path.read_text()
    except (OSError, UnicodeDecodeError):
        continue
    updated = re.sub(r"^export XDG_CACHE_HOME=.*$", replacement, text, flags=re.MULTILINE)
    if updated != text:
        path.write_text(updated)

bashrc = Path(os.environ["LOCATION"]) / ".bashrc"
if bashrc.exists():
    text = bashrc.read_text()
    updated = re.sub(r"^export XDG_CACHE_HOME=.*$", replacement, text, flags=re.MULTILINE)
    if updated != text:
        bashrc.write_text(updated)
PY

S6_ENVDIR="/run/s6/container_environment"
mkdir -p "$S6_ENVDIR"
printf '%s' "$CACHE_DIR" > "$S6_ENVDIR/XDG_CACHE_HOME"

# Safe here: no graphical longrun has started yet, and the former directory was
# only a boot-created target for the now-removed persistent-home symlink.
rm -rf /tmp/cache
bashio::log.info "Application cache moved from RAM-backed /tmp to $CACHE_DIR"
