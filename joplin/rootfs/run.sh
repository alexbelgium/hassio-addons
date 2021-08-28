#!/usr/bin/env bashio

bashio::log.warning "Warning - minimum configuration recommended : 2 cpu cores and 4 GB of memory. Otherwise the system will become unresponsive and crash." 

##########
# BANNER #
##########

if bashio::supervisor.ping; then
  bashio::log.blue \
  '-----------------------------------------------------------'
  bashio::log.blue " Add-on: $(bashio::addon.name)"
  bashio::log.blue " $(bashio::addon.description)"
  bashio::log.blue \
  '-----------------------------------------------------------'

  bashio::log.blue " Add-on version: $(bashio::addon.version)"
  if bashio::var.true "$(bashio::addon.update_available)"; then
    bashio::log.magenta ' There is an update available for this add-on!'
    bashio::log.magenta \
    " Latest add-on version: $(bashio::addon.version_latest)"
    bashio::log.magenta ' Please consider upgrading as soon as possible.'
  else
    bashio::log.green ' You are running the latest version of this add-on.'
  fi

  bashio::log.blue " System: $(bashio::info.operating_system)" \
  " ($(bashio::info.arch) / $(bashio::info.machine))"
  bashio::log.blue " Home Assistant Core: $(bashio::info.homeassistant)"
  bashio::log.blue " Home Assistant Supervisor: $(bashio::info.supervisor)"

  bashio::log.blue \
  '-----------------------------------------------------------'
  bashio::log.blue \
  ' Please, share the above information when looking for help'
  bashio::log.blue \
  ' or support in, e.g., GitHub, forums or the Discord chat.'
  bashio::log.green \
  ' https://github.com/alexbelgium/hassio-addons'
  bashio::log.blue \
  '-----------------------------------------------------------'
fi

##############
# LAUNCH APP #
##############

# Configure app
bashio::config.has_value 'DB_CLIENT' && export DB_CLIENT=$(bashio::config 'DB_CLIENT') && bashio::log.info 'Custom database set'
bashio::config.has_value 'POSTGRES_PASSWORD' && export POSTGRES_PASSWORD=$(bashio::config 'POSTGRES_PASSWORD')
bashio::config.has_value 'POSTGRES_USER' && export POSTGRES_USER=$(bashio::config 'POSTGRES_USER')
bashio::config.has_value 'POSTGRES_PORT' && export POSTGRES_PORT=$(bashio::config 'POSTGRES_PORT')
bashio::config.has_value 'POSTGRES_HOST' && export POSTGRES_HOST=$(bashio::config 'POSTGRES_HOST')
export APP_BASE_URL=$(bashio::config 'APP_BASE_URL')

bashio::log.info 'Starting Joplin. Initial user is "admin@localhost" with password "admin"'

npm --prefix packages/server start
