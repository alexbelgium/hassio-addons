#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Ensures all scripts are up-to-date
# ==============================================================================

if [ -d /etc/cont-init.d ]; then
  # Check if downloads possible
  wget -NS https://example.com/ &>/dev/null || exit 0

  # Check scripts
  cd /etc/cont-init.d || true
  for scripts in *; do
    # If newer file, download to directory
    wget -NS --content-disposition "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/$scripts" &>/dev/null || true
  done
fi
