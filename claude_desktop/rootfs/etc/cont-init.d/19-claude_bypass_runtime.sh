#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

# Claude Code deliberately refuses bypass-permissions mode when its effective UID is 0.
# The add-on historically defaults PUID to 0, so switch the shared `abc` desktop user to
# an unused non-root UID before storage ownership and Selkies runtime directories are set up.
# Keep abc's configured primary group (commonly group 0) so existing group-based access to
# Home Assistant mounts is preserved. Strict and auto permission modes are unchanged.
if [ "$(bashio::config 'permission_mode')" != "bypass" ]; then
    exit 0
fi

CURRENT_UID="$(id -u abc)"
if [ "$CURRENT_UID" -ne 0 ]; then
    bashio::log.info "Claude bypass runtime already uses non-root UID ${CURRENT_UID}"
    exit 0
fi

find_available_uid() {
    local candidate owner
    for candidate in 1000 911 $(seq 1001 1099); do
        owner="$(getent passwd "$candidate" | cut -d: -f1 || true)"
        if [ -z "$owner" ] || [ "$owner" = "abc" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

TARGET_UID="$(find_available_uid || true)"
if [ -z "$TARGET_UID" ]; then
    bashio::exit.nok "Claude bypass mode requires a non-root runtime user, but no free fallback UID was found"
fi

usermod --uid "$TARGET_UID" abc

if [ "$(id -u abc)" -eq 0 ]; then
    bashio::exit.nok "Unable to switch the Claude Desktop runtime away from root for bypass mode"
fi

mkdir -p /run/s6/container_environment
printf '%s' "$TARGET_UID" > /run/s6/container_environment/CLAUDE_RUNTIME_UID
printf '%s' "$(id -g abc)" > /run/s6/container_environment/CLAUDE_RUNTIME_GID

bashio::log.warning "Claude bypass mode cannot run as root; remapped abc from UID 0 to UID ${TARGET_UID} (GID $(id -g abc))"
