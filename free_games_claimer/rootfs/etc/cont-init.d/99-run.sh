#!/usr/bin/env bashio
# shellcheck shell=bash

##############
# Initialize #
##############

# Use new config file
CONFIG_HOME="$(bashio::config "CONFIG_LOCATION")"
CONFIG_HOME="$(dirname "$CONFIG_HOME")"
if [ ! -f "$CONFIG_HOME"/config.env ]; then
    # Copy default config.env
    cp /templates/config.env "$CONFIG_HOME"/config.env
    chmod 777 "$CONFIG_HOME"/config.env
    bashio::log.warning "A default config.env file was copied in $CONFIG_HOME. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
else
    bashio::log.warning "The config.env file found in $CONFIG_HOME will be used. Please customize according to https://github.com/vogler/free-games-claimer/tree/main#configuration--options and restart the add-on"
fi

# Copy new file
mkdir -p /data/data
\cp "$CONFIG_HOME"/config.env /data/data/

# Permissions
chmod -R 777 "$CONFIG_HOME"

# Export variables
set -a
cp /./"$CONFIG_HOME"/config.env /config.env
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
# shellcheck disable=SC2162
read -a strarr <<< "$CMD_ARGUMENTS"

# Sanitizes commands
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# Add docker-entrypoint command
# Print each value of the array by using the loop
for val in "${strarr[@]}";
do
  #Removes whitespaces
  val="$(trim "$val")"
  echo " "
  bashio::log.info "Starting the app with arguments \"$val\""
  echo " "
  # shellcheck disable=SC2086
  echo "$val" | xargs docker-entrypoint.sh || true
done

bashio::log.info "All actions concluded, addon will stop in 10 seconds"
sleep 10
bashio::addon.stop
