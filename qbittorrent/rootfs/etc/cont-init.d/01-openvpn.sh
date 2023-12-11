#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

mkdir -p /config/openvpn
QBT_CONFIG_FILE="/config/qBittorrent/config/qBittorrent.conf"

# Correct openvpn files
if [[ bashio::config "VPN_ENABLED" == "yes" ]] && [[ bashio::config "VPN_TYPE" == "openvpn" ]]; then

    # If there is a config file, add nopull
    if [ -n "$(ls -A /config/openvpn 2>/dev/null)" ]; then
        for file in /config/openvpn/*; do 
        if [ -f "$file" ]; then 
            if ! grep -q route-nopull "$file"; then
                echo "... adding route-nopull to $file"
                sed -i "1a route-nopull" "$file"
            fi
        fi 
        done
    fi

    ip route add 10.0.0.0/8 via 172.30.32.1
    ip route add 192.168.0.0/16 via 172.30.32.1
    ip route add 172.16.0.0/12 via 172.30.32.1
    
else

    # Ensure no redirection by removing the direction tag
    if [ -f "$QBT_CONFIG_FILE" ]; then
        sed -i '/Interface/d' "$QBT_CONFIG_FILE"
    fi
    bashio::log.info "... direct connection without VPN enabled"

fi
