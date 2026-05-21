#!/bin/sh
set -e

# Create persistent directories in HA volumes
mkdir -p /config/data
mkdir -p "${DOWNLOAD_FOLDER:-/share/aurral/downloads}"
mkdir -p "${WEEKLY_FLOW_FOLDER:-/share/aurral/downloads/weekly-flow}"

# The upstream app expects its data at /app/backend/data and downloads at /app/downloads.
# Symlink both into HA persistent storage.
ln -sfn /config/data /app/backend/data
ln -sfn "${DOWNLOAD_FOLDER:-/share/aurral/downloads}" /app/downloads

exec "$@"
