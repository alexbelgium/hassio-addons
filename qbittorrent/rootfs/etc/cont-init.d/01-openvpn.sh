#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

mkdir -p /config/openvpn

if [ -d /config/openvpn ]; then
  if [ -n "$(ls -A /config/openvpn 2>/dev/null)" ]; then
    # Modify ovpn config
    if ! grep -q route-nopull /etc/openvpn/config.ovpn; then
        echo "... adding route-nopull to your config.ovpn"
        sed -i "1a route-nopull" /etc/openvpn/config.ovpn
    fi
  fi
fi
