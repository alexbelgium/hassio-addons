#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

DATA_DIR="/app/data"
CFG_DIR="${DATA_DIR}/config"
SETTINGS="${CFG_DIR}/user_settings.json"

mkdir -p "${CFG_DIR}"

if [ ! -f "${SETTINGS}" ]; then
  if [ -f /app/config/user_settings.example.json ]; then
    cp /app/config/user_settings.example.json "${SETTINGS}"
  else
    printf '%s\n' '{}' > "${SETTINGS}"
  fi
fi

RECORDING_MODE="$(bashio::config 'RECORDING_MODE' || true)"
RTSP_URL="$(bashio::config 'RTSP_URL' || true)"

PATCH='{}'
if [ -n "${RECORDING_MODE}" ]; then
  PATCH="$(printf '%s' "${PATCH}" | jq --arg v "${RECORDING_MODE}" '.audio.recording_mode=$v')"
fi
if [ -n "${RTSP_URL}" ]; then
  PATCH="$(printf '%s' "${PATCH}" | jq --arg v "${RTSP_URL}" '.audio.rtsp_url=$v')"
fi

tmp="$(mktemp)"
jq -s '.[0] * .[1]' "${SETTINGS}" <(printf '%s\n' "${PATCH}") > "${tmp}"
mv "${tmp}" "${SETTINGS}"

chmod 0644 "${SETTINGS}" || true
