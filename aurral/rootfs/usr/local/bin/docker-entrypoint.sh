#!/bin/sh
set -e

DOWNLOAD_FOLDER=$(bashio::config 'download_folder')
WEEKLY_FLOW_SUFFIX=$(bashio::config 'weekly_flow_folder')

export DOWNLOAD_FOLDER
export WEEKLY_FLOW_FOLDER="${DOWNLOAD_FOLDER}/${WEEKLY_FLOW_SUFFIX}"

# Create persistent directories in HA volumes
mkdir -p /config/data
mkdir -p "${DOWNLOAD_FOLDER}"
mkdir -p "${WEEKLY_FLOW_FOLDER}"

exec "$@"
