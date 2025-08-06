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

if bashio::config.has_value 'aliasgroup1'; then
    aliasgroup1="$(bashio::config 'aliasgroup1')"
    export aliasgroup1
fi

if bashio::config.has_value 'dictionaries'; then
    dictionaries="$(bashio::config 'dictionaries')"
    export dictionaries
fi

if bashio::config.has_value 'extra_params'; then
    extra_params="$(bashio::config 'extra_params')"
    export extra_params
fi

COOL_CONFIG="/etc/coolwsd/coolwsd.xml"
CONFIG_DEST="/config/coolwsd.xml"

mkdir -p /config
if [ ! -e "${CONFIG_DEST}" ]; then
    mv "${COOL_CONFIG}" "${CONFIG_DEST}"
    chown root:root "${CONFIG_DEST}"
    chmod 644 "${CONFIG_DEST}"
else
    rm -f "${COOL_CONFIG}"
fi
ln -sf "${CONFIG_DEST}" "${COOL_CONFIG}"

bashio::log.info "Starting Collabora Online..."
su -s /bin/bash -c "/start-collabora-online.sh" "$(getent passwd 1001 | cut -d: -f1)"
