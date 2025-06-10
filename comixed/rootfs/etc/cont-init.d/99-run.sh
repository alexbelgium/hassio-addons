#!/usr/bin/env bashio
# shellcheck shell=bash

############
# TIMEZONE #
############

if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    if [ -f /usr/share/zoneinfo/"$TIMEZONE" ]; then
        ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
        echo "$TIMEZONE" >/etc/timezone
  else
        bashio::log.fatal "$TIMEZONE not found, are you sure it is a valid timezone?"
  fi
fi

#################
# NGINX SETTING #
#################

INGRESS="false"
if [[ $INGRESS == "true"   ]]; then
    #declare port
    #declare certfile
    declare ingress_interface
    declare ingress_port
    #declare keyfile

    FB_BASEURL="$(bashio::addon.ingress_entry)"
    export FB_BASEURL

    declare ADDON_PROTOCOL=http
    # Generate Ingress configuration
    if bashio::config.true 'ssl'; then
        ADDON_PROTOCOL=https
  fi

    #port=$(bashio::addon.port 80)
    ingress_port=$(bashio::addon.ingress_port)
    ingress_interface=$(bashio::addon.ip_address)
    sed -i "s|%%protocol%%|${ADDON_PROTOCOL}|g" /etc/nginx/servers/ingress.conf
    sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
    sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
    sed -i "s|%%subpath%%|${FB_BASEURL}/|g" /etc/nginx/servers/ingress.conf
    mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

    # Correct baseurl
    for file in /config/hypercorn.toml $(find /usr -name hypercorn.toml.default); do
        if [ -f "$file" ]; then
            sed -i "/root_path/d" "$file"
            sed -i "1a root_path = \"${FB_BASEURL}\"" "$file"
    fi
  done
fi

###########
# FOLDERS #
###########

echo "Create structure"
mkdir -p /config/comic_data
mkdir -p /config/library
mkdir -p /config/imports
mkdir -p /config/database
ln -sf /config/comic_data /comic_data
ln -sf /config/library /library
ln -sf /config/imports /imports
ln -sf /config/database /root/.comixed

##############
# LAUNCH APP #
##############

bashio::log.warning "When run for the first time, ComiXed creates two default accounts for logging into the system:"
bashio::log.warning "Username: comixedadmin@localhost Password: comixedadmin"
bashio::log.warning "Username: comixedreader@localhost Password: comixedreader"

bashio::log.info "Starting..."

# shellcheck disable=SC2086
/./app/"$(find /app -type d -name 'comixed-release*' | head -n 1)"/bin/run.sh -L /config/comixed.log

#& true
#bashio::net.wait_for 7171 localhost 900 || true
#bashio::log.info "Started !"
#exec nginx
