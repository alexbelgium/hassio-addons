#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Uprade
echo "Updating distribution"
apt-get update &>/dev/null || apk update &>/dev/null || true
apt-get -y upgrade &>/dev/null || apk upgrade &>/dev/null || true

# Fix mate software center
if [ -f /usr/lib/dbus-1.0/dbus-daemon-launch-helper ]; then
  echo "Allow software center"
  chmod u+s /usr/lib/dbus-1.0/dbus-daemon-launch-helper
  service dbus restart
fi

# Add repositories
if bashio::config.true 'edge_repositories'; then
  { echo "https://dl-cdn.alpinelinux.org/alpine/edge/community";
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing";
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/main";
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/releases"; } > /etc/apk/repositories
else
  { echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/community";
  echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main";
  echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases"; } > /etc/apk/repositories
fi

# Install specific apps
if bashio::config.has_value 'additional_apps'; then
  bashio::log.info "Installing additional apps :"
  # hadolint ignore=SC2005
  NEWAPPS=$(bashio::config 'additional_apps')
  for APP in ${NEWAPPS//,/ }; do
    bashio::log.green "... $APP"
    apk add --no-cache "$APP" &>/dev/null || apt-get install -yqq "$APP" &>/dev/null \
    # shellcheck disable=SC2015
    && bashio::log.green "... done" || bashio::log.red "... not successful, please check package name"
  done
fi
