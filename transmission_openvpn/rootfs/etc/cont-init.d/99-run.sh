#!/usr/bin/bashio

#################
# Update to v3 #
################

if bashio::config.true "TRANSMISSION_V3_UPDATE"; then

    (
        bashio::log.info "Updating transmission to v3"
        bashio::log.warning "If your previous version was v2, remove and add torrents again"

        # see https://github.com/haugene/docker-transmission-openvpn/discussions/1937
        wget -O 976b5901365c5ca1.key "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xa37da909ae70535824d82620976b5901365c5ca1"

        cat > /etc/apt/sources.list.d/transmission.list <<EOF
# Transmission PPA https://launchpad.net/~transmissionbt/+archive/ubuntu/ppa
deb [signed-by=/976b5901365c5ca1.key] http://ppa.launchpad.net/transmissionbt/ppa/ubuntu focal main
#deb-src http://ppa.launchpad.net/transmissionbt/ppa/ubuntu focal main
EOF

        apt-get update -o Dir::Etc::sourcelist="sources.list.d/transmission.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        apt-get install -y transmission-daemon transmission-cli
    ) >/dev/null

fi

####################
# Export variables #
####################

bashio::log.info "Exporting variables"
for k in $(bashio::jq "/data/options.json" 'keys | .[]'); do
    bashio::log.blue "$k"="$(bashio::config "$k")"
    export "$k"="$(bashio::config "$k")"
done
echo ""

###########################
# Correct download folder #
###########################

if [ -f "$TRANSMISSION_HOME"/settings.json ]; then
    echo "Updating variables"
    sed -i "/download-dir/c     \"download-dir\": \"$(bashio::config 'TRANSMISSION_DOWNLOAD_DIR')\"," "$TRANSMISSION_HOME"/settings.json
    sed -i "/incomplete-dir/c     \"incomplete-dir\": \"$(bashio::config 'TRANSMISSION_INCOMPLETE_DIR')\"," "$TRANSMISSION_HOME"/settings.json || true
    sed -i "/watch-dir/c     \"watch-dir\": \"$(bashio::config 'TRANSMISSION_WATCH_DIR')\"" "$TRANSMISSION_HOME"/settings.json || true
fi

###################
# Custom provider #
###################

if bashio::config.true "OPENVPN_CUSTOM_PROVIDER"; then

    OVPNLOCATION="$(bashio::config "OPENVPN_CUSTOM_PROVIDER_OVPN_LOCATION")"
    OPENVPN_PROVIDER="${OVPNLOCATION##*/}"
    OPENVPN_PROVIDER="${OPENVPN_PROVIDER%.*}"
    OPENVPN_PROVIDER="${OPENVPN_PROVIDER,,}"
    bashio::log.info "Custom openvpn provider selected"

    # Check that ovpn file exists
    if [ ! -f "$(bashio::config "OPENVPN_CUSTOM_PROVIDER_OVPN_LOCATION")" ]; then
        bashio::log.fatal "Ovpn file not found at location provided : $OVPNLOCATION"
        exit 1
    fi

    # Copy ovpn file
    echo "Copying ovpn file to proper location"
    mkdir -p /etc/openvpn/"$OPENVPN_PROVIDER"
    cp "$OVPNLOCATION" /etc/openvpn/"$OPENVPN_PROVIDER"/"$OPENVPN_PROVIDER".ovpn

    # Use custom provider
    echo "Exporting variable for custom provider : $OPENVPN_PROVIDER"
    export OPENVPN_PROVIDER="$OPENVPN_PROVIDER"
    export OPENVPN_CONFIG="$OPENVPN_PROVIDER"

else

    bashio::log.info "Custom openvpn provider not selected, the provider $OPENVPN_PROVIDER will be used"

fi

#######################
# Run haugene scripts #
#######################

bashio::log.info "Running userscript"
chmod +x /etc/transmission/userSetup.sh
/./etc/transmission/userSetup.sh
echo ""

bashio::log.info "Starting app"
/./etc/openvpn/start.sh & echo ""

#################
# Allow ingress #
#################

bashio::net.wait_for 9091 localhost 900
bashio::log.info "Ingress ready"
exec nginx
