#!/usr/bin/bashio

# Set user
if bashio::config.has_value 'PUID'; then PUID="$(bashio::config 'PUID')"; fi
if bashio::config.has_value 'PGID'; then PGID="$(bashio::config 'PGID')"; fi

# Enable watch folder
if bashio::config.has_value "watch_path"; then
  # Enables folders
  sed -i "/[[folder]]/c [[folder]]" /config/unpackerr.conf
  # Set downloads path
  sed -i "s|_path|_pth|g" /config/unpackerr.conf
  sed -i "/path =/c path = $(bashio::config 'watch_path')" /config/unpackerr.conf
  sed -i "s|_pth|_path|g" /config/unpackerr.conf
  # Make path
  mkdir -p "$(bashio::config 'watch_path')"
  # Set permission
  chown -R $PUID:$PGID "$(bashio::config 'watch_path')"
fi

# Enable extraction folder
if bashio::config.has_value "extraction_path"; then
  # Enables folders
  sed -i "/[[folder]]/c [[folder]]" /config/unpackerr.conf
  # Set extraction path
  sed -i "/extract_path =/c extract_path = $(bashio::config 'extraction_path')" /config/unpackerr.conf
  # Make path
  mkdir -p "$(bashio::config 'extraction_path')"
  # Set permission
  chown -R $PUID:$PGID "$(bashio::config 'extraction_path')"
fi
