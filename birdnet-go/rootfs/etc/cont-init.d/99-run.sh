#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

bashio::log.info "ALSA_CARD option is set to $(bashio::config "ALSA_CARD"). If the microphone doesn't work, please adapt it"
echo " "

# Adjust microphone volume if needed
if command -v amixer >/dev/null 2>/dev/null; then
  current_volume="$(amixer sget Capture | grep -oP '\[\d+%\]' | tr -d '[]%' | head -1 2>/dev/null || echo "100")" || true
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
