#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

######################
# CHECK BIRDNET.CONF #
######################

echo " "
bashio::log.info "Checking your birndet.conf file integrity"

# Set variables
configcurrent="$HOME"/BirdNET-Pi/birdnet.conf
configtemplate="$HOME"/BirdNET-Pi/birdnet.bak

# Extract variable names from config template and read each one
grep -o '^[^#=]*=' "$configtemplate" | sed 's/=//' | while read -r var; do
    # Check if the variable is in configcurrent, if not, append it
    if ! grep -q "^$var=" "$configcurrent"; then
        # At which line was the variable in the initial file
        bashio::log.yellow "...$var was missing from your birdnet.conf file, it was re-added"
        grep "^$var=" "$configtemplate" >> "$configcurrent"
    fi
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

# Correct language labels
export "$(grep "^DATABASE_LANG" /config/birdnet.conf)"
echo "... adapting labels according to birdnet.conf file to $DATABASE_LANG"
/."$HOME"/BirdNET-Pi/scripts/install_language_label_nm.sh -l "$DATABASE_LANG"

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

# Remove services tab
echo "... removing System Controls from webui as should be used from HA"
sed -i '/>System Controls/d' "$HOME"/BirdNET-Pi/homepage/views.php

# Remove services tab
echo "... removing Ram drive from webui as it is handled from HA"
sed -i '/Ram drive/{n;s/center"/center" style="display: none;"/;}' "$HOME"/BirdNET-Pi/scripts/service_controls.php
sed -i '/Ram drive/d' "$HOME"/BirdNET-Pi/scripts/service_controls.php

# Correct the phpsysinfo for the correct gotty service
gottyservice="$(pgrep -l "gotty" | awk '{print $NF}' | head -n 1)"
echo "... using $gottyservice in phpsysinfo"
sed -i "s/,gotty,/,${gottyservice:-gotty},/g" "$HOME"/BirdNET-Pi/templates/phpsysinfo.ini

bashio::log.info "Starting upstream container"
