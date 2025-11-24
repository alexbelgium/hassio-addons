#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

vpn_openvpn=false
vpn_wireguard=false

if bashio::config.true 'openvpn_enabled'; then
    vpn_openvpn=true
fi

if bashio::config.true 'wireguard_enabled'; then
    vpn_wireguard=true
fi

if [[ "${vpn_openvpn}" != true && "${vpn_wireguard}" != true ]]; then
    # No VPN enabled: remove monitoring service to avoid unnecessary restarts
    rm -rf /etc/services.d/vpn-monitor
fi
