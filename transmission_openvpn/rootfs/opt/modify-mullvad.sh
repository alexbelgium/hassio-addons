#!/bin/bash

echo "Removing IPv6 from mullvad"

echo "pull-filter ignore \"route-ipv6\"" | tee -a "/etc/openvpn/mullvad/"*.ovpn
echo "pull-filter ignore \"ifconfig-ipv6\"" | tee -a "/etc/openvpn/mullvad/"*.ovpn
echo "pull-filter ignore \"dhcp-option DNS6\"" | tee -a "/etc/openvpn/mullvad/"*.ovpn
