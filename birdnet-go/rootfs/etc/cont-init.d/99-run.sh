#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

echo " "

# Check if alsa_card is provided
CONFIG_LOCATION="/config/config.yaml"
if bashio::config.true "homeassistant_microphone"; then
    bashio::log.info "homeassistant_microphone option is selected. The audio card config value is set to 'default'. Set in the addon options to which this is set"
    audio_card="default"
else
    bashio::log.warning "homeassistant_microphone option is not set, disabling microphone input"
    audio_card=""
fi
yq -iy ".realtime.audio.source = \"${audio_card}\"" "$CONFIG_LOCATION"

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
