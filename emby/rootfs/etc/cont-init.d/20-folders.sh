#!/bin/bash

if [ ! -d /emby ]; then
    echo "Creating /emby"
    mkdir -p /emby
    chown -R abc:abc /emby
fi

if [ ! -d /share/storage/tv ]; then
    echo "Creating /share/storage/tv"
    mkdir -p /share/storage/tv
    chown -R abc:abc /share/storage/tv
fi

if [ ! -d /share/storage/movies ]; then
    echo "Creating /share/storage/movies"
    mkdir -p /share/storage/movies
    chown -R abc:abc /share/storage/movies
fi

if [ ! -d /share/emby ]; then
    echo "Creating /share/emby"
    mkdir -p /share/emby
    chown -R abc:abc /share/emby
fi

if [ -d /config/emby ] && [ ! -d /config/addons_config/emby ]; then
    echo "Moving to new location /config/addons_config/emby"
    mkdir -p /config/addons_config/emby
    chown -R abc:abc /config/addons_config/emby
    mv /config/emby/* /config/addons_config/emby/
    rm -r /config/emby
fi

if [ ! -d /config/addons_config/emby ]; then
    echo "Creating /config/addons_config/emby"
    mkdir -p /config/addons_config/emby
    chown -R abc:abc /config/addons_config/emby
fi

# links

if [ ! -d /emby/cache ]; then
    echo "Creating link for /emby/cache"
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

rm /emby/logs
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
