#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

yarn prisma migrate deploy

bashio::log.info "Starting app..."

yarn start docker-entrypoint.sh
