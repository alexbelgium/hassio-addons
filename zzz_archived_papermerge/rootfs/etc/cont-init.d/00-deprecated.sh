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

sleep 5
