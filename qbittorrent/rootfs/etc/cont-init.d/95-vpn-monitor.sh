#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

if ! bashio::config.true 'openvpn_enabled' && ! bashio::config.true 'wireguard_enabled'; then
    # No VPN enabled: remove monitoring service to avoid unnecessary restarts
    rm -rf /etc/services.d/vpn-monitor
    exit 0
fi

_fetch_public_ip() {
    local resp
    local url
    local urls=(
        "https://icanhazip.com"
        "https://ifconfig.me/ip"
        "https://api64.ipify.org"
        "https://checkip.amazonaws.com"
        "https://domains.google.com/checkip"
        "https://ipinfo.io/ip"
    )
    local shuffled_urls
    mapfile -t shuffled_urls < <(printf "%s\n" "${urls[@]}" | shuf)
    # Loop through the now-randomized list
    for url in "${shuffled_urls[@]}"; do
        resp=$(curl -fsS --max-time 5 "${url}" 2>/dev/null || true)
        resp="${resp//[[:space:]]/}"

        # Validate IPv4 or IPv6
        if [[ "${resp}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "${resp}" =~ ^[0-9a-fA-F:]+$ ]]; then
            printf '%s\n' "${resp}"
            return 0
        fi
    done
    return 1
}

echo "$(_fetch_public_ip || true)" > /currentip
