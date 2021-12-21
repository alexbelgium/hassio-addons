#!/bin/bash

echo "Installing pikepdf..." 
(apt-get update
apt-get install -yqq libxml2-dev libxslt-dev python-dev libjpeg-dev zlib1g-dev python3-dev build-essential
pip install pikepdf --force-reinstall) >/dev/null
echo "... success!" 
