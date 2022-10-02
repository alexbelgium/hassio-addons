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
mkdir -p "$CONFIGSOURCE"/db "$CONFIGSOURCE"/html "$CONFIGSOURCE"/pdf
cp -rnf /opt/tplink/EAPController/data/* "$CONFIGSOURCE"

# Make sure permissions are right
echo "Updating permissions"
chown -R "508:508" "$CONFIGSOURCE"

# Delete previous directories
echo "Removing previous directories"
rm -r /opt/tplink/EAPController/data/html
rm -r /opt/tplink/EAPController/data/pdf
rm -r /opt/tplink/EAPController/data/db

# Create symlink
echo "Creating symlink"
ln -s /config/addons_config/omada/pdf /opt/tplink/EAPController/data/pdf
ln -s /config/addons_config/omada/html /opt/tplink/EAPController/data/html
ln -s /config/addons_config/omada/db /opt/tplink/EAPController/data/db
