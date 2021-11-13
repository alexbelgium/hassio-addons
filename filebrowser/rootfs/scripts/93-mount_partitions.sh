#!/usr/bin/with-contenv bashio

mkdir -p /addons
mount /dev/mmcblk0p8 /addons &>/dev/null && bashio::log.info "Data drive mounted in /addons"
