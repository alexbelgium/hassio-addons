#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

# Please see available options to customize Navidrome for your needs at
# https://www.navidrome.org/docs/usage/configuration-options/#available-options

ND_MUSICFOLDER=$(bashio::config 'music_folder')
ND_DATAFOLDER=$(bashio::config 'data_folder')
ND_LOGLEVEL=$(bashio::config 'log_level')
ND_BASEURL=$(bashio::config 'base_url')
if bashio::config.true 'ssl'; then
    bashio::log.info "ssl is enabled"
    ND_TLSCERT=$(bashio::config 'certfile')
    ND_TLSKEY=$(bashio::config 'keyfile')
fi


##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading!"

/app/navidrome

