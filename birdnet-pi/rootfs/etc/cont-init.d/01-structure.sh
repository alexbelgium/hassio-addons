#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

##################
# ALLOW RESTARTS #
##################

if [[ "${BASH_SOURCE[0]}" == /etc/cont-init.d/* ]]; then
    mkdir -p /etc/scripts-init
    sed -i "s|/etc/cont-init.d|/etc/scripts-init|g" /ha_entrypoint.sh
    sed -i "/ rm/d" /ha_entrypoint.sh
    cp "${BASH_SOURCE[0]}" /etc/scripts-init/
fi

###############
# SET /CONFIG #
###############

bashio::log.info "Ensuring the file structure is correct:"

# Create default configuration files if not present
echo "... creating default files"
DEFAULT_FILES=("apprise.txt" "exclude_species_list.txt" "IdentifiedSoFar.txt" "disk_check_exclude.txt" "confirmed_species_list.txt" "blacklisted_images.txt" "whitelist_species_list.txt")
for file in "${DEFAULT_FILES[@]}"; do
    if [ ! -f "/config/$file" ]; then
        echo "" > "/config/$file"
    fi
done
touch /config/include_species_list.txt # Ensure this is always created

# Set BirdSongs folder location from configuration if specified
BIRDSONGS_FOLDER="/config/BirdSongs"
if bashio::config.has_value "BIRDSONGS_FOLDER"; then
    BIRDSONGS_FOLDER_OPTION="$(bashio::config "BIRDSONGS_FOLDER")"
    echo "... BIRDSONGS_FOLDER set to $BIRDSONGS_FOLDER_OPTION"
    mkdir -p "$BIRDSONGS_FOLDER_OPTION" || bashio::log.fatal "...... folder couldn't be created"
    chown -R pi:pi "$BIRDSONGS_FOLDER_OPTION" || bashio::log.fatal "...... folder couldn't be given permissions for 1000:1000"
    if [ -d "$BIRDSONGS_FOLDER_OPTION" ] && [ "$(stat -c '%u:%g' "$BIRDSONGS_FOLDER_OPTION")" == "1000:1000" ]; then
        BIRDSONGS_FOLDER="$BIRDSONGS_FOLDER_OPTION"
    else
        bashio::log.warning "BIRDSONGS_FOLDER reverted to /config/BirdSongs"
    fi
fi

# Create default folders
echo "... creating default folders; it is highly recommended to store these on an SSD"
mkdir -p "$BIRDSONGS_FOLDER/By_Date" "$BIRDSONGS_FOLDER/Charts"

# Use tmpfs if installed
if df -T /tmp | grep -q "tmpfs"; then
    echo "... tmpfs detected, using it for StreamData and Processed to reduce disk wear"
    mkdir -p /tmp/StreamData /tmp/Processed
    [ -d "$HOME/BirdSongs/StreamData" ] && rm -r "$HOME/BirdSongs/StreamData"
    [ -d "$HOME/BirdSongs/Processed" ] && rm -r "$HOME/BirdSongs/Processed"
    sudo -u pi ln -fs /tmp/StreamData "$HOME/BirdSongs/StreamData"
    sudo -u pi ln -fs /tmp/Processed "$HOME/BirdSongs/Processed"
fi

# Set permissions for created files and folders
echo "... setting permissions for user pi"
chown -R pi:pi /config /etc/birdnet "$BIRDSONGS_FOLDER" /tmp
chmod -R 755 /config /etc/birdnet "$BIRDSONGS_FOLDER" /tmp

# Backup default birdnet.conf for sanity check
cp "$HOME/BirdNET-Pi/birdnet.conf" "$HOME/BirdNET-Pi/birdnet.bak"

# Create default birdnet.conf if not existing
if [ ! -f /config/birdnet.conf ]; then
    cp -f "$HOME/BirdNET-Pi/birdnet.conf" /config/
fi

# Create default birds.db
if [ ! -f /config/birds.db ]; then
    echo "... creating initial db"
    "$HOME/BirdNET-Pi/scripts/createdb.sh"
    cp "$HOME/BirdNET-Pi/scripts/birds.db" /config/
elif [ "$(stat -c%s /config/birds.db)" -lt 10240 ]; then
    echo "... your db is corrupted, creating new one"
    rm /config/birds.db
    "$HOME/BirdNET-Pi/scripts/createdb.sh"
    cp "$HOME/BirdNET-Pi/scripts/birds.db" /config/
fi

# Symlink configuration files
echo "... creating symlinks for configuration files"
CONFIG_FILES=("$HOME/BirdNET-Pi/birdnet.conf" "$HOME/BirdNET-Pi/scripts/whitelist_species_list.txt" "$HOME/BirdNET-Pi/blacklisted_images.txt" "$HOME/BirdNET-Pi/scripts/birds.db" "$HOME/BirdNET-Pi/BirdDB.txt" "$HOME/BirdNET-Pi/scripts/disk_check_exclude.txt" "$HOME/BirdNET-Pi/apprise.txt" "$HOME/BirdNET-Pi/exclude_species_list.txt" "$HOME/BirdNET-Pi/include_species_list.txt" "$HOME/BirdNET-Pi/IdentifiedSoFar.txt" "$HOME/BirdNET-Pi/scripts/confirmed_species_list.txt")

for file in "${CONFIG_FILES[@]}"; do
    filename="${file##*/}"
    [ ! -f "/config/$filename" ] && touch "/config/$filename"
    [ -e "$file" ] && rm "$file"
    sudo -u pi ln -fs "/config/$filename" "$file"
    sudo -u pi ln -fs "/config/$filename" "$HOME/BirdNET-Pi/scripts/$filename"
    sudo -u pi ln -fs "/config/$filename" "/etc/birdnet/$filename"
done

# Symlink BirdSongs folders
for folder in By_Date Charts; do
    echo "... creating symlink for $BIRDSONGS_FOLDER/$folder"
    [ -d "$HOME/BirdSongs/Extracted/${folder:?}" ] && rm -r "$HOME/BirdSongs/Extracted/$folder"
    sudo -u pi ln -fs "$BIRDSONGS_FOLDER/$folder" "$HOME/BirdSongs/Extracted/$folder"
done

# Set permissions for newly created files and folders
echo "... checking and setting permissions"
chmod -R 755 /config/*
chmod 777 /config

# Create Matplotlib configuration directory
echo "... setting up Matplotlabdir"
MPLCONFIGDIR="${MPLCONFIGDIR:-$HOME/.config/matplotlib}"
mkdir -p "$MPLCONFIGDIR"
chown pi:pi "$MPLCONFIGDIR"
chmod 777 "$MPLCONFIGDIR"

