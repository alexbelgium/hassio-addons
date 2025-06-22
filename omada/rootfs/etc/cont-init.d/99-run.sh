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

# Migrate previous files
mkdir -p /config/data
mv /data/* /config/data

# Copy container files
cp -rnf /opt/tplink/EAPController/data/* "$CONFIGSOURCE"
rm -r /opt/tplink/EAPController/data/*

# Create symlinks
echo "Creating symlink"

# Create potentially missing folers
for folders in html keystore pdf db portal; do
	mkdir -p "$CONFIGSOURCE/$folders"
done
touch /config/LAST_RAN_OMADA_VER.txt

# Create symlinks for all files in /data
for item in "$CONFIGSOURCE"/*; do
	# Get the base name of the file or folder
	base_name=$(basename "$item")
	# Create a symbolic link in the current working directory
	ln -s "$item" /opt/tplink/EAPController/data/"$base_name"
	echo "Created symlink for '$base_name'"
done

# Create logfile
touch /config/server.log
ln -s /config/server.log /opt/tplink/EAPController/logs/server.log

# Make sure permissions are right
echo "Updating permissions"
chmod -R 777 "$CONFIGSOURCE"
chown -R "508:508" "$CONFIGSOURCE"
chown -R "508:508" /opt/tplink/EAPController

echo ""
echo ""
echo "Recommendation : please backup your database and migrated to this addon https://github.com/jkunczik/home-assistant-omada"
echo ""
echo ""
