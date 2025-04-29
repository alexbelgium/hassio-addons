#!/command/with-contenv bashio
# shellcheck shell=bash disable=SC2016
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

################
# MODIFY WEBUI #
################

bashio::log.info "Adapting webui"

# HA specific elements
######################

if bashio::supervisor.ping 2>/dev/null; then
    # Remove services tab from webui
    echo "... removing System Controls from webui as should be used from HA"
    sed -i '/>System Controls/d' "$HOME/BirdNET-Pi/homepage/views.php"

    # Remove pulseaudio
    echo "... disabling pulseaudio as managed by HomeAssistant"
    for file in $(grep -srl "pulseaudio --start" $HOME/BirdNET-Pi/scripts); do
        sed -i "s|! pulseaudio --check|pulseaudio --check|g" "$file"
    done

    # Check if port 80 is correctly configured
    if [ -n "$(bashio::addon.port "80")" ] && [ "$(bashio::addon.port "80")" != 80 ]; then
        bashio::log.fatal "The port 80 is enabled, but should still be 80 if you want automatic SSL certificates generation to work."
    fi
fi

# General elements
##################

# Remove Ram drive option from webui
echo "... removing Ram drive from webui as it is handled from HA"
if grep -q "Ram drive" "$HOME/BirdNET-Pi/scripts/service_controls.php"; then
    sed -i '/Ram drive/{n;s/center"/center" style="display: none;"/;}' "$HOME/BirdNET-Pi/scripts/service_controls.php"
    sed -i '/Ram drive/d' "$HOME/BirdNET-Pi/scripts/service_controls.php"
fi

