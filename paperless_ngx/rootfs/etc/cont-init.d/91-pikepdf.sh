#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

echo "Installing pikepdf..."
(
    export DEBIAN_FRONTEND="noninteractive"
    export TERM="xterm-256color"
    apt-get update
    apt-get install -yq libxml2-dev libxslt-dev python-dev
    apt-get install -yq libjpeg-dev zlib1g-dev
    apt-get install -yq python3-dev build-essential
    pip install pikepdf --force-reinstall
) >/dev/null
echo "... success!"
