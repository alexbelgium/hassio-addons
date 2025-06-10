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
    curl -s ipecho.net/plain >/currentip

    # Function to check for files path
    function check_path()  {

        # Get variable
        file="$1"

        # Double check exists
        if [ ! -f "$file" ]; then
            bashio::warning "$file not found"
            return 1
    fi

        # Check each lines
        cp "$file" /tmpfile
        line_number=0
        while read -r line; do
            # Increment the line number
            ((line_number = line_number + 1))

            # Check if lines starting with auth-user-pass have a valid argument
            ###################################################################
            if [[ $line == "auth-user-pass"*   ]]; then
                # Extract the second argument
                file_name="$(echo "$line" | awk -F' ' '{print $2}')"
                # If second argument is null or -
                if [ -z "$file_name" ] || [[ $file_name == -*   ]]; then
                    # Insert to explain why a comment is made
                    sed -i "${line_number}i # The following line is commented out as does not contain a valid argument" "$file"
                    # Increment as new line added
                    ((line_number = line_number + 1))
                    # Comment out the line
                    sed -i "${line_number}s/^/# /" "$file"
                    # Go to next line
                    continue
        fi
      fi

            # Check if the line contains a txt file
            #######################################
            if [[ ! $line =~ ^"#" ]] && [[ ! $line =~ ^";" ]] && [[ $line == *" "*"."*   ]] || [[ $line == "auth-user-pass"*   ]]; then
                # Extract the txt file name from the line
                file_name="$(echo "$line" | awk -F' ' '{print $2}')"
                # if contains only numbers and dots it is likely an ip, don't check it
                if [[ $file_name =~ ^[0-9\.]+$   ]]; then
                    continue
        fi
                # Check if the txt file exists
                if [[ $file_name != *"/etc/openvpn/credentials"*   ]] && [ ! -f "$file_name" ]; then
                    # Check if the txt file exists in the /config/openvpn/ directory
                    if [ -f "/config/openvpn/${file_name##*/}" ]; then
                        # Append /config/openvpn/ in front of the original txt file in the ovpn file
                        sed -i "${line_number}s|$file_name|/config/openvpn/${file_name##*/}|" "$file"
                        # Print a success message
                        bashio::log.warning "Appended /config/openvpn/ to ${file_name##*/} in $file"
          else
                        # Print an error message
                        bashio::log.warning "$file_name is referenced in your ovpn file but does not exist, and can't be found either in the /config/openvpn/ directory"
          fi
        fi
      fi
    done     </tmpfile
        rm /tmpfile

        # Standardize lf
        dos2unix "$file"

        # Remove custom up & down
        sed -i '/^up /s/^/#/' "$file"
        sed -i '/^down /s/^/#/' "$file"

        # Remove blank lines
        sed -i '/^[[:blank:]]*$/d' "$file"

        # Ensure config ends with a line feed
        sed -i '$q'  "$file"

        # Correct paths
        sed -i "s=/etc/openvpn=/config/openvpn=g" "$file"
        sed -i "s=/config/openvpn/credentials=/etc/openvpn/credentials=g" "$file"

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
            if [[ $openvpn_config == *".ovpn"   ]] || [[ $openvpn_config == *".conf"   ]]; then
                echo "... configured ovpn file : using /addon_configs/$HOSTNAME/openvpn/$openvpn_config"
      else
                bashio::exit.nok "Configured ovpn file : $openvpn_config is set but does not end by .ovpn ; it can't be used!"
      fi
    else
            bashio::exit.nok "Configured ovpn file : $openvpn_config not found! Are you sure you added it in /addon_configs/$HOSTNAME/openvpn using the Filebrowser addon ?"
    fi

        # If openvpn_config not set, but folder is not empty
  elif   ls /config/openvpn/*.ovpn >/dev/null  2>&1; then
        # Look for openvpn files
        # Wildcard search for openvpn config files and store results in array
        mapfile -t VPN_CONFIGS < <( find /config/openvpn -maxdepth 1 -name "*.ovpn" -print)
        # Choose random config
        VPN_CONFIG="${VPN_CONFIGS[RANDOM % ${#VPN_CONFIGS[@]}]}"
        # Get the VPN_CONFIG name without the path and extension
        openvpn_config="${VPN_CONFIG##*/}"
        echo "... Openvpn enabled, but openvpn_config option empty. Selecting a random ovpn file : ${openvpn_config}. Other available files :"
        printf '%s\n' "${VPN_CONFIGS[@]}"
        # If openvpn_enabled set, config not set, and openvpn folder empty
  else
        bashio::exit.nok "openvpn_enabled is set, however, your openvpn folder is empty ! Are you sure you added it in /addon_configs/$HOSTNAME/openvpn using the Filebrowser addon ?"
  fi

    # Send to openvpn script
    sed -i "s|/config/openvpn/config.ovpn|/config/openvpn/$openvpn_config|g" /etc/s6-overlay/s6-rc.d/svc-qbittorrent/run

    # Check path
    check_path /config/openvpn/"${openvpn_config}"

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
    if grep -q ^auth-user-pass /config/openvpn/"$openvpn_config"; then
        # Credentials specified are they custom ?
        file_name="$(sed -n "/^auth-user-pass/p" /config/openvpn/"$openvpn_config" | awk -F' ' '{print $2}')"
        file_name="${file_name:-null}"
        if [[ $file_name != *"/etc/openvpn/credentials"*   ]] && [[ $file_name != "null"   ]]; then
            if [ -f "$file_name" ]; then
                # If credential specified, exists, and is not the addon default
                bashio::log.warning "auth-user-pass specified in the ovpn file, addon username and passwords won't be used !"
      else
                # Credential referenced but doesn't exist
                bashio::log.warning "auth-user-pass $file_name is referenced in your ovpn file but does not exist, and can't be found either in the /config/openvpn/ directory. The addon will attempt to use it's own username and password instead."
                # Comment previous lines
                sed -i '/^auth-user-pass/i # specified auth-user-pass file not found, disabling' /config/openvpn/"$openvpn_config"
                sed -i '/^auth-user-pass/s/^/#/' /config/openvpn/"$openvpn_config"
                # No credentials specified, using addons username and password
                echo "# Please do not remove the line below, it allows using the addon username and password" >>/config/openvpn/"$openvpn_config"
                echo "auth-user-pass /etc/openvpn/credentials" >>/etc/openvpn/"$openvpn_config"
      fi
    else
            # Standardize just to be sure
            sed -i "/\/etc\/openvpn\/credentials/c auth-user-pass \/etc\/openvpn\/credentials" /config/openvpn/"$openvpn_config"
    fi
  else
        # No credentials specified, using addons username and password
        echo "# Please do not remove the line below, it allows using the addon username and password" >>/config/openvpn/"$openvpn_config"
        echo "auth-user-pass /etc/openvpn/credentials" >>/config/openvpn/"$openvpn_config"
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
        if grep -q route-nopull /config/openvpn/"$openvpn_config"; then
            echo "... removing route-nopull from your config.ovpn"
            sed -i '/route-nopull/d' /config/openvpn/"$openvpn_config"
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
    if ! grep -q route-nopull  /config/openvpn/"$openvpn_config"; then
        echo "... adding route-nopull to your config.ovpn"
        sed -i "1a route-nopull"  /config/openvpn/"$openvpn_config"
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
