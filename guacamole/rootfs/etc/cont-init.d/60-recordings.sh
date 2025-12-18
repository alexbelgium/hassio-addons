#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

readonly GUAC_PROPERTIES_FILE="/config/guacamole.properties"

recording_path="$(bashio::config 'recording_search_path')"
if bashio::var.is_empty "${recording_path}"; then
    recording_path="/config/recordings"
fi

bashio::log.info "Ensuring recording storage path exists: ${recording_path}"
mkdir -p "${recording_path}"

if [ ! -f "${GUAC_PROPERTIES_FILE}" ]; then
    bashio::log.info "Creating guacamole.properties at ${GUAC_PROPERTIES_FILE}"
    touch "${GUAC_PROPERTIES_FILE}"
fi

if grep -q "^recording-search-path:" "${GUAC_PROPERTIES_FILE}"; then
    sed -i "s|^recording-search-path:.*|recording-search-path: ${recording_path}|" "${GUAC_PROPERTIES_FILE}"
else
    echo "recording-search-path: ${recording_path}" >> "${GUAC_PROPERTIES_FILE}"
fi
