#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting Social to Mealie"
cd /app || bashio::exit.nok "App directory not found"
/./app/entrypoint.sh node --run start
