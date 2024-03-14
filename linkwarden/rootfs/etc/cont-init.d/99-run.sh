#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Creating folders"
mkdir -p /config/library

bashio::log.info "Starting app..."
yarn prisma migrate deploy
yarn start docker-entrypoint.sh
