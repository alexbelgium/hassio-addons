#!/usr/bin/bashio

####################
# Export variables #
####################

bashio::log.info "Exporting variables"
for k in $(bashio::jq "/data/options.json" 'keys | .[]'); do
    bashio::log.blue "$k"="$(bashio::config "$k")"
    export "$k"="$(bashio::config "$k")"
done
echo ""

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
