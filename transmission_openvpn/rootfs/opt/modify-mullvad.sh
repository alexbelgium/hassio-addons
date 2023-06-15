#!/bin/bash

if bashio::config.has_value "OPENVPN_CUSTOM_PROVIDER"; then
    OVPNLOCATION="$(bashio::config "OPENVPN_CUSTOM_PROVIDER_OVPN_LOCATION")"
    OPENVPN_PROVIDER="${OVPNLOCATION##*/}"
    OPENVPN_PROVIDER="${OPENVPN_PROVIDER%.*}"
    OPENVPN_PROVIDER="${OPENVPN_PROVIDER,,}"
else
    OPENVPN_PROVIDER="mullvad"
fi

echo "Removing IPv6 from mullvad"

echo "pull-filter ignore \"route-ipv6\"" | tee -a "/etc/openvpn/$OPENVPN_PROVIDER/"*.ovpn
echo "pull-filter ignore \"ifconfig-ipv6\"" | tee -a "/etc/openvpn/$OPENVPN_PROVIDER/"*.ovpn
echo "pull-filter ignore \"dhcp-option DNS6\"" | tee -a "/etc/openvpn/$OPENVPN_PROVIDER/"*.ovpn
