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

bashio::log.info "Updating FileBrowser config..."

# --- Server (hardcoded values) ---
bashio::log.info "... set server"
yq e -i ".server.port = 8080"            "$FILEBROWSER_CONFIG"
yq e -i ".server.listen = \"0.0.0.0\""  "$FILEBROWSER_CONFIG"
yq e -i ".server.database = \"/config/database.db\"" "$FILEBROWSER_CONFIG"
yq e -i ".server.cacheDir = \"/cache\""  "$FILEBROWSER_CONFIG"

# --- Default user scope / source path ---
bashio::log.info "... set default user scope"
DEFAULT_USER_SCOPE=$(bashio::config 'default_user_scope' '/')

# Validate: must start with /
if [[ "$DEFAULT_USER_SCOPE" != /* ]]; then
    bashio::log.fatal "default_user_scope '${DEFAULT_USER_SCOPE}' is not a valid absolute path (must start with /). Stopping."
    exit 1
fi

# Validate: path must exist
if [ ! -d "$DEFAULT_USER_SCOPE" ]; then
    bashio::log.fatal "default_user_scope '${DEFAULT_USER_SCOPE}' does not exist or is not a directory. Stopping."
    exit 1
fi

bashio::log.info "... set source path and defaultUserScope to ${DEFAULT_USER_SCOPE}"
yq e -i ".server.sources[0].path = \"${DEFAULT_USER_SCOPE}\""  "$FILEBROWSER_CONFIG"
yq e -i ".server.sources[0].name = \"Default\""                "$FILEBROWSER_CONFIG"
yq e -i ".server.sources[0].config.defaultUserScope = \"${DEFAULT_USER_SCOPE}\"" "$FILEBROWSER_CONFIG"

# --- Base URL (from env or config) ---
bashio::log.info "... set base URL to allow ingress"
BASE_URL=$(bashio::config 'base_url' "${FB_BASEURL:-/}")
yq e -i ".server.baseURL = \"${BASE_URL}\"" "$FILEBROWSER_CONFIG"

# --- Auth method ---
AUTH_METHOD=$(bashio::config 'auth_method' 'password')
bashio::log.info "... authentication method set to $AUTH_METHOD"
case "$AUTH_METHOD" in
    noauth)
        yq e -i ".auth.methods.noauth = true"            "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.password.enabled = false" "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.proxy.enabled = false"    "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.oidc.enabled = false"     "$FILEBROWSER_CONFIG"
        ;;
    password)
        yq e -i ".auth.methods.noauth = false"           "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.password.enabled = true"  "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.proxy.enabled = false"    "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.oidc.enabled = false"     "$FILEBROWSER_CONFIG"
        ;;
    proxy)
        yq e -i ".auth.methods.noauth = false"           "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.password.enabled = false" "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.proxy.enabled = true"     "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.oidc.enabled = false"     "$FILEBROWSER_CONFIG"
        ;;
    oidc)
        yq e -i ".auth.methods.noauth = false"           "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.password.enabled = false" "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.proxy.enabled = false"    "$FILEBROWSER_CONFIG"
        yq e -i ".auth.methods.oidc.enabled = true"      "$FILEBROWSER_CONFIG"
        ;;
    *)
        bashio::log.fatal "Unknown auth_method: $AUTH_METHOD"
        ;;
esac

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
