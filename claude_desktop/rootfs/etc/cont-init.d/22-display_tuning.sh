#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Cap the virtual screen the desktop is drawn on.
#
# The Selkies base image starts Xvfb at DEFAULT_RES=15360x8640 so that a client on any monitor
# can resize into it. Nothing here needs a 133-megapixel screen: it enlarges the area Xvfb and
# the Selkies capture loop track for damage on every frame, which the add-on pays for
# continuously — measurably so even with no browser connected at all.
#
# MAX_RES is the base image's own knob for this (svc-xorg prefers it over DEFAULT_RES) and it
# only sets the *maximum*; Selkies still resizes dynamically underneath it, so a smaller cap
# costs nothing until a client actually asks for something larger.
#
# This is a CPU and address-space saving, not a memory one: the framebuffer is a lazily
# populated SysV shared segment, so the unused portion of the oversized screen was never
# resident to begin with.
#
# Note SELKIES_MANUAL_WIDTH/HEIGHT is a different knob that *pins* the resolution and disables
# dynamic resizing. It is deliberately not used here.
MAX_RESOLUTION="$(bashio::config 'max_resolution' '1920x1080')"

if [ -z "$MAX_RESOLUTION" ]; then
    bashio::log.info "max_resolution is empty; leaving the base image's default virtual screen size"
    exit 0
fi

if ! printf '%s' "$MAX_RESOLUTION" | grep -qE '^[0-9]{1,5}x[0-9]{1,5}$'; then
    bashio::log.warning "max_resolution '${MAX_RESOLUTION}' is not WIDTHxHEIGHT; leaving the base image default"
    exit 0
fi

# A syntactically valid but nonsensical size (0x0, 99999x99999) would either stop Xvfb from
# starting at all or ask it for a framebuffer larger than the default this option exists to
# shrink. Bound it to something Xvfb and Selkies can actually serve; the upper bound is the
# base image's own default, so this option can only ever reduce the screen.
MAX_WIDTH="${MAX_RESOLUTION%%x*}"
MAX_HEIGHT="${MAX_RESOLUTION##*x}"
if [ "$MAX_WIDTH" -lt 640 ] || [ "$MAX_HEIGHT" -lt 480 ] ||
    [ "$MAX_WIDTH" -gt 15360 ] || [ "$MAX_HEIGHT" -gt 8640 ]; then
    bashio::log.warning "max_resolution '${MAX_RESOLUTION}' is outside the supported range (640x480 to 15360x8640); leaving the base image default"
    exit 0
fi

# cont-init.d completes before any s6-rc service starts, so svc-xorg picks this up on the same
# boot. Both paths are written because the base image's scripts read the legacy /var/run alias.
for envdir in /var/run/s6/container_environment /run/s6/container_environment; do
    if [ -d "$envdir" ]; then
        printf '%s' "$MAX_RESOLUTION" > "${envdir}/MAX_RES"
    fi
done

bashio::log.info "Virtual screen capped at ${MAX_RESOLUTION} (Selkies still resizes dynamically below this)"
