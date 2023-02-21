#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

##################
# SYMLINK CONFIG #
##################

#Create folders

if [ ! -d /share/piwigo ]; then
    echo "Creating /share/piwigo"
    mkdir -p /share/piwigo
    chown -R abc:abc /share/piwigo
else
    chown -R abc:abc /share/piwigo
fi

if [ ! -d /share/piwigo/config ]; then
    echo "moving config folder"
    mv /config/www/local/config /share/piwigo
    ln -s /share/piwigo/config /config/www/local
    echo "links done"
else
    rm -r /config/www/local/config
    ln -s /share/piwigo/config /config/www/local
    echo "Using existing config"
fi

if [ ! -d /share/piwigo/keys ]; then
    echo "moving keys folder"
    mv /config/keys /share/piwigo
    ln -s /share/piwigo/keys /config
    echo "links done"
else
    rm -r /config/keys
    ln -s /share/piwigo/keys /config
    echo "Using existing keys folder"
fi

##################
# CORRECT CONFIG #
##################
# shellcheck disable=SC2015
sed -i 's|E_ALL|""|g' /share/piwigo/config/config.inc.php && echo "config corrected for php error" || true
