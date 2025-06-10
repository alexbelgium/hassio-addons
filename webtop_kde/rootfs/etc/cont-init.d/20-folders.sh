#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046
set -e

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Set user for microsoft edge if available
if [ -f /usr/bin/microsoft-edge-real ]; then
  chown "$PUID:$PGID" /usr/bin/microsoft-edge*
  chmod +x /usr/bin/microsoft-edge*
fi

# Check data location
LOCATION=$(bashio::config 'data_location')

if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
  # Default location
  LOCATION="/config/data_kde"
else
  # Check if config is located in an acceptable location
  LOCATIONOK=""
  for location in "/share" "/config" "/data" "/mnt"; do
    if [[ "$LOCATION" == "$location"* ]]; then
      LOCATIONOK=true
    fi
  done

  if [ -z "$LOCATIONOK" ]; then
    LOCATION="/config/data_kde"
    bashio::log.fatal "Your data_location value can only be set in /share, /config or /data (internal to addon). It will be reset to the default location : $LOCATION"
  fi
fi

# Set data location
bashio::log.info "Setting data location to $LOCATION"

# Correct home locations
for file in /etc/s6-overlay/s6-rc.d/*/run; do
  if [ "$(sed -n '1{/bash/p};q' "$file")" ]; then
    sed -i "1a export HOME=$LOCATION" "$file"
    sed -i "1a export FM_HOME=$LOCATION" "$file"
  fi
done

# Correct home location
for folders in /defaults /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d; do
  if [ -d "$folders" ]; then
    sed -i "s|/config/data_kde|$LOCATION|g" $(find "$folders" -type f) &>/dev/null || true
  fi
done

#  Change user home
sed -i "s|^\(abc:[^:]*:[^:]*:[^:]*:[^:]*:\)[^:]*|\1$LOCATION|" /etc/passwd
#usermod --home "$LOCATION" abc || true

# Add environment variables
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" >/var/run/s6/container_environment/HOME; fi
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" >/var/run/s6/container_environment/FM_HOME; fi
{
  printf "%s\n" "export HOME=\"$LOCATION\""
  printf "%s\n" "export FM_HOME=\"$LOCATION\""
} >>~/.bashrc

# Create folder
echo "Creating $LOCATION"
mkdir -p "$LOCATION"

# Create cache
mkdir -p /.cache
chmod 777 /.cache
if [ -d "/config/.cache" ]; then
  cp -rf /config/.cache /.cache
  rm -r /config/.cache
fi
ln -sf /config/.cache /.cache

# Set ownership
bashio::log.info "Setting ownership to $PUID:$PGID"
chown -R "$PUID":"$PGID" "$LOCATION"
chmod -R 700 "$LOCATION"
