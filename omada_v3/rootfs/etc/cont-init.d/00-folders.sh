#!/bin/bash
# shellcheck shell=bash

CONFIGSOURCE="/config/addons_config/omada_v3"

# Create directory
if [ ! -f "$CONFIGSOURCE" ]; then
    echo "Creating directory"
    mkdir -p "$CONFIGSOURCE"
fi

# Ensure structure is correct
cp -rnf /opt/tplink/EAPController/data/* "$CONFIGSOURCE"

# Make sure permissions are right
echo "Updating permissions"
chown -R "508:508" "$CONFIGSOURCE"

echo "Creating symlink"
rm -r /opt/tplink/EAPController/data/*

mkdir -p "$CONFIGSOURCE"/pdf
mkdir -p "$CONFIGSOURCE"/omada/html
mkdir -p "$CONFIGSOURCE"/db

ln -s "$CONFIGSOURCE"/pdf /opt/tplink/EAPController/data/pdf
ln -s "$CONFIGSOURCE"/omada/html /opt/tplink/EAPController/data/html
ln -s "$CONFIGSOURCE"/db /opt/tplink/EAPController/data/db
