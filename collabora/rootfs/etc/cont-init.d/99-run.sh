#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.has_value 'domain'; then
    domain="$(bashio::config 'domain')"
    export domain
fi

if bashio::config.has_value 'username'; then
    username="$(bashio::config 'username')"
    export username
fi

if bashio::config.has_value 'password'; then
    password="$(bashio::config 'password')"
    export password
fi

bashio::log.info "Starting Collabora Online..."
su -s /bin/bash -c "/start-collabora-online.sh" "$(getent passwd 1001 | cut -d: -f1)"
