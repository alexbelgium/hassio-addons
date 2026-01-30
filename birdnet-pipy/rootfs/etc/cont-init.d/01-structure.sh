#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

DEFAULT_LOCATION="/config/data"
DATA_LOCATION="$(bashio::config 'data_location' || true)"
DATA_LOCATION="${DATA_LOCATION:-$DEFAULT_LOCATION}"

case "${DATA_LOCATION}" in
  /config/*|/share/*|/data/*) ;;
  *)
    bashio::log.warning "Invalid data_location '${DATA_LOCATION}', falling back to ${DEFAULT_LOCATION}"
    DATA_LOCATION="${DEFAULT_LOCATION}"
    ;;
esac

LEGACY1="/config/birdnet-pipy/data"
LEGACY2="/data"

mkdir -p "${DATA_LOCATION}"

if [ -z "$(ls -A "${DATA_LOCATION}" 2>/dev/null || true)" ]; then
  if [ -d "${LEGACY1}" ] && [ -n "$(ls -A "${LEGACY1}" 2>/dev/null || true)" ]; then
    bashio::log.notice "Migrating legacy data from ${LEGACY1} to ${DATA_LOCATION}"
    cp -a "${LEGACY1}/." "${DATA_LOCATION}/" || true
  elif [ -d "${LEGACY2}" ] && [ "${LEGACY2}" != "${DATA_LOCATION}" ] && [ -n "$(ls -A "${LEGACY2}" 2>/dev/null || true)" ]; then
    bashio::log.notice "Migrating legacy data from ${LEGACY2} to ${DATA_LOCATION}"
    cp -a "${LEGACY2}/." "${DATA_LOCATION}/" || true
  fi
fi

mkdir -p "${DATA_LOCATION}/config" "${DATA_LOCATION}/clips" "${DATA_LOCATION}/logs" "${DATA_LOCATION}/cache" || true

rm -rf /app/data
ln -s "${DATA_LOCATION}" /app/data

if [ "${DATA_LOCATION}" != "/data" ]; then
  if [ -L /data ]; then
    rm -f /data
  fi
  if [ ! -e /data ]; then
    ln -s "${DATA_LOCATION}" /data
  elif [ -d /data ] && [ -z "$(ls -A /data 2>/dev/null || true)" ]; then
    rmdir /data || true
    ln -s "${DATA_LOCATION}" /data
  else
    bashio::log.warning "/data exists and is not empty; leaving it unchanged."
  fi
fi

bashio::log.notice "Data location set to: ${DATA_LOCATION}"
