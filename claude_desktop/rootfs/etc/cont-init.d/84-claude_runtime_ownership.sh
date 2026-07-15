#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Earlier configuration scripts intentionally run as root and may use the configured PUID/PGID
# values when returning files to the runtime user. In bypass mode PUID can still be configured as
# 0 even though 19-claude_bypass_runtime.sh remapped abc to a non-root UID. Reconcile ownership
# with the effective desktop identity after all Claude configuration writes are complete.
RUNTIME_UID="$(id -u abc)"
RUNTIME_GID="$(id -g abc)"

for managed_path in "$HOME/.claude" "$HOME/.claude.json" "$HOME/.config/Claude"; do
    if [ -e "$managed_path" ]; then
        chown -R -- "${RUNTIME_UID}:${RUNTIME_GID}" "$managed_path" \
            || bashio::log.warning "Unable to set effective runtime ownership on $managed_path"
    fi
done
