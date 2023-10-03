#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Define home
# Creating config location
echo "Creating config location ..."
HOME="$(bashio::config "CONFIG_LOCATION")"
HOME="$(dirname "$HOME")"
mkdir -p "$HOME"
chmod -R 777 "$HOME"

# Copy files to data
echo "Copying files if needed..."
cp -rnf /fgc/* /data/
