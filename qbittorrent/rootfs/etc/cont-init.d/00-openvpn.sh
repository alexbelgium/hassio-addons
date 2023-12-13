#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

mkdir -p /config/openvpn
QBT_CONFIG_FILE="/config/qBittorrent/config/qBittorrent.conf"

# Ensure no redirection by removing the direction tag
if [ -f "$QBT_CONFIG_FILE" ]; then
    sed -i '/Interface/d' "$QBT_CONFIG_FILE"
fi

# Correct openvpn files
if [[ "$(bashio::config "VPN_ENABLED")" == "yes" ]] && [[ "$(bashio::config "VPN_TYPE")" == "openvpn" ]]; then

    # If there is a config file, remove nopull
    if [ -n "$(ls -A /config/openvpn 2>/dev/null)" ]; then
        for file in /config/openvpn/*.ovpn; do 
        if [ -f "$file" ]; then

            # Remove route-nopull
            if grep -q route-nopull "$file"; then
                echo "... removing route-nopull from $file"
                sed -i "/route-nopull/d" "$file"
            fi

            # Avoid ipv6
            sed -i "/route-ipv6/d" "$file"
            sed -i "/ifconfig-ipv6/d" "$file"
            sed -i "6a pull-filter ignore \"route-ipv6\"" "$file"
            sed -i "6a pull-filter ignore \"ifconfig-ipv6\"" "$file"

            # Correct paths
            sed -i "s=/etc/openvpn=/config/openvpn=g" "$file"

            # Check proto
            if grep -q "proto" "$file"; then
                if [ -f /data/tdp ]; then
                    echo "... proto not found in your ovpn, assuming TDP"
                    sed -i "250a VPN_PROTOCOL=\"udp\"" /etc/cont-init.d/02-vpn.sh
                else
                    echo "... proto not found in your ovpn, assuming UDP"
                fi
            fi
            
        fi
        done
    fi

    # Add iproute
    ip route add 10.0.0.0/8 via 172.30.32.1
    ip route add 192.168.0.0/16 via 172.30.32.1
    ip route add 172.16.0.0/12 via 172.30.32.1

fi
