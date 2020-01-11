#!/bin/bash

if [ ! -d /config/transmission-openvpn ]; then
  echo "Creating /config/transmission-openvpn"
  mkdir -p /config/transmission-openvpn
  chown -R abc:abc /config/transmission-openvpn
fi

if [ -d /config/transmission-openvpn/openvpn ]; then
  echo "Copying OpenVPN configurations"  
  cp -R /config/transmission-openvpn/openvpn/* /etc/openvpn/
fi

/etc/openvpn/start.sh
