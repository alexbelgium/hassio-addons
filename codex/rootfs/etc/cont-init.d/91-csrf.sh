#!/usr/bin/env bashio
# shellcheck shell=bash

# Export CSRF
# Borrowed from https://github.com/BenoitAnastay/paperless-home-assistant-addon/blob/main/paperless-ngx/rootfs/etc/s6-overlay/s6-rc.d/init-paperless/run
declare -a urls=()
CSRF=""
# Get HA Port
result=$(bashio::api.supervisor GET /core/info true || true)
port=$(bashio::jq "$result" ".data.port")
addon_port=$(bashio::addon.port 9810)

# Get all possible URLs
result=$(bashio::api.supervisor GET /core/api/config true || true)
urls+=("$(bashio::info.hostname).local")
urls+=("$(bashio::info.hostname)")
urls+=("$(bashio::jq "$result" '.internal_url' | cut -d'/' -f3 | cut -d':' -f1)")
urls+=("$(bashio::jq "$result" '.external_url' | cut -d'/' -f3 | cut -d':' -f1)")

# Get supported interfaces
for interface in $(bashio::network.interfaces); do
  urls+=("$(bashio::network.ipv6_address "${interface}" | cut -d'/' -f1)")
  urls+=("$(bashio::network.ipv4_address "${interface}" | cut -d'/' -f1)")
done

if bashio::config.has_value 'csrf_allowed'; then
  bashio::log.info "Setup manually defined ALLOWED_CSRF domains"

  while read -r line; do
    urls+=("$line")
  done <<<"$(bashio::config 'csrf_allowed')"
fi

# Add internal and external URL as it
if [[ "$(bashio::jq "$result" '.external_url')" != "null" ]]; then
  CSRF=$(bashio::jq "$result" '.external_url')
fi
if [[ "$(bashio::jq "$result" '.internal_url')" != "null" ]]; then
  CSRF=$(bashio::jq "$result" '.internal_url'),${CSRF}
fi

# Loop through URls to add them in the CSRF string
for url in "${urls[@]}"; do
  if bashio::var.has_value "${url}"; then
    if [[ "${url}" != "null" ]] && [[ "${url}" != "null.local" ]]; then
      CSRF="https://${url}:${port},http://${url}:${port},https://${url},http://${url}",${CSRF}
      if bashio::var.has_value "$(bashio::addon.port 9810)"; then
        CSRF="https://${url}:${addon_port},http://${url}:${addon_port}",${CSRF}
      fi
    fi
  fi
done
CSRF=${CSRF::-1}

# Save CSFR
echo -n "${CSRF}" >/var/run/s6/container_environment/PAPERLESS_CSRF_TRUSTED_ORIGINS
bashio::log.blue "PAPERLESS_CSRF_TRUSTED_ORIGINS is set to ${CSRF}"
