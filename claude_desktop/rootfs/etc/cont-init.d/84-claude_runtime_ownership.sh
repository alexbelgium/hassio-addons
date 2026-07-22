#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Earlier configuration scripts intentionally run as root. 20-folders.sh remapped abc to the
# effective runtime identity (never root in bypass mode, where Claude Code refuses to run as
# root). Reconcile ownership with that identity after all Claude configuration writes are
# complete, as a safety net in case any intermediate step re-owned a managed path.
RUNTIME_UID="$(id -u abc)"
RUNTIME_GID="$(id -g abc)"

for managed_path in "$HOME/.claude" "$HOME/.claude.json" "$HOME/.config/Claude"; do
    if [ -e "$managed_path" ]; then
        chown -R -- "${RUNTIME_UID}:${RUNTIME_GID}" "$managed_path" \
            || bashio::log.warning "Unable to set effective runtime ownership on $managed_path"
    fi
done
