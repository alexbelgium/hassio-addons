#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Earlier configuration scripts intentionally run as root. Reconcile the paths written by those
# scripts with the final abc runtime identity and its configured persistent home.
RUNTIME_UID="$(id -u abc)"
RUNTIME_GID="$(id -g abc)"
RUNTIME_HOME="$(getent passwd abc | cut -d: -f6)"

if [ -z "$RUNTIME_HOME" ]; then
    bashio::log.warning "Unable to resolve the abc runtime home; skipping runtime ownership reconciliation"
    exit 0
fi

for managed_path in \
    "$RUNTIME_HOME/.claude" \
    "$RUNTIME_HOME/.claude.json" \
    "$RUNTIME_HOME/.config/Claude" \
    "$RUNTIME_HOME/.codex"; do
    if [ -e "$managed_path" ]; then
        chown -R -- "${RUNTIME_UID}:${RUNTIME_GID}" "$managed_path" \
            || bashio::log.warning "Unable to set effective runtime ownership on $managed_path"
    fi
done
