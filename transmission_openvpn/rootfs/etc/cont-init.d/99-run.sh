#!/usr/bin/bashio

####################
# Export variables #
####################

echo "Exporting variables"
for k in $(bashio::jq "/data/options.json" 'keys | .[]'); do
    bashio::log.blue $k=$(bashio::config $k)
    export $k=$(bashio::config $k)
done

echo ""

bashio::log.info "Starting app"

/./etc/openvpn/start.sh & echo "Starting nginx"

bashio::net.wait_for 9091 localhost 900

bashio::log.info "Ingress ready"

exec nginx

