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

bashio::log.info "Adding microsoft edge"
apt-get update
apt-get install --no-install-recommends -y ca-certificates

if [ -z ${EDGE_VERSION+x} ]; then
    EDGE_VERSION=$(curl -sL https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/ \
        | awk -F'(<a href="microsoft-edge-stable_|_amd64.deb\")' '/href=/ {print $2}' | sort --version-sort | tail -1)
fi

curl -o /tmp/edge.deb -L "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_${EDGE_VERSION}_amd64.deb"
dpkg -I /tmp/edge.deb
apt-get install --no-install-recommends -y /tmp/edge.deb

bashio::log.info "Applying edge docker tweaks"
if [ -f /usr/bin/microsoft-edge-stable ]; then
    mv /usr/bin/microsoft-edge-stable /usr/bin/microsoft-edge-real
elif [ -f /usr/bin/microsoft-edge ]; then
    mv /usr/bin/microsoft-edge /usr/bin/microsoft-edge-real
fi
if [ -f /helpers/microsoft-edge-stable ]; then
    mv /helpers/microsoft-edge-stable /usr/bin/
fi

# The wrapper and the real binary must be usable by the desktop user, whose identity
# 20-folders.sh has already settled by the time this runs.
chown "$(id -u abc):$(id -g abc)" /usr/bin/microsoft-edge*
chmod +x /usr/bin/microsoft-edge*
