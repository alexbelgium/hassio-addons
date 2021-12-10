#!/usr/bin/with-contenv bashio

CONFIG_LOCATION=$(bashio::config 'config_location')
sed -i "s|/config/readarrg|$CONFIG_LOCATION|g" /etc/services.d/readarr/run \
sed -i "s|/config/readarr|$CONFIG_LOCATION|g" /etc/cont-init.d/30-config \
