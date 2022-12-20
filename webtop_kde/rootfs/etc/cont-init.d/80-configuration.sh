#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015

# Add Edge repositories
if bashio::config.true 'edge_repositories'; then
    bashio::log.info "Changing app repositories to edge"
    { echo "https://dl-cdn.alpinelinux.org/alpine/edge/community";
        echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing";
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/main"; } > /etc/apk/repositories
fi

# Install rpi video drivers
if bashio::config.true 'rpi_video_drivers'; then
    bashio::log.info "Installing Rpi graphic drivers"
    apk add --no-cache mesa-dri-vc4 mesa-dri-swrast mesa-gbm xf86-video-fbdev >/dev/null && bashio::log.green "... done" ||
    bashio::log.red "... not successful. Are you on a rpi?"
fi

# Fix mate software center
if [ -f /usr/lib/dbus-1.0/dbus-daemon-launch-helper ]; then
    echo "Allow software center"
    chmod u+s /usr/lib/dbus-1.0/dbus-daemon-launch-helper
    service dbus restart
fi

# Install specific apps
if bashio::config.has_value 'additional_apps'; then
    bashio::log.info "Installing additional apps :"
    # hadolint ignore=SC2005
    NEWAPPS=$(bashio::config 'additional_apps')
    for APP in ${NEWAPPS//,/ }; do
        bashio::log.green "... $APP"
        # shellcheck disable=SC2015
        apk add --no-cache "$APP" >/dev/null || bashio::log.red "... not successful, please check package name"
    done
fi

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime && echo "$TIMEZONE" >/etc/timezone
fi

# Set keyboard
if bashio::config.has_value 'KEYBOARD'; then
    KEYBOARD=$(bashio::config 'KEYBOARD')
    bashio::log.info "Setting keyboard to $KEYBOARD"
    sed -i "1a export KEYBOARD=$KEYBOARD" /etc/s6-overlay/s6-rc.d/svc-web/run
fi

# Set password
if bashio::config.has_value 'PASSWORD'; then
    bashio::log.info "Setting password to the value defined in options"
    PASSWORD=$(bashio::config 'PASSWORD')
    passwd -d abc
    echo -e "$PASSWORD\n$PASSWORD" | passwd abc
fi
