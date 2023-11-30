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

# Migrate data
if [ -d /data/db ]; then
    mv /data/* "$CONFIGSOURCE"/
    mv "$CONFIGSOURCE"/options.json /data/
fi

# Ensure structure is correct
cp -rnf /opt/tplink/EAPController/data/* "$CONFIGSOURCE/"

echo "Creating symlink"
# Clean existing folder
rm -r /opt/tplink/EAPController/data/*

# Create folders if not existing
for item in db html keystore html logs properties properties.default pdf db portal; do
    mkdir -p "$CONFIGSOURCE/$item"
fi

# Create symlinks for all files in /data
# shellcheck disable=SC2086
for item in "$CONFIGSOURCE"/*; do
    # Extract the base name of the item
    base_name=$(basename "$item")
    # Create a symbolic link in the initial directory
    ln -s "$item" "/opt/tplink/EAPController/data/$base_name"
done

# Make sure permissions are right
echo "Updating permissions"
chmod -R 777 "$CONFIGSOURCE"
chown -R "508:508" "$CONFIGSOURCE"
chown -R "508:508" "/opt/tplink/EAPController/data"

echo ""
echo ""
echo "Recommendation : please backup your database and migrated to this addon https://github.com/jkunczik/home-assistant-omada"
echo ""
echo ""
