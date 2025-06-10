#!/usr/bin/bashio
# shellcheck shell=bash

####################
# Export variables #
####################

bashio::log.info "Exporting variables"
for k in $(bashio::jq "/data/options.json" 'keys | .[]'); do
    bashio::log.blue "$k"="$(bashio::config "$k")"
    export "$k"="$(bashio::config "$k")"
done
echo ""

mkdir -p "$TRANSMISSION_HOME"/openvpn

###########################
# Correct download folder #
###########################

if [ -f "$TRANSMISSION_HOME"/settings.json ]; then
    echo "Updating variables"
    sed -i "/download-dir/c     \"download-dir\": \"$(bashio::config 'TRANSMISSION_DOWNLOAD_DIR')\"," "$TRANSMISSION_HOME"/settings.json
    if bashio::config.has_value 'TRANSMISSION_INCOMPLETE_DIR'; then
        sed -i "/\"incomplete-dir\"/c     \"incomplete-dir\": \"$(bashio::config 'TRANSMISSION_INCOMPLETE_DIR')\"," "$TRANSMISSION_HOME"/settings.json || true
        sed -i "/\"incomplete-dir-enabled\"/c     \"incomplete-dir-enabled\": true," "$TRANSMISSION_HOME"/settings.json || true
  fi
    sed -i "/watch-dir/c     \"watch-dir\": \"$(bashio::config 'TRANSMISSION_WATCH_DIR')\"," "$TRANSMISSION_HOME"/settings.json || true
    sed -i.bak ':begin;$!N;s/,\n}/\n}/g;tbegin;P;D' "$TRANSMISSION_HOME"/settings.json
fi

#######################
# Correct permissions #
#######################

# Get variables
DOWNLOAD_DIR="$(bashio::config 'TRANSMISSION_DOWNLOAD_DIR')"
INCOMPLETE_DIR="$(bashio::config 'TRANSMISSION_INCOMPLETE_DIR')"
WATCH_DIR="$(bashio::config 'TRANSMISSION_WATCH_DIR')"
TRANSMISSION_HOME="$(bashio::config 'TRANSMISSION_HOME')"

# Get id
if bashio::config.has_value 'PUID' && bashio::config.has_value 'PGID'; then
    echo "Using PUID $(bashio::config 'PUID') and PGID $(bashio::config 'PGID')"
    PUID="$(bashio::config 'PUID')"
    PGID="$(bashio::config 'PGID')"
else
    PUID="$(id -u)"
    PGID="$(id -g)"
fi

# Update permissions
for folder in "$DOWNLOAD_DIR" "$INCOMPLETE_DIR" "$WATCH_DIR" "$TRANSMISSION_HOME"; do
    mkdir -p "$folder"
    chown -R "$PUID:$PGID" "$folder"
done

###################
# Custom provider #
###################

# Migrate OPENVPN_CUSTOM_PROVIDER to OPENVPN_PROVIDER
if bashio::config.true 'OPENVPN_CUSTOM_PROVIDER'; then
    # Use new option
    bashio::addon.option "OPENVPN_PROVIDER" "custom"
    # Remove previous option
    bashio::addon.option "OPENVPN_CUSTOM_PROVIDER"
    # log
    bashio::log.yellow "OPENVPN_CUSTOM_PROVIDER actived, OPENVPN_PROVIDER set to custom"
    # Restart
    bashio::addon.restart
fi

# Function to check for files path
function check_path()  {

    # Get variable
    file="$1"

    # Double check exists
    if [ ! -f "$file" ]; then
        bashio::warning "$file not found"
        return 1
  fi

    cp "$file" /tmpfile

    # Loop through each line of the input file
    while read -r line; do
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
  done   </tmpfile

    rm /tmpfile

    # Ensure config ends with a line feed
    sed -i "\$q" "$file"

}

# Define custom file
if [ "$(bashio::config "OPENVPN_PROVIDER")" == "custom" ]; then

    # Validate ovpn file
    openvpn_config="$(bashio::config "OPENVPN_CONFIG")"

    # If contains *.ovpn, clean option
    if [[ "$openvpn_config" == *".ovpn" ]]; then
        bashio::log.warning "OPENVPN_CONFIG should not end by ovpn, correcting"
        bashio::addon.option 'OPENVPN_CONFIG' "${openvpn_config%.ovpn}"
        bashio::addon.restart
  fi

    # Add ovpn
    openvpn_config="${openvpn_config}.ovpn"

    # log
    bashio::log.info "OPENVPN_PROVDER set to custom, will use the openvpn file OPENVPN_CONFIG : $openvpn_config"

    # If file found
    if [ -f "$TRANSMISSION_HOME"/openvpn/"$openvpn_config" ]; then
        echo "... configured ovpn file : using $TRANSMISSION_HOME/openvpn/$openvpn_config"
        # Copy files
        rm -r /etc/openvpn/custom
        # Symlink folder
        echo "... symlink the $TRANSMISSION_HOME/openvpn foplder to /etc/openvpn/custom"
        ln -s "$TRANSMISSION_HOME"/openvpn /etc/openvpn/custom
        # Check path
        check_path /etc/openvpn/custom/"$openvpn_config"
  else
        bashio::exit.nok "Configured ovpn file : $openvpn_config not found! Are you sure you added it in $TRANSMISSION_HOME/openvpn ?"
  fi

else

    bashio::log.info "Custom openvpn provider not selected, the provider $OPENVPN_PROVIDER will be used"

fi

###################
# Accept local ip #
###################

ip route add 10.0.0.0/8 via 172.30.32.1
ip route add 192.168.0.0/16 via 172.30.32.1
ip route add 172.16.0.0/12 via 172.30.32.1
ip route add 172.30.0.0/16 via 172.30.32.1

################
# Auto restart #
################

if bashio::config.true 'auto_restart'; then

    bashio::log.info "Auto restarting addon if openvpn down"
    (
     set -o posix
                   export -p
  )                           >/env.sh
    chmod 777 /env.sh
    chmod +x /usr/bin/restart_addon
    sed -i "1a . /env.sh; /usr/bin/restart_addon >/proc/1/fd/1 2>/proc/1/fd/2" /etc/openvpn/tunnelDown.sh

fi

if [ -f /data/addonrestarted ]; then
    bashio::log.warning "Warning, transmission had failed and the addon has self-rebooted as 'auto_restart' option was on. Please check that it is still running"
    rm /data/addonrestarted
fi

#######################
# Run haugene scripts #
#######################

bashio::log.info "Running userscript"
chmod +x /etc/transmission/userSetup.sh
/./etc/transmission/userSetup.sh
echo ""

# Correct mullvad
if [ "$(bashio::config "OPENVPN_PROVIDER")" == "mullvad" ]; then
    bashio::log.info "Mullvad selected, copying script for IPv6 disabling"
    chown "$PUID:$PGID"  /opt/modify-mullvad.sh
    chmod +x  /opt/modify-mullvad.sh
    sed -i '$i/opt/modify-mullvad.sh' /etc/openvpn/start.sh
fi

bashio::log.info "Starting app"
/./etc/openvpn/start.sh &
                          echo ""

#################
# Allow ingress #
#################

bashio::net.wait_for 9091 localhost 900
bashio::log.info "Ingress ready"
exec nginx
