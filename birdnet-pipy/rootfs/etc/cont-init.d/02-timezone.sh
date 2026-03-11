#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

# Use timezone defined in add-on options
bashio::log.info "Setting timezone..."
TZ_VALUE="$(bashio::config 'TZ' || true)"
TZ_VALUE="${TZ_VALUE:-Europe/Paris}"

if [ ! -f "/usr/share/zoneinfo/${TZ_VALUE}" ]; then
    bashio::log.warning "Invalid timezone '${TZ_VALUE}'. Falling back to Europe/Paris."
    bashio::log.warning "See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones for valid values."
    TZ_VALUE="Europe/Paris"
fi

# Apply timezone to the container
ln -sf "/usr/share/zoneinfo/${TZ_VALUE}" /etc/localtime
echo "${TZ_VALUE}" > /etc/timezone
export TZ="${TZ_VALUE}"
sed -i "1a TZ=\"${TZ_VALUE}\"" /etc/services.d/*

# Update s6 container environment so child processes inherit the timezone
if [ -d /var/run/s6/container_environment ]; then
    echo "${TZ_VALUE}" > /var/run/s6/container_environment/TZ
fi

bashio::log.notice "Timezone set to: ${TZ_VALUE}"
