#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Packages installed from their vendors' apt repos (see Dockerfile), so the add-on
# keeps the latest release between image rebuilds.
packages="claude-desktop claude-code gh"

bashio::log.info "Checking for Claude Desktop, Claude Code and GitHub CLI updates..."
# shellcheck disable=SC2086
if apt-get update -o Acquire::http::Timeout=10 -o Acquire::https::Timeout=10 &> /dev/null && apt-get install -y --only-upgrade $packages &> /dev/null; then
    # shellcheck disable=SC2086
    bashio::log.info "Versions: $(dpkg-query -W -f='${Package} ${Version}  ' $packages)"
else
    bashio::log.warning "Update check failed (offline?), keeping current versions"
fi
