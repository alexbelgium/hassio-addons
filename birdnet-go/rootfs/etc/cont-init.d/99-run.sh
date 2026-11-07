#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

echo " "

# Allow advanced users to supply their own ALSA config (e.g. to enable JACK
# or a custom dsnoop chain) by dropping asound.conf into the addon config
# folder. Written to /root/.asoundrc because /etc/asound.conf is read-only.
#if [ -f /config/asound.conf ]; then
#    if [ -r /config/asound.conf ]; then
#        bashio::log.info "Using user-provided /config/asound.conf, overriding addon defaults"
#        if ! cp /config/asound.conf /root/.asoundrc; then
#            bashio::log.warning "Failed to copy /config/asound.conf; continuing with bundled /root/.asoundrc defaults"
#        fi
#    else
#        bashio::log.warning "/config/asound.conf exists but is not readable; continuing with bundled /root/.asoundrc defaults"
#    fi
#fi

# Check if alsa_card is provided
CONFIG_LOCATION="/config/config.yaml"
if bashio::config.true "homeassistant_microphone"; then
    bashio::log.info "homeassistant_microphone option is selected. The audio card config value is set to 'default'. Set in the addon options to which this is set"
    audio_card="default"
    yq -iy ".realtime.audio.source = \"${audio_card}\"" "$CONFIG_LOCATION"
else
    bashio::log.info "homeassistant_microphone option is not set, keeping audio source configured via the UI"
fi

########################
# CONFIGURE birdnet-go #
########################

bashio::log.info "Starting app..."
# shellcheck disable=SC2086
/usr/bin/entrypoint.sh /usr/bin/startup-wrapper.sh birdnet-go realtime &
true

# Wait for app to become available to start nginx
bashio::net.wait_for 8080 localhost 900
bashio::log.info "Starting NGinx..."
exec nginx
