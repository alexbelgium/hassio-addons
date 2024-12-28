#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

if [[ "$(uname -m)" = "x86_64" && ! grep -q "avx2" /proc/cpuinfo ]]; then
    bashio::log.fatal "❌ Your CPU is x86_64 but doesn't support AVX2. BirdNET-Go requires Intel Haswell (2013) or newer CPU with AVX2 support."
    exit 1
fi

#################
# INITALISATION #
#################

bashio::log.info "ALSA_CARD option is set to $(bashio::config "ALSA_CARD"). If the microphone doesn't work, please adapt it"
echo " "

########################
# CONFIGURE birdnet-go #
########################

bashio::log.info "Starting app..."
COMMAND="$(bashio::config "COMMAND")"
# shellcheck disable=SC2086
/usr/bin/birdnet-go $COMMAND & true

# Wait for app to become available to start nginx
bashio::net.wait_for 8080 localhost 900
bashio::log.info "Starting NGinx..."
exec nginx

