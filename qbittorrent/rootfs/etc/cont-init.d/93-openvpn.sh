#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================

declare openvpn_config
declare openvpn_username
declare openvpn_password

QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"

if bashio::config.true 'openvpn_enabled'; then

    bashio::log.info "Configuring openvpn"

    # Get current ip
    curl -s ipecho.net/plain > /currentip

    #####################
    # CONFIGURE OPENVPN #
    #####################

    openvpn_config=$(bashio::config 'openvpn_config')

    cp "/config/openvpn/${openvpn_config}" /etc/openvpn/config.ovpn || bashio::log.error "openvpn config file not found in /config/openvpn/${openvpn_config}"

    openvpn_username=$(bashio::config 'openvpn_username')
    echo "${openvpn_username}" >/etc/openvpn/credentials
    openvpn_password=$(bashio::config 'openvpn_password')
    echo "${openvpn_password}" >>/etc/openvpn/credentials
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

    # WITH CONTAINER BINDING
    #########################
    # If alternative mode enabled, bind container
    if bashio::config.true 'openvpn_alt_mode'; then
        echo "Using container binding"

        # Remove interface
        echo "... deleting previous interface settings"
        sed -i '/Interface/d' "$QBT_CONFIG_FILE"

        # Modify ovpn config
        if grep -q route-nopull /etc/openvpn/config.ovpn; then
            echo "... removing route-nopull from your config.ovpn"
            sed -i '/route-nopull/d' /etc/openvpn/config.ovpn
        fi

        # Exit
        exit 0
    fi

    # WITH INTERFACE BINDING
    #########################
    # Connection with interface binding
    echo "Using interface binding in the qBittorrent app"

    # Define preferences line
    cd /config/qBittorrent/ || exit 1
    LINE=$(sed -n '/Preferences/=' "$QBT_CONFIG_FILE")
    LINE=$((LINE + 1))
    SESSION=$(sed -n '/BitTorrent/=' "$QBT_CONFIG_FILE")

    # If qBittorrent.conf exists
    if [ -f "$QBT_CONFIG_FILE" ]; then
        # Remove previous line and bind tun0
        echo "... deleting previous interface settings"
        sed -i '/Interface/d' "$QBT_CONFIG_FILE"

        # Bind tun0
        echo "... binding tun0 interface in qBittorrent configuration"
        sed -i "$LINE i\Connection\\\Interface=tun0" "$QBT_CONFIG_FILE"
        sed -i "$LINE i\Connection\\\InterfaceName=tun0" "$QBT_CONFIG_FILE"

        if [ "$SESSION" != "" ]; then
            SESSION=$((SESSION + 1))
            sed -i "$SESSION i\Session\\\Interface=tun0" "$QBT_CONFIG_FILE"
            sed -i "$SESSION i\Session\\\InterfaceName=tun0" "$QBT_CONFIG_FILE"
        fi

    else
        bashio::log.error "qBittorrent config file doesn't exist, openvpn must be added manually to qbittorrent options "
        exit 1
    fi

    # Modify ovpn config
    if ! grep -q route-nopull /etc/openvpn/config.ovpn; then
        echo "... adding route-nopull to your config.ovpn"
        sed -i "1a route-nopull" /etc/openvpn/config.ovpn
    fi

else

    ##################
    # REMOVE OPENVPN #
    ##################

    # Ensure no redirection by removing the direction tag
    sed -i '/Interface/d' "$QBT_CONFIG_FILE"
    bashio::log.info "Direct connection without VPN enabled"

fi
