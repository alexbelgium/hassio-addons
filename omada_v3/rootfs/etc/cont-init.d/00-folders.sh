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

for d in /opt/tplink/EAPController/data/*/ ; do
    echo "Moving $d"
    rm -r "$d"
    mkdir -p "$CONFIGSOURCE/$(basename $d)"
    ln -s "$CONFIGSOURCE/$(basename $d)" "$d"
done
