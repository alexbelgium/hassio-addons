#!/bin/bash
# shellcheck shell=bash
set -e

CONFIGSOURCE="/data"

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

# Ensure structure is correct
cp -rnf /opt/tplink/EAPController/data/* "$CONFIGSOURCE"

echo "Creating symlink"
# Clean existing folder
rm -r /opt/tplink/EAPController/data/*

# Create symlinks for all files in /data
for files in $(ls -d "$CONFIGSOURCE"/*); do
    if [ -e "$files" ]; then
        ln -s "$files" /opt/tplink/EAPController/data
    fi
done

# Make sure permissions are right
echo "Updating permissions"
chmod -R 777 "$CONFIGSOURCE"
chown -R "508:508" "$CONFIGSOURCE"
