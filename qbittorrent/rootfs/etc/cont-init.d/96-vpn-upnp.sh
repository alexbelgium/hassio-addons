#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

if ! bashio::config.true 'openvpn_enabled' && ! bashio::config.true 'wireguard_enabled'; then
    # No VPN enabled: remove UPnP service to avoid unnecessary restarts
    rm -rf /etc/services.d/vpn-upnp
    exit 0
fi

if ! bashio::config.true 'vpn_upnp_enabled'; then
    # UPnP not enabled: remove UPnP service to avoid unnecessary restarts
    rm -rf /etc/services.d/vpn-upnp
    exit 0
fi
