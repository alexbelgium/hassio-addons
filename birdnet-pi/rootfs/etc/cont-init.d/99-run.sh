#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# INITALISATION #
#################

# Correcting systemctl
curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /bin/systemctl
chmod a+x /bin/systemctl

# Starting dbus
bashio::log.info "Starting system services..."
echo "... dbus"
service dbus start

# Symlink files
bashio::log.info "Ensuring files are in /config ; please customize as needed"
for files in /etc/birdnet/birdnet.conf "$HOME/BirdNET-Pi/scripts/birds.db"; do
    filename="${files##*/}"
    if [ ! -f /config/"$filename" ]; then cp "$files" /config/; fi
    if [ -f "$files" ]; then rm "$files"; fi
    chown 1000:1000 /config/"$filename"
    ln -s /config/"$filename" "$files"
    chown 1000:1000 -h "$files"
done

# Starting services
bashio::log.info "Starting BirdNET-Pi services"
chmod +x "$HOME"/BirdNET-Pi/scripts/restart_services.sh
/."$HOME"/BirdNET-Pi/scripts/restart_services.sh &>/proc/1/fd/1

bashio::log.info "App is accessible from webui"
