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
touch /config/IdentifiedSoFar.txt

# Set BirdSongs folder
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
echo "... creating default folders ; it is highly recommended to store those on a ssd"
mkdir -p "$BIRDSONGS_FOLDER"/By_Date
mkdir -p "$BIRDSONGS_FOLDER"/Charts

echo "... setting StreamData and Processed on tmpfs to reduce disk wear"
mkdir -p /tmp/StreamData
mkdir -p /tmp/Processed
rm -r "$HOME"/BirdSongs/StreamData
rm -r "$HOME"/BirdSongs/Processed
sudo -u pi ln -fs /tmp/StreamData "$HOME"/BirdSongs/StreamData
sudo -u pi ln -fs /tmp/Processed "$HOME"/BirdSongs/Processed

# Permissions
echo "... set permissions to user pi"
chown -R pi:pi /config /etc/birdnet "$BIRDSONGS_FOLDER" /tmp
chmod 664 /config/birds.db

# Symlink files
for files in "$HOME/BirdNET-Pi/birdnet.conf" "$HOME/BirdNET-Pi/scripts/birds.db" "$HOME/BirdNET-Pi/apprise.txt" "$HOME/BirdNET-Pi/exclude_species_list.txt" "$HOME/BirdNET-Pi/include_species_list.txt" "$HOME/BirdNET-Pi/IdentifiedSoFar.txt"; do
    filename="${files##*/}"
    echo "... creating symlink for $filename"
    if [ ! -f /config/"$filename" ]; then echo "... copying $filename" && sudo -u pi mv "$files" /config/; fi
    if [ -e "$files" ]; then rm "$files"; fi
    sudo -u pi ln -fs /config/"$filename" "$files"
    sudo -u pi ln -fs /config/"$filename" /etc/birdnet/"$filename"
    chmod 664 /config/*
done

# Symlink folders
for folders in Extracted/By_Date Extracted/Charts; do
    echo "... creating symlink for $BIRDSONGS_FOLDER/$folders"
    rm -r "$HOME/BirdSongs/${folders:?}"
    sudo -u pi ln -fs "$BIRDSONGS_FOLDER"/"$folders" "$HOME/BirdSongs/$folders"
done

##############
# SET SYSTEM #
##############

echo " "
bashio::log.info "Starting system services"

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    echo "... setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" >/etc/timezone
fi || (bashio::log.fatal "Error : $TIMEZONE not found. Here is a list of valid timezones : https://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html")

# Correcting systemctl
echo "... correcting systemctl"
curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /bin/systemctl
chmod a+x /bin/systemctl

# Starting dbus
echo "... starting dbus"
service dbus start

# Starting services
echo ""
bashio::log.info "Starting BirdNET-Pi services"
chmod +x "$HOME"/BirdNET-Pi/scripts/restart_services.sh
/."$HOME"/BirdNET-Pi/scripts/restart_services.sh &>/proc/1/fd/1

################
# MODIFY WEBUI #
################

echo " "
bashio::log.info "Adapting webui"

# Correct language labels
export "$(grep "^DATABASE_LANG" /config/birdnet.conf)" || exit 1
echo "... adapting labels according to birdnet.conf file to $DATABASE_LANG"
.$HOME/BirdNET-Pi/scripts/install_language_label_nm.sh -l "$DATABASE_LANG" || exit 1

# Remove services tab
echo "... removing System Controls from webui as should be used from HA"
sed -i '/>System Controls/d' "$HOME"/BirdNET-Pi/homepage/views.php

# Correct the phpsysinfo for the correct gotty service
gottyservice="$(pgrep -l "gotty" | awk '{print $NF}' | head -n 1)"
echo "... using $gottyservice in phpsysinfo"
sed -i "s/,gotty,/,${gottyservice:-gotty},/g" "$HOME"/BirdNET-Pi/templates/phpsysinfo.ini

bashio::log.info "Starting upstream container"
