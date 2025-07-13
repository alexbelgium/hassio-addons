#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

# Please see available options to customize Navidrome for your needs at
# https://www.navidrome.org/docs/usage/configuration-options/#available-options

ND_MUSICFOLDER=$(bashio::config 'music_folder')
export ND_MUSICFOLDER

ND_DATAFOLDER=$(bashio::config 'data_folder')
export ND_DATAFOLDER

ND_LOGLEVEL=$(bashio::config 'log_level')
export ND_LOGLEVEL

ND_BASEURL=$(bashio::config 'base_url')
ND_BASEURL="${ND_BASEURL%/}"
export ND_BASEURL

if bashio::config.true 'ssl'; then
	bashio::log.info "ssl is enabled"
	ND_TLSCERT=$(bashio::config 'certfile')
	export ND_TLSCERT
	ND_TLSKEY=$(bashio::config 'keyfile')
	export ND_TLSKEY
fi
if bashio::config.has_value 'default_language'; then
	ND_DEFAULTLANGUAGE=$(bashio::config 'default_language')
	export ND_DEFAULTLANGUAGE
fi
if bashio::config.has_value 'image_cache_size'; then
	ND_IMAGECACHESIZE=$(bashio::config 'image_cache_size')
	export ND_IMAGECACHESIZE
fi
if bashio::config.has_value 'lastfm_api_key'; then
	ND_LASTFM_APIKEY=$(bashio::config 'lastfm_api_key')
	export ND_LASTFM_APIKEY
fi
if bashio::config.has_value 'lastfm_secret'; then
	ND_LASTFM_SECRET=$(bashio::config 'lastfm_secret')
	export ND_LASTFM_SECRET
fi
if bashio::config.has_value 'password_encryption_key'; then
	ND_PASSWORDENCRYPTIONKEY=$(bashio::config 'password_encryption_key')
	export ND_PASSWORDENCRYPTIONKEY
fi
if bashio::config.has_value 'scan_schedule'; then
	ND_SCANSCHEDULE=$(bashio::config 'scan_schedule')
	export ND_SCANSCHEDULE
fi
if bashio::config.has_value 'spotify_id'; then
	ND_SPOTIFY_ID=$(bashio::config 'spotify_id')
	export ND_SPOTIFY_ID
fi
if bashio::config.has_value 'spotify_secret'; then
	ND_SPOTIFY_SECRET=$(bashio::config 'spotify_secret')
	export ND_SPOTIFY_SECRET
fi
if bashio::config.has_value 'transcoding_cache_size'; then
	ND_TRANSCODINGCACHESIZE=$(bashio::config 'transcoding_cache_size')
	export ND_TRANSCODINGCACHESIZE
fi
if bashio::config.has_value 'welcome_message'; then
	ND_UIWELCOMEMESSAGE=$(bashio::config 'welcome_message')
	export ND_UIWELCOMEMESSAGE
fi

##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading!"

/app/navidrome
