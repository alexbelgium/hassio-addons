#!/usr/bin/with-contenv bashio
# ==============================================================================

declare openvpn_config
declare openvpn_username
declare openvpn_password

if bashio::config.true 'openvpn_enabled'; then

  openvpn_config=$(bashio::config 'openvpn_config')

  cp "/config/openvpn/${openvpn_config}.ovpn" /etc/openvpn/config.ovpn

  openvpn_username=$(bashio::config 'openvpn_username')
  echo "${openvpn_username}" > /etc/openvpn/credentials
  openvpn_password=$(bashio::config 'openvpn_password')
  echo "${openvpn_password}" >> /etc/openvpn/credentials

  sed -i 's/auth-user-pass.*/auth-user-pass \/etc\/openvpn\/credentials/g' /etc/openvpn/config.ovpn

  sed -i "1a\/etc/openvpn/up-transmission.sh \"\${4}\" &\n" /etc/openvpn/up.sh

fi
