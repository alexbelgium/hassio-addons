#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

slug=paperless_ng

if [ ! -d /config/addons_config/$slug ]; then
    echo "Creating /config/addons_config/$slug"
    mkdir -p /config/addons_config/$slug
fi

chmod -R 755 /config/addons_config/$slug
chown -R paperless:paperless /config/addons_config/$slug

if [ -f /etc/cont-init.d/90-config_yaml.sh ]; then
     sed -i "/# Export the variable/a sed -i \"/file_env()/a export \$line\" /sbin/docker-entrypoint.sh" /etc/cont-init.d/90-config_yaml.sh
     echo "config.yaml enabled"
fi
