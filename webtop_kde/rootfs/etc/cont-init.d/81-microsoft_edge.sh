#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Webtop-only. Lives here rather than in the shared 80-configuration.sh so the Selkies startup
# scripts stay identical across claude_desktop, webtop and webtop_kde. It also carries the
# ownership fixup that used to sit in 20-folders.sh, which ran before this install and so
# never had anything to match.

if ! bashio::config.true 'install_ms_edge'; then
    exit 0
fi

# Every step below is bounded and non-fatal. cont-init.d blocks the whole add-on, so an
# unreachable or stalled packages.microsoft.com -- or a Debian mirror having a bad day -- must
# not hang or kill startup: the desktop is useful without Edge, an add-on stuck before Selkies
# starts is not. `set -e` would turn any apt or dpkg hiccup into exactly that, so each command
# is guarded and every failure path warns and exits 0.
edge_giveup() {
    bashio::log.warning "$1; skipping the Microsoft Edge install"
    rm -f /tmp/edge.deb
    exit 0
}

bashio::log.info "Adding microsoft edge"
# -o Acquire::*Timeout bounds the mirror handshake/transfer the same way --max-time bounds curl.
APT_TIMEOUTS=(-o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 -o Acquire::Retries=1)
apt-get "${APT_TIMEOUTS[@]}" update || edge_giveup "apt-get update failed"
apt-get "${APT_TIMEOUTS[@]}" install --no-install-recommends -y ca-certificates \
    || edge_giveup "Installing ca-certificates failed"

EDGE_REPO="https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable"

if [ -z "${EDGE_VERSION+x}" ]; then
    EDGE_VERSION=$(curl -sL --fail --connect-timeout 15 --max-time 120 "$EDGE_REPO/" \
        | awk -F'(<a href="microsoft-edge-stable_|_amd64.deb\")' '/href=/ {print $2}' | sort --version-sort | tail -1 || true)
fi

if [ -z "$EDGE_VERSION" ]; then
    edge_giveup "Could not determine the latest Microsoft Edge version"
fi

curl -o /tmp/edge.deb -L --fail --connect-timeout 15 --max-time 600 \
    "$EDGE_REPO/microsoft-edge-stable_${EDGE_VERSION}_amd64.deb" \
    || edge_giveup "Downloading Microsoft Edge ${EDGE_VERSION} failed"

dpkg -I /tmp/edge.deb || edge_giveup "The downloaded Microsoft Edge package is not a valid .deb"
apt-get "${APT_TIMEOUTS[@]}" install --no-install-recommends -y /tmp/edge.deb \
    || edge_giveup "Installing Microsoft Edge ${EDGE_VERSION} failed"
rm -f /tmp/edge.deb

bashio::log.info "Applying edge docker tweaks"
# Gated on the helper still being in /helpers, which is where the image ships it and where it
# stops being once installed. Without the guard a second run would move the wrapper already
# sitting in /usr/bin aside as "-real" with nothing left to take its place, and Edge would
# stop launching.
if [ -f /helpers/microsoft-edge-stable ]; then
    if [ -f /usr/bin/microsoft-edge-stable ]; then
        mv /usr/bin/microsoft-edge-stable /usr/bin/microsoft-edge-real
    elif [ -f /usr/bin/microsoft-edge ]; then
        mv /usr/bin/microsoft-edge /usr/bin/microsoft-edge-real
    fi
    mv /helpers/microsoft-edge-stable /usr/bin/
fi

# The wrapper and the real binary must be usable by the desktop user, whose identity
# 20-folders.sh has already settled by the time this runs. Guarded against an empty glob:
# without nullglob the literal pattern would reach chown, and `set -e` would then abort
# container startup rather than just skipping a fixup that has nothing to do.
shopt -s nullglob
edge_binaries=(/usr/bin/microsoft-edge*)
shopt -u nullglob
if [ "${#edge_binaries[@]}" -gt 0 ]; then
    chown "$(id -u abc):$(id -g abc)" "${edge_binaries[@]}"
    chmod +x "${edge_binaries[@]}"
else
    bashio::log.warning "Edge install reported success but no /usr/bin/microsoft-edge* binary is present"
fi
