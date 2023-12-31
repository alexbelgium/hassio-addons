#!/usr/bin/bashio

# Set user
if bashio::config.has_value 'PUID'; then export PUID="$(bashio::config 'PUID')"; fi
if bashio::config.has_value 'PGID'; then export PGID="$(bashio::config 'PGID')"; fi

# Enable watch folder
if bashio::config.has_value "watch_path"; then
    # Info
    bashio::log.info "Watch path is $(bashio::config 'watch_path'), creating folder and setting permission. You'll need to physically enable the option in the config/unpackerr.conf file"
    # Make path
    mkdir -p "$(bashio::config 'watch_path')"
    # Set permission
    chown -R "$PUID":"$PGID" "$(bashio::config 'watch_path')"
fi

# Enable extraction folder
if bashio::config.has_value "extraction_path"; then
    # Info
    bashio::log.info "Extraction path is $(bashio::config 'extraction_path'), creating folder and setting permission.  You'll need to physically enable the option in the config/unpackerr.conf file"
    # Make path
    mkdir -p "$(bashio::config 'extraction_path')"
    # Set permission
    chown -R "$PUID":"$PGID" "$(bashio::config 'extraction_path')"
fi
