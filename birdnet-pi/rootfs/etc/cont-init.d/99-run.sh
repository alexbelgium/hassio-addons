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
chown -R 1000:1000 /config /etc/birdnet
for files in "$HOME/BirdNET-Pi/birdnet.conf" "$HOME/BirdNET-Pi/scripts/birds.db"; do
    filename="${files##*/}"
    echo "... setting $filename"
    if [ ! -f /config/"$filename" ]; then echo "... copying $filename" && sudo -u pi mv "$files" /config/; fi
    if [ -e "$files" ]; then rm "$files"; fi
    chmod 777 /config/*
    sudo -u pi ln -fs /config/"$filename" "$files"
    sudo -u pi ln -fs /config/"$filename" /etc/birdnet/"$filename"
done

for files in "apprise.txt"
    if [ -f "$files" ]; then
        echo "... /config/$files exists, it will be sent to BirdNET"  
    else
        echo "... /config/$files does not exist, if created before restarting it will be sent to BirdNET"  
    fi
done

# Starting services
bashio::log.info "Starting BirdNET-Pi services"
chmod +x "$HOME"/BirdNET-Pi/scripts/restart_services.sh
/."$HOME"/BirdNET-Pi/scripts/restart_services.sh &>/proc/1/fd/1

bashio::log.info "App is accessible from webui"
