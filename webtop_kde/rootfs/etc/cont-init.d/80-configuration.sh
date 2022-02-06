#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Set repositories
  { echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/community";
  echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main";
  echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases"; 
  echo "https://alpine.global.ssl.fastly.net/alpine/latest-stable/community";
  echo "https://alpine.global.ssl.fastly.net/alpine/latest-stable/main";
  echo "https://alpine.global.ssl.fastly.net/alpine/latest-stable/releases"; } > /etc/apk/repositories

# Uprade
echo "Updating distribution"
apk update &>/dev/null || apt-get update &>/dev/null || true
apk upgrade &>/dev/null || apt-get -y upgrade &>/dev/null || true

# Fix mate software center
if [ -f /usr/lib/dbus-1.0/dbus-daemon-launch-helper ]; then
  echo "Allow software center"
  chmod u+s /usr/lib/dbus-1.0/dbus-daemon-launch-helper
  service dbus restart
fi

# Add Edge repositories
if bashio::config.true 'edge_repositories'; then
{ echo "https://dl-cdn.alpinelinux.org/alpine/edge/community";
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing";
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/main";
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/releases"; } > /etc/apk/repositories
fi

# Install rpi video drivers
if bashio::config.true 'rpi_video_drivers'; then
  bashio::log.info "Installing Rpi graphic drivers"
  apk add --no-cache mesa-dri-vc4 mesa-dri-swrast mesa-gbm xf86-video-fbdev >/dev/null && bashio::log.green "... done" || 
  bashio::log.red "... not successful"
fi

# Install specific apps
if bashio::config.has_value 'additional_apps'; then
  bashio::log.info "Installing additional apps :"
  # hadolint ignore=SC2005
  NEWAPPS=$(bashio::config 'additional_apps')
  for APP in ${NEWAPPS//,/ }; do
    bashio::log.green "... $APP"
    # shellcheck disable=SC2015
    apk add --no-cache "$APP" &>/dev/null || apt-get install -yqq "$APP" &>/dev/null \
    && bashio::log.green "... done" || bashio::log.red "... not successful, please check package name"
  done
fi
