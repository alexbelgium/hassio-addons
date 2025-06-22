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
bashio::log.yellow "This addon is now supported in the official HA community repository. You should migrate your data as soon as possible! This addon will not be supported and updates might stop in the future."
bashio::log.yellow "You'll likely get better support as the official community is supported by the HA devs ! If some features from the official add-on are missing you should raise a request on the ha community add-ons repo"
bashio::log.yellow "Thanks for all users over the years !"
echo ""

sleep 5
