#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

##############
# Initialize #
##############

CONFIG_HOME="$(bashio::config "CONFIG_LOCATION")"
CONFIG_HOME="$(dirname "$CONFIG_HOME")"

# Use new config file
if [ ! -f "$CONFIG_HOME/config.env" ]; then
    # Copy default config.env
    cp /templates/config.env "$CONFIG_HOME/"
    chmod 755 "$CONFIG_HOME/config.env"
    bashio::log.warning "A default config.env file was copied to $CONFIG_HOME. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
else
    bashio::log.info "Using existing config.env file in $CONFIG_HOME. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
fi

# Remove erroneous folder named config.env (bug fix for looping issue)
if [ -d "$CONFIG_HOME/config.env" ]; then
    bashio::log.warning "Found directory named config.env, deleting it..."
    rm -rf "$CONFIG_HOME/config.env"                   # Fix: Ensures directory removal even if it exists
    cp /templates/config.env "$CONFIG_HOME/config.env" # Recreate as a valid file
    chmod 755 "$CONFIG_HOME/config.env"
fi

# Copy new file
mkdir -p /data/data
cp "$CONFIG_HOME/config.env" /data/data/

# Permissions
chmod -R 755 "$CONFIG_HOME"

# Export variables
set -a
echo ""
bashio::log.info "Sourcing variables from $CONFIG_HOME/config.env"
cp "$CONFIG_HOME"/config.env /config.env
# Remove previous instance
sed -i "s|export ||g" /config.env
# Add export for non empty lines
sed -i '/\S/s/^/export /' /config.env
# Delete lines starting with #
sed -i '/export #/d' /config.env
# Get variables
# shellcheck source=/dev/null
source /config.env
rm /config.env
set +a

##############
# Launch App #
##############

# Go to folder
cd /data || true

# Fetch commands
CMD_ARGUMENTS="$(bashio::config "CMD_ARGUMENTS")"
IFS=';'
read -ar strarr <<< "$CMD_ARGUMENTS"

# Sanitizes commands
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# Add docker-entrypoint command
for val in "${strarr[@]}"; do
    val="$(trim "$val")"
    echo " "
    bashio::log.info "Starting the app with arguments \"$val\""
    echo " "
    echo "$val" | xargs docker-entrypoint.sh || true
done

bashio::log.info "All actions concluded. Stopping in 10 seconds."
sleep 10
bashio::addon.stop
