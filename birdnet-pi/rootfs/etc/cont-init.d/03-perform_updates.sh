#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

######################
# CHECK BIRDNET.CONF #
######################

echo " "
bashio::log.info "Updating and checking your BirdNET-Pi instance"

exec "$HOME/BirdNET-Pi/scripts/update_birdnet_snippets.sh"
