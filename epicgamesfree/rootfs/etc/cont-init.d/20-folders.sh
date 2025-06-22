#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Define home
HOME="/config/addons_config/epicgamesfree"
mkdir -p $HOME
chmod -R 777 $HOME
