#!/usr/bin/bashio

if [ ! -d /config/transmission-openvpn ]; then
  echo "Creating /config/transmission-openvpn"
  mkdir -p /config/transmission-openvpn
  chown -R abc:abc /config/transmission-openvpn
fi

if [ -d /config/transmission-openvpn/openvpn ]; then
  echo "Copying OpenVPN configurations"  
  cp -R /config/transmission-openvpn/openvpn/* /etc/openvpn/
fi

for k in $(bashio::jq "${__BASHIO_ADDON_CONFIG}" 'keys | .[]'); do
    export $k="$(bashio::config $k)"
done

/etc/openvpn/start.sh
