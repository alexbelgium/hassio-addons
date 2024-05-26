#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

exit 0
if bashio::config.true 'wireguard_enabled'; then

########################################################
# DRAFT : Start wireguard if needed
########################################################

QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"

#################
# SET VARIABLES #
#################

# Ensure single vpn
if bashio::config.true 'openvpn_enabled' && bashio::config.true 'wireguard_enabled'; then
    bashio::log.warning "Both openvpn_enabled and wireguard_enabled are set. Openvpn configuration will be used"
    bashio::addon.option 'wireguard_enabled' false
fi

# Set variables
if bashio::config.true 'wireguard_enabled'; then
    vpn="wireguard"
    vpn_ending=".conf"
    vpn_interface="wg0"
fi

# Permissions
chmod 755 /config/openvpn/*
chmod 755 /config/wireguard/*

#################
# CONFIGURE VPN #
#################

    ############
    # MESSAGES #
    ############

    bashio::log.info "----------------------------"
    bashio::log.info "${vpn} enabled, configuring"
    bashio::log.info "----------------------------"

    # Get current ip
    curl -s ipecho.net/plain >/currentip

    ####################
    # CONFIG SELECTION #
    ####################

    # If openvpn_config option used
    if bashio::config.has_value "openvpn_config"; then
        openvpn_config=$(bashio::config 'openvpn_config')
        # If file found
        if [ -f /config/"${vpn}"/"${openvpn_config}" ]; then
            # If correct type
            if [[ "${openvpn_config}" == *"${vpn_ending}" ]]; then
                echo "... configured config file : using /addon_configs/$HOSTNAME/${vpn}/${openvpn_config}"
            else
                bashio::exit.nok "Configured ${vpn_ending} file : ${openvpn_config} is set but does not end by ${vpn_ending} ; it can't be used!"
            fi
        else
            bashio::exit.nok "Configured ${vpn_ending} file : ${openvpn_config} not found! Are you sure you added it in /addon_configs/$HOSTNAME/${vpn} using the Filebrowser addon ?"
        fi
        # If openvpn_config not set, but folder is not empty
    elif ls /config/"${vpn}"/*"${vpn_ending}" >/dev/null 2>&1; then
        # Look for openvpn files
        # Wildcard search for openvpn config files and store results in array
        mapfile -t VPN_CONFIGS < <(find /config/"${vpn}" -maxdepth 1 -name "*${vpn_ending}" -print)
        # Choose random config
        VPN_CONFIG="${VPN_CONFIGS[$RANDOM % ${#VPN_CONFIGS[@]}]}"
        # Get the VPN_CONFIG name without the path and extension
        openvpn_config="${VPN_CONFIG##*/}"
        echo "... ${vpn} enabled, but openvpn_config option empty. Selecting a random ${vpn_ending} file : ${openvpn_config}. Other available files :"
        printf '%s\n' "${VPN_CONFIGS[@]}"
        # If openvpn_enabled set, config not set, and openvpn folder empty
    else
        bashio::exit.nok "_enabled is set, however, your ${vpn} folder is empty ! Are you sure you added it in /addon_configs/$HOSTNAME/ using the Filebrowser addon ?"
    fi

    # Send to script
    sed -i "s|/config/${vpn}/config${vpn_ending}|/config/${vpn}/${openvpn_config}|g" /etc/s6-overlay/s6-rc.d/svc-qbittorrent/run

    #######################
    # WIREGUARD SPECIFICS #
    #######################

    if [[ "$vpn" == "wireguard" ]]; then
        echo "wireguard"

        # Set interface name
        vpn_interface="${openvpn_config%.*}"

        # Set gateway
        DEFAULT_IPV4_GATEWAY=$(ip -4 route list 0/0 | cut -d ' ' -f 3 | head -n 1)

        # Route WebUI traffic over "$DEFAULT_IPV4_GATEWAY"
        mkdir -p /etc/iproute2/
        echo "8080 webui" >> /etc/iproute2/rt_tables
        if [ -n "$DEFAULT_IPV4_GATEWAY" ]; then
        	# Default
        	ip rule add fwmark 8080 table webui
        	ip route add default via "$DEFAULT_IPV4_GATEWAY" table webui
        	# Look for local networks first
        	ip rule add fwmark 8080 table main suppress_prefixlength 1
        fi

        # Ensure ingress is allowed in allowed_ips
        allowed_ips="$(sed -n "/AllowedIPs/p" /config/wireguard/"${openvpn_config}")"
        allowed_ips="${allowed_ips//*=}"
        # Use comma as separator and read into an array
        IFS=',' read -ra ADDR <<< "$allowed_ips"
        # Initialize an empty array to hold the filtered elements
        filtered=()
        # Loop over the elements
        for i in "${ADDR[@]}" 127.0.0.1 10.0.0.0/8 192.168.0.0/16 172.16.0.0/12 172.30.0.0/16; do
            # If the element does not contain "::", add it to the filtered array
            if [[ $i != *::* ]]; then
                filtered+=("$i")
            fi
        done
        filtered=("$(echo "${filtered[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')")
        # Join the filtered elements with commas and store in a variable
        allowed_ips=$(IFS=', '; echo "${filtered[*]}")
        # Store it in the conf file
        sed -i "/^AllowedIPs/c AllowedIPs=$allowed_ips" /config/wireguard/"${openvpn_config}"

    fi

    ###################
    # Accept local ip #
    ###################

    ip route add 10.0.0.0/8 via 172.30.32.1 || true
    ip route add 192.168.0.0/16 via 172.30.32.1 || true
    ip route add 172.16.0.0/12 via 172.30.32.1 || true
    ip route add 172.30.0.0/16 via 172.30.32.1 || true

    ##################
    # CONFIGURE QBIT #
    ##################

    echo "... $vpn correctly set, qbittorrent will run tunnelled"

    # Connection with interface binding
    echo "Using interface binding in the qBittorrent app"

    # Define preferences line
    cd /config/qBittorrent/ || exit 1

    # If qBittorrent.conf exists
    if [ -f "$QBT_CONFIG_FILE" ]; then
        # Remove previous line and bind tun0
        echo "... deleting previous interface settings"
        sed -i '/Interface/d' "$QBT_CONFIG_FILE"

        # Bind tun0
        echo "... binding ${vpn_interface} interface in qBittorrent configuration"
        sed -i "/\[Preferences\]/ i\Connection\\\Interface=${vpn_interface}" "$QBT_CONFIG_FILE"
        sed -i "/\[Preferences\]/ i\Connection\\\InterfaceName=${vpn_interface}" "$QBT_CONFIG_FILE"

        # Add to ongoing session
        sed -i "/\[BitTorrent\]/a \Session\\\Interface=${vpn_interface}" "$QBT_CONFIG_FILE"
        sed -i "/\[BitTorrent\]/a \Session\\\InterfaceName=${vpn_interface}" "$QBT_CONFIG_FILE"

    else
        bashio::log.error "qBittorrent config file doesn't exist, openvpn must be added manually to qbittorrent options "
        exit 1
    fi

elif ! bashio::config.true 'openvpn_enabled'; then

    ##################
    # REMOVE OPENVPN #
    ##################

    # Ensure no redirection by removing the direction tag
    if [ -f "$QBT_CONFIG_FILE" ]; then
        sed -i '/Interface/d' "$QBT_CONFIG_FILE"
    fi
    bashio::log.info "Direct connection without VPN enabled"

fi
