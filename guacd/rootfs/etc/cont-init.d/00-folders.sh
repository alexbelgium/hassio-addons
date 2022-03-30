#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Define home
HOME="/config/addons_config/guacd"

PUID="$(bashio::config "PUID")"
PGID="$(bashio::config "PGID")"

mkdir -p "$HOME"
chown -R "$PUID:$PGID" "$HOME"
