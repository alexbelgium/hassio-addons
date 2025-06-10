#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155
set -e

bashio::log.warning "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory. Otherwise the system will become unresponsive and crash."

# Check data location
LOCATION=$(bashio::config 'data_location')
if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
  # Default location
  LOCATION="/config/addons_config/joplin"
else
  bashio::log.warning "Warning : a custom data location was selected, but the previous folder will NOT be copied. You need to do it manually"
fi

# Create folder
if [ ! -d "$LOCATION" ]; then
  echo "Creating $LOCATION"
  mkdir -p "$LOCATION"
fi

touch "$LOCATION"/database.sqlite

if [ ! -d "$LOCATION"/resources ]; then
  mkdir -p "$LOCATION"/resources
fi
ln -s "$LOCATION"/resources /home/joplin/packages/server

chown -R joplin:joplin "$LOCATION"
chmod -R 777 "$LOCATION"
chmod 777 "$LOCATION/database.sqlite"
export SQLITE_DATABASE="$LOCATION/database.sqlite"

if bashio::config.has_value 'POSTGRES_DATABASE'; then
  bashio::log.info "Using postgres"

  bashio::config.has_value 'DB_CLIENT' && export DB_CLIENT=$(bashio::config 'DB_CLIENT') && bashio::log.info 'Database client set'
  bashio::config.has_value 'POSTGRES_PASSWORD' && export POSTGRES_PASSWORD=$(bashio::config 'POSTGRES_PASSWORD') && bashio::log.info 'Postgrep Password set'
  bashio::config.has_value 'POSTGRES_DATABASE' && export POSTGRES_DATABASE=$(bashio::config 'POSTGRES_DATABASE') && bashio::log.info 'Postgrep Database set'
  bashio::config.has_value 'POSTGRES_USER' && export POSTGRES_USER=$(bashio::config 'POSTGRES_USER') && bashio::log.info 'Postgrep User set'
  bashio::config.has_value 'POSTGRES_PORT' && export POSTGRES_PORT=$(bashio::config 'POSTGRES_PORT') && bashio::log.info 'Postgrep Port set'
  bashio::config.has_value 'POSTGRES_HOST' && export POSTGRES_HOST=$(bashio::config 'POSTGRES_HOST') && bashio::log.info 'Postgrep Host set'
else

  bashio::log.info "Using sqlite"

fi

##############
# LAUNCH APP #
##############

# Configure app
bashio::config.has_value 'MAILER_HOST' && export MAILER_HOST=$(bashio::config 'MAILER_HOST') && bashio::log.info 'Mailer Host set'
bashio::config.has_value 'MAILER_PORT' && export MAILER_PORT=$(bashio::config 'MAILER_PORT') && bashio::log.info 'Mailer Port set'
bashio::config.has_value 'MAILER_SECURITY' && export MAILER_SECURITY=$(bashio::config 'MAILER_SECURITY') && bashio::log.info 'Mailer Security set'
bashio::config.has_value 'MAILER_AUTH_USER' && export MAILER_AUTH_USER=$(bashio::config 'MAILER_AUTH_USER') && bashio::log.info 'Mailer User set'
bashio::config.has_value 'MAILER_AUTH_PASSWORD' && export MAILER_AUTH_PASSWORD=$(bashio::config 'MAILER_AUTH_PASSWORD') && bashio::log.info 'Mailer Password set'
bashio::config.has_value 'MAILER_NOREPLY_NAME' && export MAILER_NOREPLY_NAME=$(bashio::config 'MAILER_NOREPLY_NAME') && bashio::log.info 'Mailer Noreply Name set'
bashio::config.has_value 'MAILER_NOREPLY_EMAIL' && export MAILER_NOREPLY_EMAIL=$(bashio::config 'MAILER_NOREPLY_EMAIL') && bashio::log.info 'Mailer Noreply Email set'
bashio::config.has_value 'MAILER_ENABLED' && export MAILER_ENABLED=$(bashio::config 'MAILER_ENABLED') && bashio::log.info 'Mailer Enabled set'
export APP_BASE_URL=$(bashio::config 'APP_BASE_URL')
export ALLOWED_HOSTS="*"

bashio::log.info 'Starting Joplin. Initial user is "admin@localhost" with password "admin"'

cd /home/joplin || true
npm --prefix packages/server start
