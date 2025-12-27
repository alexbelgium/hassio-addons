#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting Social to Mealie"
cd /app || bashio::exit.nok "App directory not found"
chown nextjs /app/entrypoint.sh
chmod +x /app/entrypoint.sh
exec gosu nextjs /app/entrypoint.sh node --run start
