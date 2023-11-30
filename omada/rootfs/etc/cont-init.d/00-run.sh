#!/bin/bash
# shellcheck shell=bash
set -e

CONFIGSOURCE="/config"

# Use ssl
if [ -d /ssl ]; then
    mkdir -p /cert
    cp -r /ssl/* /cert
    chown -R 508:508 /cert
fi

# Create directory
if [ ! -f "$CONFIGSOURCE" ]; then
    echo "Creating directory"
    mkdir -p "$CONFIGSOURCE"
fi

# Create new global directory
mkdir -p /opt/tplink/EAPController2
cp -rnf /opt/tplink/EAPController /opt/tplink/EAPController2
rm -r /opt/tplink/EAPController || true

# Migrate data
if [ -d /data/db ]; then
    mv /data/* "$CONFIGSOURCE"/
    mv "$CONFIGSOURCE"/options.json /data/
fi

# Ensure structure is correct
cp -rnf /opt/tplink/EAPController/data/* "$CONFIGSOURCE/"

# Symlink data folder
echo "Creating symlink"
rm -r /opt/tplink/EAPController2/data || true
ln -s "$CONFIGSOURCE" /opt/tplink/EAPController2/data

# Make sure permissions are right
echo "Updating permissions"
chmod -R 777 "$CONFIGSOURCE"
chown -R "508:508" "$CONFIGSOURCE"
chown -R "508:508" "/opt/tplink/EAPController2"

echo ""
echo ""
echo "Recommendation : please backup your database and migrated to this addon https://github.com/jkunczik/home-assistant-omada"
echo ""
echo ""
