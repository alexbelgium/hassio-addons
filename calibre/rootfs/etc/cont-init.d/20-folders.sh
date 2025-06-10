#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046
set -e

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
LOCATION=$(bashio::config 'data_location')

if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
	# Default location
	LOCATION="/config"
else
	bashio::log.warning "Warning : a custom data location was selected, but the previous folder will NOT be copied. You need to do it manually"

	# Check if config is located in an acceptable location
	LOCATIONOK=""
	for location in "/share" "/config" "/data" "/mnt"; do
		if [[ "$LOCATION" == "$location"* ]]; then
			LOCATIONOK=true
		fi
	done

	if [ -z "$LOCATIONOK" ]; then
		LOCATION="/config"
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
		sed -i "s|/config|$LOCATION|g" $(find "$folders" -type f) &>/dev/null || true
	fi
done

#  Change user home
usermod --home "$LOCATION" abc

# Add environment variables
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" >/var/run/s6/container_environment/HOME; fi
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" >/var/run/s6/container_environment/FM_HOME; fi
{
	printf "%s\n" "HOME=\"$LOCATION\""
	printf "%s\n" "FM_HOME=\"$LOCATION\""
} >>~/.bashrc

# Create folder
echo "Creating $LOCATION"
mkdir -p "$LOCATION"

# Set ownership
bashio::log.info "Setting ownership to $PUID:$PGID"
chown -R "$PUID":"$PGID" "$LOCATION"
chmod -R 755 "$LOCATION"
mkdir -p "$LOCATION"/.XDG
chmod -R 700 "$LOCATION"/.XDG
