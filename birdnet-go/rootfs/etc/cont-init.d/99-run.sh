#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

echo " "

# Check if alsa_card is provided
CONFIG_LOCATION="/config/config.yaml"
if bashio::config.has_value "ALSA_CARD"; then
    alsa_card=$(bashio::config 'ALSA_CARD')
    bashio::log.info "ALSA_CARD option set to $alsa_card"
    bashio::log.info "ALSA_CARD option is set to ${alsa_card}. Please ensure it is the correct card"
    sed -i "s/card:.*/card: ${alsa_card}/g" "$CONFIG_LOCATION"
    yq -i -y ".audio.card = \"${alsa_card}\"" "${CONFIG_FILE}"
fi

# Adjust microphone volume if needed
if command -v amixer > /dev/null 2> /dev/null; then
    current_volume="$(amixer sget Capture | grep -oP '\[\d+%\]' | tr -d '[]%' | head -1 2> /dev/null || echo "100")" || true
    if [[ "$current_volume" -eq 0 ]]; then
        amixer sset Capture 70%
        bashio::log.warning "Microphone was off, volume set to 70%."
    fi || true
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
