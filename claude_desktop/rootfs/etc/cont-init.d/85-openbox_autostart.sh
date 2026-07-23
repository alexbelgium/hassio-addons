#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# The openbox autostart that actually launches Claude Desktop lives on persistent storage at
# $HOME/.config/openbox/autostart. The base image's init-selkies-config s6-rc oneshot only
# seeds it from /defaults/autostart when the persistent copy is missing ("first run"), so an
# addon upgrade that changes /defaults/autostart (e.g. the --password-store flag) would
# otherwise never reach an existing install's persistent copy.
#
# cont-init.d runs to completion, as root, before any s6-rc service starts (same ordering
# 21-gpu_permissions.sh relies on) — i.e. before init-selkies-config's seed-if-absent check
# and before the RESTART_APP lockdown further down that same oneshot (which can leave the
# persistent file root-owned and chmod 550). Reconciling here, as root, overwrites that
# regardless, so every boot picks up the current /defaults/autostart content; ownership/mode
# is left in the normal abc-writable state that init-selkies-config itself uses when
# RESTART_APP is unset, and re-locked by that oneshot afterward if RESTART_APP is set.
if [ -f /defaults/autostart ]; then
    mkdir -p "$HOME/.config/openbox"
    cp -f /defaults/autostart "$HOME/.config/openbox/autostart"
    chown abc:abc "$HOME/.config/openbox" "$HOME/.config/openbox/autostart"
    chmod 644 "$HOME/.config/openbox/autostart"
    bashio::log.info "Synced $HOME/.config/openbox/autostart from the current addon image"
else
    bashio::log.warning "/defaults/autostart missing; leaving any existing openbox autostart untouched"
fi
