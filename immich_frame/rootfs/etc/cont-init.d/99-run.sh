#!/usr/bin/env bashio

bashio::log.info "Starting Immich Frame"

mkdir -p /config/Config
if [ -f /app/Config ]; then
	rm -r /app/Config
fi
ln -sf /app/Config /config/Config

exec dotnet ImmichFrame.WebApi.dll
