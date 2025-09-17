#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

echo " "

# Check if alsa_card is provided
CONFIG_LOCATION="/config/config.yaml"
if bashio::config.has_value "audio_card"; then
    audio_card=$(bashio::config 'audio_card')
    bashio::log.info "Audio card set to ${audio_card} if you use an USB card. This overwrites your value already set in your config. Please use 'default' when possible, and set in the addon options to which this 'default' device is set"
    yq -iy ".realtime.audio.source = \"${audio_card}\"" "$CONFIG_LOCATION"
fi

########################
# CONFIGURE birdnet-go #
########################

bashio::log.info "Starting app..."
# shellcheck disable=SC2086
/usr/bin/entrypoint.sh birdnet-go realtime &
true

# Wait for app to become available to start nginx
bashio::net.wait_for 8080 localhost 900
bashio::log.info "Starting NGinx..."
exec nginx
