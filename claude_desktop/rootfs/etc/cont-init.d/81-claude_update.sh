#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.true 'auto_update'; then
    bashio::log.info "Checking for Claude Desktop updates..."
    if apt-get update -o Acquire::http::Timeout=10 -o Acquire::https::Timeout=10 &> /dev/null && apt-get install -y --only-upgrade claude-desktop &> /dev/null; then
        bashio::log.info "Claude Desktop version: $(dpkg-query -W -f='${Version}' claude-desktop)"
    else
        bashio::log.warning "Update check failed (offline?), keeping current version"
    fi
fi
