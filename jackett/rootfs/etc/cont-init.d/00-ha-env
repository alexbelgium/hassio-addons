#!/usr/bin/with-contenv bashio

for k in $(bashio::jq "${__BASHIO_ADDON_CONFIG}" 'keys | .[]'); do
    printf "$(bashio::config $k)" > /var/run/s6/container_environment/$k
done