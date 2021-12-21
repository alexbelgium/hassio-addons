#!/bin/bash

echo "Installing pikepdf..." 
apt-get install libxml2-dev libxslt-dev python-dev

apt-get install libjpeg-dev zlib1g-dev

apt-get install python3-dev build-essential -y && \
pip install pikepdf==2.16.1 --force-reinstall

echo "... success!" 
