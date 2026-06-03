#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

############
# TIMEZONE #
############

if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    if [ -f /usr/share/zoneinfo/"$TIMEZONE" ]; then
        ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
        echo "$TIMEZONE" > /etc/timezone
    else
        bashio::log.fatal "$TIMEZONE not found, are you sure it is a valid timezone?"
    fi
fi

###################
# SSL CONFIG v1.0 #
###################

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
    bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"
    #set variables
    CERTFILE="/ssl/$(bashio::config 'certfile')"
    KEYFILE="/ssl/$(bashio::config 'keyfile')"
else
    CERTFILE=""
    KEYFILE=""
fi
export CERTFILE KEYFILE

#################
# NGINX SETTING #
#################

#declare port
#declare certfile
declare ingress_interface
declare ingress_port
#declare keyfile

FB_BASEURL=$(bashio::addon.ingress_entry)
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

############################
# FILEBROWSER CONFIGURATION #
############################

mkdir -p /config /cache

# Copy default config if not existing
if [ ! -f "$FILEBROWSER_CONFIG" ]; then
    cp /home/filebrowser/data/config.yaml "$FILEBROWSER_CONFIG"
fi

# Update existing fields in config using yq
bashio::log.info "Updating FileBrowser config..."

# --- Server ---
bashio::log.info "... base URL set to allow ingress"
BASE_URL=$(bashio::config 'base_url' "${FB_BASEURL:-/}")
yq e -i ".server.baseURL = \"${BASE_URL}\"" "$FILEBROWSER_CONFIG"

# Enable/disable auth methods based on auth_method selection
bashio::log.info "... authentification method set to $AUTH_METHOD"
yq e -i ".auth.methods.noauth = $( [ "$AUTH_METHOD" = "noauth" ]    && echo 'true' || echo 'false' )" "$FILEBROWSER_CONFIG"
yq e -i ".auth.methods.password.enabled = $( [ "$AUTH_METHOD" = "password" ] && echo 'true' || echo 'false' )" "$FILEBROWSER_CONFIG"
yq e -i ".auth.methods.proxy.enabled = $( [ "$AUTH_METHOD" = "proxy" ]    && echo 'true' || echo 'false' )" "$FILEBROWSER_CONFIG"
yq e -i ".auth.methods.oidc.enabled = $( [ "$AUTH_METHOD" = "oidc" ]     && echo 'true' || echo 'false' )" "$FILEBROWSER_CONFIG"

######################
# LAUNCH FILEBROWSER #
######################

# Prevent conflicts
for folders in /etc/services.d /etc/s6-overlay; do
    [[ -d "$folders" ]] && rm -r "$folders"
done

bashio::log.info "Starting..."

cd /home/filebrowser
./filebrowser &
bashio::net.wait_for 8080 localhost 900 || true
bashio::log.info "Started !"
nginx || bashio::log.fatal "Nginx failed"
