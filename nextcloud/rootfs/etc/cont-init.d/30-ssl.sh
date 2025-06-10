#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.true 'use_own_certs'; then

  bashio::log.green "Using referenced ssl certificates"
  CERTFILE=$(bashio::config 'certfile')
  KEYFILE=$(bashio::config 'keyfile')

  # Validate ssl
  bashio::config.require.ssl

  #Check if files exist
  echo "... checking if referenced files exist"
  [ ! -f /ssl/"$CERTFILE" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$CERTFILE not found" && bashio::exit.nok
  [ ! -f /ssl/"$KEYFILE" ] && bashio::log.fatal "... use_own_certs is true but certificate /ssl/$KEYFILE not found" && bashio::exit.nok

  [[ -f /data/config/keys/cert.key ]] && rm /data/config/keys/cert.key
  [[ -f /data/config/keys/cert.crt ]] && rm /data/config/keys/cert.crt
  cp /ssl/"$CERTFILE" /data/config/keys/cert.crt
  cp /ssl/"$KEYFILE" /data/config/keys/cert.key
  echo "... done"

fi
