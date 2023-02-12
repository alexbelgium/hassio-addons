#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2046

# Define user
PUID=$(bashio::config "PUID")
PGID=$(bashio::config "PGID")

# Check data location
LOCATION=$(bashio::config 'data_location')

if [[ "$LOCATION" = "null" || -z "$LOCATION" ]]; then
    # Default location
    LOCATION="/share/webtop_kde"
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
        LOCATION=/config/addons_config/${HOSTNAME#*-}
        bashio::log.fatal "Your data_location value can only be set in /share, /config or /data (internal to addon). It will be reset to the default location : $LOCATION"
    fi

fi

# Set data location
bashio::log.info "Setting data location to $LOCATION"

sed -i "1a export HOME=$LOCATION" /etc/s6-overlay/s6-rc.d/svc-web/run || true
sed -i "1a export FM_HOME=$LOCATION" /etc/s6-overlay/s6-rc.d/svc-web/run || true
sed -i "s|/share/webtop_kde|$LOCATION|g" $(find /defaults -type f) || true
sed -i "s|/share/webtop_kde|$LOCATION|g" $(find /etc/cont-init.d -type f) || true
sed -i "s|/share/webtop_kde|$LOCATION|g" $(find /etc/services.d -type f) || true
sed -i "s|/share/webtop_kde|$LOCATION|g" $(find /etc/s6-overlay/s6-rc.d -type f) || true
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" > /var/run/s6/container_environment/HOME; fi
if [ -d /var/run/s6/container_environment ]; then printf "%s" "$LOCATION" > /var/run/s6/container_environment/FM_HOME; fi

usermod --home "$LOCATION" abc

# Create folder
echo "Creating $LOCATION"
mkdir -p "$LOCATION"

# Set ownership
bashio::log.info "Setting ownership to $PUID:$PGID"
chown "$PUID":"$PGID" "$LOCATION"
