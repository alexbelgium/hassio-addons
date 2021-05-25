#!/usr/bin/with-contenv bashio
# ==============================================================================

declare openvpn_config
declare openvpn_username
declare openvpn_password

if bashio::config.true 'openvpn_enabled'; then
  
  bashio::log.info "Configuring openvpn"

  #####################
  # CONFIGURE OPENVPN #
  #####################
  
  openvpn_config=$(bashio::config 'openvpn_config')

  cp "/config/openvpn/${openvpn_config}" /etc/openvpn/config.ovpn ||   bashio::log.error "openvpn config file not found in /config/openvpn/${openvpn_config}"

  openvpn_username=$(bashio::config 'openvpn_username')
  echo "${openvpn_username}" > /etc/openvpn/credentials
  openvpn_password=$(bashio::config 'openvpn_password')
  echo "${openvpn_password}" >> /etc/openvpn/credentials
  sed -i 's/auth-user-pass.*/auth-user-pass \/etc\/openvpn\/credentials/g' /etc/openvpn/config.ovpn
  
  # Permissions
  chmod 600 /etc/openvpn/credentials
  chmod 755 /etc/openvpn/up.sh
  chmod 755 /etc/openvpn/down.sh
  chmod 755 /etc/openvpn/up-qbittorrent.sh  
  chmod +x /etc/openvpn/up.sh
  chmod +x /etc/openvpn/up-qbittorrent.sh

  bashio::log.info "openvpn correctly set, qbittorrent will run tunnelled through openvpn"

  #########################
  # CONFIGURE QBITTORRENT #
  #########################
  
  QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
  # Define preferences line
  cd /config/qBittorrent/
  LINE=$(sed -n '/Preferences/=' qBittorrent.conf)
  LINE=$((LINE + 1))
      
  # If qBittorrent.conf exists
  if [ -f "$QBT_CONFIG_FILE" ]; then 
      # Remove previous line and bind tun0
      sed -i '/Interface/d' qBittorrent.conf
      # sed -i '/PortRangeMin/d' qBittorrent.conf     
      # Bind tun0
     # sed -i "$LINE i\Connection\\\Interface=tun0" qBittorrent.conf
     # sed -i "$LINE i\Connection\\\InterfaceName=tun0" qBittorrent.conf
  else
      bashio::log.error "qBittorrent config file doesn't exist, openvpn must be added manually to qbittorrent options "
      exit 1
  fi

  #####################
  # ALTERNATIVE MODE  #
  #####################

  if bashio::config.true 'openvpn_alternative_mode'; then
     # Remove previous line and bind tun0
     sed -i '/Interface/d' qBittorrent.conf
     # Bind tun0
     sed -i "$LINE i\Connection\\\Interface=tun0" qBittorrent.conf
     sed -i "$LINE i\Connection\\\InterfaceName=tun0" qBittorrent.conf
     # Modify ovpn config 
     echo "route-nopull" >> /etc/openvpn/config.ovpn
  fi

else

  ##################
  # REMOVE OPENVPN #
  ##################
  # Ensure no redirection by removing the direction tag
  cd /config/qBittorrent/
  sed -i '/Interface/d' qBittorrent.conf 
  bashio::log.info "Direct connection without VPN enabled"

fi
