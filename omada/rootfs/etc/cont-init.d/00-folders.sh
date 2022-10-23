#!/bin/bash
# shellcheck shell=bash

CONFIGSOURCE="/config/addons_config/omada"

# Use ssl
if [ -d /ssl ]; then
    mkdir -p /cert
    cp /ssl/* /cert
    chown -R 508:508 /cert
fi

# Create directory
if [ ! -f "$CONFIGSOURCE" ]; then
    echo "Creating directory"
    mkdir -p "$CONFIGSOURCE"
fi

# Ensure structure is correct
cp -rnf /opt/tplink/EAPController/data/* "$CONFIGSOURCE"

echo "Creating symlink"
rm -r /opt/tplink/EAPController/data/*

mkdir -p "$CONFIGSOURCE"/pdf
mkdir -p "$CONFIGSOURCE"/omada/html
mkdir -p "$CONFIGSOURCE"/db
mkdir -p "$CONFIGSOURCE"/map
mkdir -p "$CONFIGSOURCE"/portal

ln -s "$CONFIGSOURCE"/pdf /opt/tplink/EAPController/data
ln -s "$CONFIGSOURCE"/omada/html /opt/tplink/EAPController/data
ln -s "$CONFIGSOURCE"/db /opt/tplink/EAPController/data
ln -s "$CONFIGSOURCE"/map /opt/tplink/EAPController/data
ln -s "$CONFIGSOURCE"/portal /opt/tplink/EAPController/data

# Make sure permissions are right
echo "Updating permissions"
chmod -R 777 "$CONFIGSOURCE"
chown -R "508:508" "$CONFIGSOURCE"