# Allow symlinks
echo "... ensuring symlinks work"
for files in "$HOME"/BirdNET-Pi/scripts/*.sh; do
  sed -i "s|find |find -L |g" "$files"
  sed -i "s|find -L -L |find -L |g" "$files"
done

# Correct services to start as user pi
echo "... updating services to start as user pi"
if ! grep -q "/usr/bin/sudo" "$HOME/BirdNET-Pi/templates/birdnet_analysis.service"; then
    while IFS= read -r file; do
        if [[ "$(basename "$file")" != "birdnet_log.service" ]]; then
            sed -i "s|ExecStart=|ExecStart=/usr/bin/sudo -u pi |g" "$file"
        fi
    done < <(find "$HOME/BirdNET-Pi/templates/" -name "*net*.service" -print)
fi

# Allow pulseaudio system
echo "... allow pulseaudio as root as backup"
sed -i 's#pulseaudio --start#pulseaudio --start 2>/dev/null && pulseaudio --check || pulseaudio --system#g' "$HOME"/BirdNET-Pi/scripts/birdnet_recording.sh

# Send services log to container logs
echo "... redirecting services logs to container logs"
while IFS= read -r file; do
    sed -i "/StandardError/d" "$file"
    sed -i "/StandardOutput/d" "$file"
    sed -i "/\[Service/a StandardError=append:/proc/1/fd/1" "$file"
    sed -i "/\[Service/a StandardOutput=append:/proc/1/fd/1" "$file"
done < <(find "$HOME/BirdNET-Pi/templates/" -name "*.service" -print)

# Preencode API key
if [[ -f "$HOME/BirdNET-Pi/scripts/common.php" ]] && ! grep -q "221160312" "$HOME/BirdNET-Pi/scripts/common.php"; then
    sed -i "/return \$_SESSION\['my_config'\];/i\ \ \ \ if (isset(\$_SESSION\['my_config'\]) \&\& empty(\$_SESSION\['my_config'\]\['FLICKR_API_KEY'\])) {\n\ \ \ \ \ \ \ \ \$_SESSION\['my_config'\]\['FLICKR_API_KEY'\] = \"221160312e1c22\";\n\ \ \ \ }" "$HOME"/BirdNET-Pi/scripts/common.php
    sed -i "s|e1c22|e1c22ec60ecf336951b0e77|g" "$HOME"/BirdNET-Pi/scripts/common.php
fi

# Correct log services to show /proc/1/fd/1
echo "... redirecting birdnet_log service output to /logs"
sed -i "/User=pi/d" "$HOME/BirdNET-Pi/templates/birdnet_log.service"
sed -i "s|birdnet_log.sh|cat /proc/1/fd/1|g" "$HOME/BirdNET-Pi/templates/birdnet_log.service"

# Correct backup script
if [[ -f "$HOME/BirdNET-Pi/scripts/backup_data.sh" ]]; then
    echo "... correct backup script"
    sed -i "/PHP_SERVICE=/c PHP_SERVICE=\$(systemctl list-unit-files -t service --no-pager | grep 'php' | grep 'fpm' | awk '{print \$1}')" "$HOME/BirdNET-Pi/scripts/backup_data.sh"
fi

# Caddyfile modifications
echo "... modifying Caddyfile configurations"
caddy fmt --overwrite /etc/caddy/Caddyfile
#Change port to leave 80 free for certificate requests
if ! grep -q "http://:8081" /etc/caddy/Caddyfile; then
    sed -i "s|http://|http://:8081|g" /etc/caddy/Caddyfile
    sed -i "s|http://|http://:8081|g" "$HOME/BirdNET-Pi/scripts/update_caddyfile.sh"
    if [ -f /etc/caddy/Caddyfile.original ]; then
        rm /etc/caddy/Caddyfile.original
    fi
fi

# Correct webui paths
echo "... correcting webui paths"
if ! grep -q "/stats/" "$HOME/BirdNET-Pi/homepage/views.php"; then
    sed -i "s|/stats|/stats/|g" "$HOME/BirdNET-Pi/homepage/views.php"
    sed -i "s|/log|/log/|g" "$HOME/BirdNET-Pi/homepage/views.php"
fi

# Correct systemctl path
echo "... updating systemctl path"
curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /bin/systemctl || mv /helpers/systemctl3.py /bin/systemctl
chown pi:pi /bin/systemctl
chmod a+x /bin/systemctl

# Allow reverse proxy for streamlit
echo "... allow reverse proxy for streamlit"
sed -i "s|plotly_streamlit.py --browser.gatherUsageStats|plotly_streamlit.py --server.enableXsrfProtection=false --server.enableCORS=false --browser.gatherUsageStats|g" "$HOME/BirdNET-Pi/templates/birdnet_stats.service"

# Clean saved mp3 files
if [[ -f "$HOME/BirdNET-Pi/scripts/utils/reporting.py" ]]; then
    echo ".. add highpass and lowpass to sox extracts"
    sed -i "s|f'={stop}']|f'={stop}', 'highpass', '250']|g" "$HOME/BirdNET-Pi/scripts/utils/reporting.py"
fi

# Correct timedatectl path
echo "... updating timedatectl path"
if [[ -f /helpers/timedatectl ]]; then
    mv /helpers/timedatectl /usr/bin/timedatectl
    chown pi:pi /usr/bin/timedatectl
    chmod a+x /usr/bin/timedatectl
fi

# Set RECS_DIR
echo "... setting RECS_DIR to /tmp"
grep -rl "RECS_DIR" "$HOME" --exclude="*.php" | while read -r file; do
    sed -i "s|conf\['RECS_DIR'\]|'/tmp'|g" "$file"
    sed -i "s|\$RECS_DIR|/tmp|g" "$file"
    sed -i "s|\${RECS_DIR}|/tmp|g" "$file"
    sed -i "/^RECS_DIR=/c RECS_DIR=/tmp" "$file"
    sed -i "/^\$RECS_DIR=/c \$RECS_DIR=/tmp" "$file"
done
mkdir -p /tmp

# Correct language labels according to birdnet.conf
echo "... adapting labels according to birdnet.conf"
if export "$(grep "^DATABASE_LANG" /config/birdnet.conf)"; then
    bashio::log.info "Setting language to ${DATABASE_LANG:-en}"
    "$HOME/BirdNET-Pi/scripts/install_language_label_nm.sh" -l "${DATABASE_LANG:-}" &>/dev/null || bashio::log.warning "Failed to update language labels"
else
    bashio::log.warning "DATABASE_LANG not found in configuration. Using default labels."
fi
