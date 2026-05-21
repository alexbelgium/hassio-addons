#!/bin/sh
set -e

DOWNLOAD_FOLDER=$(jq -r '.download_folder // "/share/aurral/downloads"' /data/options.json)
WEEKLY_FLOW_SUFFIX=$(jq -r '.weekly_flow_folder // "weekly-flow"' /data/options.json)

export DOWNLOAD_FOLDER
export WEEKLY_FLOW_FOLDER="${DOWNLOAD_FOLDER}/${WEEKLY_FLOW_SUFFIX}"

# Create persistent directories in HA volumes
mkdir -p /config/data
mkdir -p "${DOWNLOAD_FOLDER}"
mkdir -p "${WEEKLY_FLOW_FOLDER}"

exec "$@"
