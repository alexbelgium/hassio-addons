#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

if ! bashio::config.true 'openvpn_enabled' && ! bashio::config.true 'wireguard_enabled'; then
    # No VPN enabled: remove proxy service to avoid unnecessary restarts
    rm -rf /etc/services.d/vpn-proxy
    exit 0
fi

if ! bashio::config.true 'vpn_proxy_enabled'; then
    # Proxy not enabled: remove proxy service to avoid unnecessary restarts
    rm -rf /etc/services.d/vpn-proxy
    exit 0
fi
