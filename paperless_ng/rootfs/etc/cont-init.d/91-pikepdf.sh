#!/bin/bash

echo "Installing pikepdf..."
(apt-get update
apt-get install -yq libxml2-dev libxslt-dev python-dev
apt-get install -yq libjpeg-dev zlib1g-dev
apt-get install -yq python3-dev build-essential -y && \
pip install -yq pikepdf==2.16.1 --force-reinstall
 
pip install pikepdf --force-reinstall) >/dev/null
echo "... success!" 
