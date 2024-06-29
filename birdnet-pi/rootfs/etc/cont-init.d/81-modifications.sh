#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

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

# Correct services to start as user pi
echo "... correct services to start as pi"
for file in $(find "$HOME"/BirdNET-Pi/templates/birdnet*.service -print0 | xargs -0 basename -a) livestream.service chart_viewer.service chart_viewer.service spectrogram_viewer.service; do
    if [[ "$file" != "birdnet_log.service" ]]; then
        sed -i "s|ExecStart=|ExecStart=/usr/bin/sudo -u pi |g" "$HOME/BirdNET-Pi/templates/$file"
    fi
done

# Remove pulseaudio server to force using HA one
echo "... remove embedded pulseaudio"
# shellcheck disable=SC2013
for file in $(grep -srl "pulseaudio --start" "$HOME"/BirdNET-Pi/scripts); do
    sed -i "/pulseaudio --start/d" "$file"
done

# Send services log to container logs
echo "... send services log to container logs"
for file in $(find "$HOME"/BirdNET-Pi/templates/birdnet*.service -print0 | xargs -0 basename -a) livestream.service chart_viewer.service chart_viewer.service spectrogram_viewer.service; do
    sed -i "/Service/a StandardError=append:/proc/1/fd/1" "$HOME/BirdNET-Pi/templates/$file"
    sed -i "/Service/a StandardOutput=append:/proc/1/fd/1" "$HOME/BirdNET-Pi/templates/$file"
done

# Avoid preselection in include and exclude lists
echo "... avoid preselecting options in include and exclude lists"
sed -i "s|option selected|option disabled|g" "$HOME"/BirdNET-Pi/scripts/include_list.php
sed -i "s|option selected|option disabled|g" "$HOME"/BirdNET-Pi/scripts/exclude_list.php

# Correct log services to show /proc/1/fd/1
echo "... show container logs in /logs"
sed -i "/User=pi/d" "$HOME/BirdNET-Pi/templates/birdnet_log.service"
sed -i "s|birdnet_log.sh|cat /proc/1/fd/1|g" "$HOME/BirdNET-Pi/templates/birdnet_log.service"

# Make sure config is correctly formatted.
echo "... caddyfile modifications"
#Correct instructions
caddy fmt --overwrite /etc/caddy/Caddyfile
#Change port to leave 80 free for certificate requests
sed -i "s|http://|http://:8081|g" /etc/caddy/Caddyfile
sed -i "s|http://|http://:8081|g" "$HOME"/BirdNET-Pi/scripts/update_caddyfile.sh
#Remove default file that blocks 80
if [ -f /etc/caddy/Caddyfile.original ]; then rm /etc/caddy/Caddyfile.original; fi

# Improve webui paths to facilitate ingress
echo "... correcting webui paths"
sed -i "s|/stats|/stats/|g" "$HOME"/BirdNET-Pi/homepage/views.php
sed -i "s|/log|/log/|g" "$HOME"/BirdNET-Pi/homepage/views.php

# If port 80 is enabled, make sure it is still 80
if [ -n "$(bashio::addon.port 80)" ] && [ "$(bashio::addon.port 80)" != 80 ]; then
    bashio::log.fatal "The port 80 is enabled, but should still be 80 if you want the automatic ssl certificates generation to work"
fi

echo " "
