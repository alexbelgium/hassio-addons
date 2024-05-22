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
curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /bin/systemctl
chmod a+x /bin/systemctl

# Correct language labels
export "$(grep "^DATABASE_LANG" /config/birdnet.conf)"
# Saving default of en
cp "$HOME"/BirdNET-Pi/model/labels.txt "$HOME"/BirdNET-Pi/model/labels.bak
# Adapt to new language
echo "... adapting labels according to birdnet.conf file to $DATABASE_LANG"
/."$HOME"/BirdNET-Pi/scripts/install_language_label_nm.sh -l "$DATABASE_LANG"

echo "... starting cron"
service cron start

# Starting dbus
echo "... starting dbus"
service dbus start

# Starting journald
# echo "... starting journald"
# systemctl start systemd-journald

# Starting services
echo ""
bashio::log.info "Starting BirdNET-Pi services"
chmod +x "$HOME"/BirdNET-Pi/scripts/restart_services.sh
"$HOME"/BirdNET-Pi/scripts/restart_services.sh

# Correct the phpsysinfo for the correct gotty service
gottyservice="$(pgrep -l "gotty" | awk '{print $NF}' | head -n 1)"
echo "... using $gottyservice in phpsysinfo"
sed -i "s/,gotty,/,${gottyservice:-gotty},/g" "$HOME"/BirdNET-Pi/templates/phpsysinfo.ini

echo " "
