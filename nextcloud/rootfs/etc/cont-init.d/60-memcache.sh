#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Change data directory
datadirectory=$(bashio::config 'data_directory')
bashio::log.info "Setting data diretory: ${datadirectory}"
sed -i "s|%%datadirectory%%|$datadirectory|g" /defaults/config.php

# copy config
[[ ! -f /data/config/www/nextcloud/config/config.php ]] &&
cp /defaults/config.php /data/config/www/nextcloud/config/config.php

# permissions
chown abc:abc \
    /data/config/www/nextcloud/config/config.php
