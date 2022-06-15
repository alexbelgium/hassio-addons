#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

bashio::log.info "Updating folder structure and permission"

echo "Internal location : /emby"
mkdir -p /emby
chown -R abc:abc /emby

echo "Files location : /share/storage/tv"
mkdir -p /share/storage/tv
chown -R abc:abc /share/storage/tv

echo "Files location : /share/storage/movies"
mkdir -p /share/storage/movies
chown -R abc:abc /share/storage/movies

echo "Data location : /share/emby"
mkdir -p /share/emby
chown -R abc:abc /share/emby

echo "Config location : /config/addons_config/emby"
mkdir -p /config/addons_config/emby
chown -R abc:abc /config/addons_config/emby

# links

if [ ! -d /emby/cache ]; then
    echo "... link for /emby/cache"
    mkdir -p /share/emby/cache
    chown -R abc:abc /share/emby/cache
    ln -s /share/emby/cache /emby/cache
fi

if [ ! -d /emby/config ]; then
    echo "Creating link for /emby/config"
    mkdir -p /config/emby
    chown -R abc:abc /config/emby
    ln -s /config/emby /emby/config
fi

if [ ! -d /emby/data ]; then
    echo "Creating link for /emby/data"
    mkdir -p /share/emby/data
    chown -R abc:abc /share/emby/data
    ln -s /share/emby/data /emby/data
fi

if [ ! -d /emby/logs ]; then
    echo "Creating link for /emby/logs"
    mkdir -p /share/emby/logs
    chown -R abc:abc /share/emby/logs
    ln -s /share/emby/logs /emby/logs
fi

if [ ! -d /emby/metadata ]; then
    echo "Creating link for /emby/metadata"
    mkdir -p /share/emby/metadata
    chown -R abc:abc /share/emby/metadata
    ln -s /share/emby/metadata /emby/metadata
fi

if [ ! -d /emby/plugins ]; then
    echo "Creating link for /emby/plugins"
    mkdir -p /share/emby/plugins
    chown -R abc:abc /share/emby/plugins
    ln -s /share/emby/plugins /emby/plugins
fi

if [ ! -d /emby/root ]; then
    echo "Creating link for /emby/root"
    mkdir -p /share/emby/root
    chown -R abc:abc /share/emby/root
    ln -s /share/emby/root /emby/root
fi
