#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

##############
# SET SYSTEM #
##############

echo " "
bashio::log.info "Setting password for the user pi"
echo "pi:$(bashio::config "pi_password")" | sudo chpasswd
echo "... done"

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
mv /helpers/systemctl3.py /bin/systemctl
chmod a+x /bin/systemctl

# Correcting systemctl
echo "... correcting datetimectl"
mv /helpers/timedatectl /usr/bin/timedatectl
chmod a+x /usr/bin/timedatectl

# Correct language labels
export "$(grep "^DATABASE_LANG" /config/birdnet.conf)"
# Saving default of en
cp "$HOME"/BattyBirdNET-Analyzer/model/labels.txt "$HOME"/BattyBirdNET-Analyzer/model/labels.bak
# Adapt to new language
echo "... adapting labels according to birdnet.conf file to $DATABASE_LANG"
/."$HOME"/BattyBirdNET-Analyzer/scripts/install_language_label_nm.sh -l "$DATABASE_LANG"

echo "... starting cron"
systemctl start cron

# Starting dbus
echo "... starting dbus"
service dbus start

# Starting journald
# echo "... starting journald"
# systemctl start systemd-journald

# Starting services
echo ""
bashio::log.info "Starting battyBattyBirdNET-Analyzer services"
chmod +x "$HOME"/BattyBirdNET-Analyzer/scripts/restart_services.sh
"$HOME"/BattyBirdNET-Analyzer/scripts/restart_services.sh

if bashio::config.true LIVESTREAM_BOOT_ENABLED; then
    echo "... starting livestream"
    sudo systemctl enable icecast2
    sudo systemctl start icecast2.service
    sudo systemctl enable --now livestream.service
fi

# Correct the phpsysinfo for the correct gotty service
gottyservice="$(pgrep -l "gotty" | awk '{print $NF}' | head -n 1)"
echo "... using $gottyservice in phpsysinfo"
sed -i "s/,gotty,/,${gottyservice:-gotty},/g" "$HOME"/BattyBirdNET-Analyzer/templates/phpsysinfo.ini

echo " "
