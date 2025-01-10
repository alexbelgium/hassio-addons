#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155

#############
# STRUCTURE #
#############

# Define variables
DATA_LOCATION="$(bashio::config "DATA_LOCATION")"
DATA_LOCATION="${DATA_LOCATION%/}"
bashio::log.info "Data is stored in $DATA_LOCATION"
DATA_LOCATION_FILE="/data/oldwebtreeshome"

# Create folders
mkdir -p "$DATA_LOCATION"
mkdir -p /config/modules_v4
cp -rn /var2/www/webtrees/data/* "$DATA_LOCATION"/ &>/dev/null || true
cp -rn /var2/www/webtrees/data/.* "$DATA_LOCATION"/ &>/dev/null || true
cp -rn /var2/www/webtrees/modules_v4/* /config/modules_v4/ &>/dev/null || true

# Check if a migration is needed
if bashio::fs.file_exists "$DATA_LOCATION_FILE"; then
    DATA_LOCATION_CURRENT="$(cat "$DATA_LOCATION_FILE")"
    DATA_LOCATION_CURRENT="${DATA_LOCATION_CURRENT%/}"
elif [[ -d /share/webtrees ]] && [[ "$(ls -A /share/webtrees)" ]]; then
    DATA_LOCATION_CURRENT="/share/webtrees"
else
    DATA_LOCATION_CURRENT="$DATA_LOCATION"
fi

# Migrate files
if [[ "$DATA_LOCATION_CURRENT" != "$DATA_LOCATION" ]] && [[ "$(ls -A "$DATA_LOCATION_CURRENT")" ]]; then
    bashio::log.warning "Data location was changed from $DATA_LOCATION_CURRENT to $DATA_LOCATION, migrating files"
    cp -rnf "$DATA_LOCATION_CURRENT"/* "$DATA_LOCATION"/ &>/dev/null || true
    echo "Files moved to $DATA_LOCATION" > "$DATA_LOCATION_CURRENT"/migrated
    mv "$DATA_LOCATION_CURRENT" "${DATA_LOCATION_CURRENT}_migrated"
fi

# Saving data location
echo "... using data folder $DATA_LOCATION"
echo -n "$DATA_LOCATION" > "$DATA_LOCATION_FILE"

# Update entrypoint
sed -i "s|DATA_DIR = os.path.join(ROOT, \"data\")|DATA_DIR = \"$DATA_LOCATION\"|" /docker-entrypoint.py

# Creating symlinks
echo "... creating symlinks"
rm -r /var2/www/webtrees/data
ln -sf "$DATA_LOCATION" /var2/www/webtrees/data
rm -r /var2/www/webtrees/modules_v4
ln -sf "/config/modules_v4" /var2/www/webtrees/modules_v4

# Update permissions on target directories
echo "... update permissions"
chown -R www-data:www-data "$DATA_LOCATION"
chmod -R 755 "$DATA_LOCATION"
chown -R www-data:www-data "/config"
chmod -R 755 "/config"

# Remove /data/data
if [[ -d "$DATA_LOCATION"/data ]] && [[ "$(ls -A "$DATA_LOCATION"/data/*)" ]]; then
  mv "$DATA_LOCATION"/data/* "$DATA_LOCATION"/
  rm -r "$DATA_LOCATION"/data
fi

################
# SSL CONFIG   #
################

BASE_URL=$(bashio::config 'BASE_URL')
# Remove the http
BASE_URL="${BASE_URL#*//}"
# Remove the port
BASE_URL="${BASE_URL%%:*}"

bashio::config.require.ssl
if bashio::config.true 'ssl'; then

    #set variables
    CERTFILE=$(bashio::config 'certfile')
    KEYFILE=$(bashio::config 'keyfile')

    #Replace variables
    export SSL_CERT_FILE="/ssl/$CERTFILE"
    export SSL_CERT_KEY_FILE="/ssl/$KEYFILE"

    #Send env variables
    export HTTPS=true
    export SSL=true
    export HTTPS_REDIRECT=true
    BASE_URL_PORT=":$(bashio::addon.port 443)"
    if [[ "$BASE_URL_PORT" == ":443" ]]; then BASE_URL_PORT=""; fi
    BASE_URL_PROTO="https"

    #Communication
    bashio::log.info "Ssl enabled. If webui don't work, check if the port 443 was opened in the addon options, disable ssl or check your certificate paths"
else
    export HTTPS=false
    export SSL=false
    export HTTPS_REDIRECT=false
    BASE_URL_PORT=":$(bashio::addon.port 80)"
    if [[ "$BASE_URL_PORT" == ":80" ]]; then BASE_URL_PORT=""; fi
    BASE_URL_PROTO="http"
fi

if [[ "$BASE_URL_PORT" == ":" ]]; then
    bashio::log.fatal "Your $BASE_URL_PROTO port is not set in the addon options, please check your configuration and restart"
    bashio::addon.stop
fi
BASE_URL="${BASE_URL_PROTO}://${BASE_URL}${BASE_URL_PORT}"
export BASE_URL

# CLOUDFLARE
if bashio::config.true "base_url_portless"; then
    export BASE_URL=$(bashio::config 'BASE_URL')
fi

# Correct base url if needed
echo "... align base url with latest addon value"
if [ -f "$DATA_LOCATION"/config.ini.php ]; then
    echo "Aligning base_url addon config"
    LINE=$(sed -n '/base_url/=' "$DATA_LOCATION"/config.ini.php)
    sed -i "$LINE a base_url=\"$BASE_URL\"" "$DATA_LOCATION"/config.ini.php
    sed -i "$LINE d" "$DATA_LOCATION"/config.ini.php
fi || true

##############
# LAUNCH APP #
##############

bashio::log.info "Launching app, please wait"

###################
# TRUSTED HEADERS #
###################

if bashio::config.has_value "trusted_headers" && [ -f "$DATA_LOCATION"/config.ini.php ]; then
    bashio::log.info "Aligning trusted_headers addon config (use single address, or a range of addresses in CIDR format)"
    sed -i "/trusted_headers/ d" "$DATA_LOCATION"/config.ini.php
    sed -i "1a trusted_headers=\"$(bashio::config 'trusted_headers')\"" "$DATA_LOCATION"/config.ini.php
elif [ -f "$DATA_LOCATION"/config.ini.php ]; then
    bashio::log.info "Aligning trusted_headers addon config with cf-connecting-ip"
    sed -i "/trusted_headers/ d" "$DATA_LOCATION"/config.ini.php
    sed -i "1a trusted_headers=\"cf-connecting-ip\"" "$DATA_LOCATION"/config.ini.php
fi

############
# END INFO #
############

# Execute main script
# shellcheck ignore=SC1091
source /etc/apache2/envvars
echo "Adapting start script"
cd /var2/www/webtrees || exit 1
chmod +x /etc/scripts/launcher.sh
sed -i "s|%%data_location%%|${DATA_LOCATION}|g" /etc/scripts/launcher.sh
sed -i "s|%%base_url%%|${BASE_URL}|g" /etc/scripts/launcher.sh
sed -i "/Starting Apache/a\    subprocess.run('/usr/lib/bashio/bashio /etc/scripts/launcher.sh', shell=True, check=True)" /docker-entrypoint.py

bashio::log.info "Starting docker-entrypoint.py"
python3 /docker-entrypoint.py
