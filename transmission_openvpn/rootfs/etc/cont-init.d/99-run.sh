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
