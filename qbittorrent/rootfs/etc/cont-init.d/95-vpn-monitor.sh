#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

if ! bashio::config.true 'openvpn_enabled' && ! bashio::config.true 'wireguard_enabled'; then
    # No VPN enabled: remove monitoring service to avoid unnecessary restarts
    rm -rf /etc/services.d/vpn-monitor
fi
