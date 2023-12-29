#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

declare openvpn_config
declare openvpn_username
declare openvpn_password

QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"

if bashio::config.true 'openvpn_enabled'; then

    bashio::log.info "----------------------------"
    bashio::log.info "Openvpn enabled, configuring"
    bashio::log.info "----------------------------"

    # Get current ip
    curl -s ipecho.net/plain > /currentip

    # Function to check for files path
    function check_path () {

    # Get variable
    file="$1"

    # Double check exists
    if [ !-f "$file" ]; then
        bashio::warning "$file not found"
        return 1
    fi

    cp "$file" "$file2"

    # Loop through each line of the input file
    while read line
    do
        # Check if the line contains a txt file
        if [[ "$line" =~ \.txt ]] || [[ "$line" =~ \.crt ]]; then
            # Extract the txt file name from the line
            file_name="$(echo "$line" | awk -F' ' '{print $2}')"
            # Check if the txt file exists
            if [ ! -f "$file_name" ]; then
                # Check if the txt file exists in the /config/openvpn/ directory
                if [ -f "/etc/openvpn/custom/${file_name##*/}" ]; then
                    # Append /config/openvpn/ in front of the original txt file in the ovpn file
                    sed -i "s|$file_name|/etc/openvpn/custom/${file_name##*/}|g" "$file"
                    # Print a success message
                    bashio::log.warning "Appended /etc/openvpn/custom/ to ${file_name##*/} in $file"
                else
                    # Print an error message
                    bashio::log.warning "$file_name is referenced in your ovpn file but does not exist in the $TRANSMISSION_HOME/openvpn folder"
                    sleep 5
                fi
            fi
        fi
    done < "$file2"

    rm "$file2"

    # Standardize lf
    dos2unix "$file"
    
    # Correct paths
    sed -i "s=/etc/openvpn=/config/openvpn=g" "$file"

    }

    #####################
    # CONFIGURE OPENVPN #
    #####################

    # If openvpn_config option used
    if bashio::config.has_value "openvpn_config"; then
        openvpn_config=$(bashio::config 'openvpn_config')
        # If file found
        if [ -f /config/openvpn/"$openvpn_config" ]; then
            # If correct type
            if [[ "$openvpn_config" == *".ovpn" ]] || [[ "$openvpn_config" == *".conf" ]]; then
                echo "... configured ovpn file : using /addon_configs/$HOSTNAME/openvpn/$openvpn_config"
                # Check path
                check_path /config/openvpn/"$openvpn_config"
                # Copy potential additional files
                cp /config/openvpn/* /etc/openvpn/
                # Standardize file
                cp /config/openvpn/"${openvpn_config}" /etc/openvpn/config.ovpn
                # Not correct type
            else
                bashio::exit.nok "Configured ovpn file : $openvpn_config is set but does not end by .ovpn ; it can't be used!"
            fi
        else
            bashio::exit.nok "Configured ovpn file : $openvpn_config not found! Are you sure you added it in /addon_configs/$HOSTNAME/openvpn using the Filebrowser addon ?"
        fi

    # If openvpn_config not set, but folder is not empty
    elif [ ! "$(ls -A /config/openvpn/*.ovpn 2>/dev/null)" ]; then
        # Look for openvpn files
        # Wildcard search for openvpn config files and store results in array
        mapfile -t VPN_CONFIGS < <( find /config/openvpn -maxdepth 1 -name "*.ovpn" -print )
        # Choose random config
        VPN_CONFIG="${VPN_CONFIGS[$RANDOM % ${#VPN_CONFIGS[@]}]}"
        # Get the VPN_CONFIG name without the path and extension
        openvpn_config="${VPN_CONFIG##*/}"
        echo "... Openvpn enabled, but openvpn_config option empty. Selecting a random ovpn file : ${openvpn_config}"
        # Check path
        check_path /config/openvpn/"${openvpn_config}"
        # Copy potential additional files
        cp /config/openvpn/* /etc/openvpn/
        # Standardize file
        cp /config/openvpn/"${openvpn_config}" /etc/openvpn/config.ovpn

    # If openvpn_enabled set, config not set, and openvpn folder empty
    else
        bashio::exit.nok "openvpn_enabled is set, however, your openvpn folder is empty ! Are you sure you added it in /addon_configs/$HOSTNAME/openvpn using the Filebrowser addon ?"
    fi

    # Set credentials
    if bashio::config.has_value "openvpn_username"; then
        openvpn_username=$(bashio::config 'openvpn_username')
        echo "${openvpn_username}" >/etc/openvpn/credentials
    else
        bashio::exit.nok "Openvpn is enabled, but openvpn_username option is empty! Exiting"
    fi
    if bashio::config.has_value "openvpn_password"; then
        openvpn_password=$(bashio::config 'openvpn_password')
        echo "${openvpn_password}" >>/etc/openvpn/credentials
    else
        bashio::exit.nok "Openvpn is enabled, but openvpn_password option is empty! Exiting"
    fi

    # Add credentials file
    if grep -q auth-user-pass /etc/openvpn/config.ovpn; then
        sed -i "s/auth-user-pass.*/auth-user-pass \/etc\/openvpn\/credentials/g" /etc/openvpn/config.ovpn
        bashio::log.warning "auth-user-pass specified, will be replaced by the addon options' username and password"
    else
        echo "auth-user-pass /etc/openvpn/credentials" >> /etc/openvpn/config.ovpn
    fi

    # Permissions
    chmod 755 /config/openvpn/*
    chmod 755 /etc/openvpn/*
    chmod 600 /etc/openvpn/credentials
    chmod 755 /etc/openvpn/up.sh
    chmod 755 /etc/openvpn/down.sh
    chmod 755 /etc/openvpn/up-qbittorrent.sh
    chmod +x /etc/openvpn/up.sh
    chmod +x /etc/openvpn/down.sh
    chmod +x /etc/openvpn/up-qbittorrent.sh

    echo "... openvpn correctly set, qbittorrent will run tunnelled through openvpn"

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

    # If qBittorrent.conf exists
    if [ -f "$QBT_CONFIG_FILE" ]; then
        # Remove previous line and bind tun0
        echo "... deleting previous interface settings"
        sed -i '/Interface/d' "$QBT_CONFIG_FILE"

        # Bind tun0
        echo "... binding tun0 interface in qBittorrent configuration"
        sed -i "/\[Preferences\]/ i\Connection\\\Interface=tun0" "$QBT_CONFIG_FILE"
        sed -i "/\[Preferences\]/ i\Connection\\\InterfaceName=tun0" "$QBT_CONFIG_FILE"

        # Add to ongoing session
        sed -i "/\[BitTorrent\]/a \Session\\\Interface=tun0" "$QBT_CONFIG_FILE"
        sed -i "/\[BitTorrent\]/a \Session\\\InterfaceName=tun0" "$QBT_CONFIG_FILE"

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
    if [ -f "$QBT_CONFIG_FILE" ]; then
        sed -i '/Interface/d' "$QBT_CONFIG_FILE"
    fi
    bashio::log.info "Direct connection without VPN enabled"

fi
