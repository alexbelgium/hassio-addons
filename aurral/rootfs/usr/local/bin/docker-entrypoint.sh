#!/bin/sh
set -e

# Create persistent data directories
mkdir -p "${AURRAL_DATA_DIR:-/config/data}"
mkdir -p "${AURRAL_DATA_DIR:-/config/data}/image-proxy"
mkdir -p "${DOWNLOAD_FOLDER:-/share/aurral/downloads}"
mkdir -p "${WEEKLY_FLOW_FOLDER:-/share/aurral/downloads/weekly-flow}"

# Pre-create /app/backend/data as a real dir so node can write to it
# (symlink approach fails when the target isn't mounted yet)
mkdir -p /app/backend/data

exec "$@"
