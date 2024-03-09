#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# ==============================================================================
# Displays a simple add-on banner on startup
# ==============================================================================

echo ""
bashio::log.yellow "####################"
bashio::log.yellow "# ADDON deprecated #"
bashio::log.yellow "####################"
echo ""
bashio::log.yellow "A better alternative is existing for paperless NGX managed by BenoitAnastay : https://github.com/BenoitAnastay/home-assistant-addons-repository"
bashio::log.yellow "It is recommended to transfer to his version that will be more robust and include ingress"
bashio::log.yellow "Thanks for all users over the years !"
echo ""

sleep 5
