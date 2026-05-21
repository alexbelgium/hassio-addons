#!/bin/sh
set -e

# Create persistent data directories
mkdir -p "${AURRAL_DATA_DIR:-/config/data}"
mkdir -p "${AURRAL_DATA_DIR:-/config/data}/image-proxy"
mkdir -p "${DOWNLOAD_FOLDER:-/share/aurral/downloads}"
mkdir -p "${WEEKLY_FLOW_FOLDER:-/share/aurral/downloads/weekly-flow}"

# The upstream app hardcodes /app/backend/data/image-proxy (relative to __dirname).
# Symlink it into persistent storage so cached images survive restarts.
mkdir -p /app/backend/data
ln -sfn "${AURRAL_DATA_DIR:-/config/data}/image-proxy" /app/backend/data/image-proxy

exec "$@"
