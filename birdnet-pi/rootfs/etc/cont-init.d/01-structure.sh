#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

###############
# SET /CONFIG #
###############

echo " "
bashio::log.info "Ensuring the file structure is correct :"

# Define structure
echo "... creating default files"
touch /config/apprise.txt
touch /config/include_species_list.txt
touch /config/exclude_species_list.txt
if [ ! -f /config/IdentifiedSoFar.txt ]; then echo "" > /config/IdentifiedSoFar.txt; fi
if [ ! -f /config/disk_check_exclude.txt ]; then echo "" > /config/disk_check_exclude.txt; fi # Using touch caused an issue with stats.php

# Get BirdSongs folder locations
BIRDSONGS_FOLDER="/config/BirdSongs"
if bashio::config.has_value "BIRDSONGS_FOLDER"; then
    BIRDSONGS_FOLDER_OPTION="$(bashio::config "BIRDSONGS_FOLDER")"
    echo "... BIRDSONGS_FOLDER set to $BIRDSONGS_FOLDER_OPTION"
    mkdir -p "$BIRDSONGS_FOLDER_OPTION" || bashio::log.fatal "...... folder couldn't be created"
    chown -R pi:pi "$BIRDSONGS_FOLDER_OPTION" || bashio::log.fatal "...... folder couldn't be given permissions for 1000:1000"
    if [ -d "$BIRDSONGS_FOLDER_OPTION" ] && [ "$(stat -c '%u:%g' "$BIRDSONGS_FOLDER_OPTION")" == "1000:1000" ]; then
        BIRDSONGS_FOLDER="$BIRDSONGS_FOLDER_OPTION"
    else
        bashio::log.yellow "BIRDSONGS_FOLDER reverted to /config/BirdSongs"
    fi
fi

# Create BirdSongs folder
echo "... creating default folders ; it is highly recommended to store those on a ssd"
mkdir -p "$BIRDSONGS_FOLDER"/By_Date
mkdir -p "$BIRDSONGS_FOLDER"/Charts

# If tmpfs is installed, use it
if df -T /tmp | grep -q "tmpfs"; then
    echo "... tmpfs detected, using it for StreamData and Processed to reduce disk wear"
    mkdir -p /tmp/StreamData
    mkdir -p /tmp/Processed
    rm -r "$HOME"/BirdSongs/StreamData
    rm -r "$HOME"/BirdSongs/Processed
    sudo -u pi ln -fs /tmp/StreamData "$HOME"/BirdSongs/StreamData
    sudo -u pi ln -fs /tmp/Processed "$HOME"/BirdSongs/Processed
fi

# Permissions for created files and folders
echo "... set permissions to user pi"
chown -R pi:pi /config /etc/birdnet "$BIRDSONGS_FOLDER" /tmp
chmod -R 755 /config /config /etc/birdnet "$BIRDSONGS_FOLDER" /tmp

# Save default birdnet.conf to perform sanity check
cp "$HOME"/BirdNET-Pi/birdnet.conf "$HOME"/BirdNET-Pi/birdnet.bak

# Symlink files
echo "... creating symlink"
for files in "$HOME/BirdNET-Pi/birdnet.conf" "$HOME/BirdNET-Pi/scripts/birds.db" "$HOME/BirdNET-Pi/scripts/disk_check_exclude.txt" "$HOME/BirdNET-Pi/apprise.txt" "$HOME/BirdNET-Pi/exclude_species_list.txt" "$HOME/BirdNET-Pi/include_species_list.txt" "$HOME/BirdNET-Pi/IdentifiedSoFar.txt"; do
    filename="${files##*/}"
    if [ ! -f /config/"$filename" ]; then echo "... copying $filename" && sudo -u pi mv "$files" /config/; fi
    if [ -e "$files" ]; then rm "$files"; fi
    sudo -u pi ln -fs /config/"$filename" "$files" || bashio::log.fatal "Symlink creation failed for $filename"
    sudo -u pi ln -fs /config/"$filename" /etc/birdnet/"$filename" || bashio::log.fatal "Symlink creation failed for $filename"
done

# Symlink folders
for folders in By_Date Charts; do
    echo "... creating symlink for $BIRDSONGS_FOLDER/$folders"
    rm -r "$HOME/BirdSongs/Extracted/${folders:?}"
    sudo -u pi ln -fs "$BIRDSONGS_FOLDER"/"$folders" "$HOME/BirdSongs/Extracted/$folders"
done

# Permissions for created files and folders
echo "... check permissions"
chmod -R 755 /config/*
chmod 777 /config

echo " "
