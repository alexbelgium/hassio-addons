#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Claude Desktop is launched with --password-store=basic (see /defaults/autostart) so that no
# system keyring — and therefore no keyring password prompt — is ever needed. Electron does not
# accept that backend unless the application itself calls
# safeStorage.setUsePlainTextEncryption(true), and Claude Desktop never does, so without this
# patch safeStorage.isEncryptionAvailable() stays false: the auth token is never persisted and
# the user is asked to sign in again on every start.
#
# claude-safestorage-patch.js injects that opt-in into the app's main bundle inside app.asar.
# It runs on every boot, and after 81-claude_update.sh, on purpose: an apt upgrade of
# claude-desktop replaces app.asar with a fresh unpatched copy. The patcher is marker-guarded,
# so a boot where the app did not change is a cheap no-op.
#
# A failure here must never block startup — the app still runs fine unpatched, it just forgets
# the sign-in — so the patcher's exit status is reported, not propagated, and it is capped with
# a timeout so a pathological archive cannot stall the boot indefinitely.

ASAR="/usr/lib/claude-desktop/resources/app.asar"
PATCHER="/usr/local/bin/claude-safestorage-patch.js"

if [ ! -f "$ASAR" ]; then
    bashio::log.warning "Claude Desktop app.asar not found; skipping the safeStorage patch"
    exit 0
fi

if [ ! -f "$PATCHER" ]; then
    bashio::log.warning "$PATCHER not found; skipping the safeStorage patch"
    exit 0
fi

if output=$(timeout 120 node "$PATCHER" "$ASAR" 2>&1); then
    bashio::log.info "safeStorage: ${output}"
else
    rc=$?
    if [ "$rc" -eq 124 ]; then
        bashio::log.warning "safeStorage patch timed out after 120s; continuing unpatched."
    else
        bashio::log.warning "safeStorage patch failed (exit ${rc}); the sign-in will not persist."
    fi
    while IFS= read -r line; do
        [ -n "$line" ] && bashio::log.warning "${line}"
    done <<< "${output}"
fi
