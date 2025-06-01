#!/usr/bin/env bashio

bashio::log.info "Starting Immich Frame"

mkdir -p /config/config
ln -sf /app/Config /config/Config

exec dotnet ImmichFrame.WebApi.dll
