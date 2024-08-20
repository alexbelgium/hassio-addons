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
if bashio::config.has_value 'default_language'; then
    ND_DEFAULTLANGUAGE=$(bashio::config 'default_language')
fi
if bashio::config.has_value 'image_cache_size'; then
    ND_IMAGECACHESIZE=$(bashio::config 'image_cache_size')
fi
if bashio::config.has_value 'lastfm_api_key'; then
    ND_LASTFM_APIKEY=$(bashio::config 'lastfm_api_key')
fi
if bashio::config.has_value 'lastfm_secret'; then
    ND_LASTFM_SECRET=$(bashio::config 'lastfm_secret')
fi
if bashio::config.has_value 'password_encryption_key'; then
    ND_PASSWORDENCRYPTIONKEY=$(bashio::config 'password_encryption_key')
fi
if bashio::config.has_value 'scan_schedule'; then
    ND_SCANSCHEDULE=$(bashio::config 'scan_schedule')
fi
if bashio::config.has_value 'spotify_id'; then
    ND_SPOTIFY_ID=$(bashio::config 'spotify_id')
fi
if bashio::config.has_value 'spotify_secret'; then
    ND_SPOTIFY_SECRET=$(bashio::config 'spotify_secret')
fi
if bashio::config.has_value 'transcoding_cache_size'; then
    ND_TRANSCODINGCACHESIZE=$(bashio::config 'transcoding_cache_size')
fi
if bashio::config.has_value 'welcome_message'; then
    ND_UIWELCOMEMESSAGE=$(bashio::config 'welcome_message')
fi


##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading!"

/app/navidrome

