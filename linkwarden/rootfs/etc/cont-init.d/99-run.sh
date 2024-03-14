#!/command/with-contenv bashio
# shellcheck shell=bash
set -e
  
bashio::log.info "Creating folders"
mkdir -p /config/library
mkdir -p /config/database
touch /config/database/linkwarden.sqlite

bashio::log.info "Applying migrations"
rm -r /data_linkwarden/prisma/migrations
cd /data_linkwarden
npx prisma db push
npx prisma generate

bashio::log.info "Starting app..."
yarn prisma migrate deploy
yarn start docker-entrypoint.sh
