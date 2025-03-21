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

# Remove services tab from webui
echo "... removing System Controls from webui as should be used from HA"
sed -i '/>System Controls/d' "$HOME/BirdNET-Pi/homepage/views.php"

# Remove Ram drive option from webui
echo "... removing Ram drive from webui as it is handled from HA"
if grep -q "Ram drive" "$HOME/BirdNET-Pi/scripts/service_controls.php"; then
    sed -i '/Ram drive/{n;s/center"/center" style="display: none;"/;}' "$HOME/BirdNET-Pi/scripts/service_controls.php"
    sed -i '/Ram drive/d' "$HOME/BirdNET-Pi/scripts/service_controls.php"
fi

# Correct services to start as user pi
echo "... updating services to start as user pi"
if ! grep -q "/usr/bin/sudo" "$HOME/BirdNET-Pi/templates/birdnet_log.service"; then
    while IFS= read -r file; do
        if [[ "$(basename "$file")" != "birdnet_log.service" ]]; then
            sed -i "s|ExecStart=|ExecStart=/usr/bin/sudo -u pi |g" "$file"
        fi
    done < <(find "$HOME/BirdNET-Pi/templates/" -name "birdnet*.service" -print)
fi

# Send services log to container logs
echo "... redirecting services logs to container logs"
while IFS= read -r file; do
    sed -i "/StandardError/d" "$file"
    sed -i "/StandardOutput/d" "$file"
    sed -i "/\[Service/a StandardError=append:/proc/1/fd/1" "$file"
    sed -i "/\[Service/a StandardOutput=append:/proc/1/fd/1" "$file"
done < <(find "$HOME/BirdNET-Pi/templates/" -name "*.service" -print)

# Avoid preselection in include and exclude lists
echo "... disabling preselecting options in include and exclude lists"
sed -i "s|option selected|option disabled|g" "$HOME/BirdNET-Pi/scripts/include_list.php"
sed -i "s|option selected|option disabled|g" "$HOME/BirdNET-Pi/scripts/exclude_list.php"

# Preencode API key
if ! grep -q "221160312" "$HOME/BirdNET-Pi/scripts/common.php"; then
    sed -i "/return \$_SESSION\['my_config'\];/i\ \ \ \ if (isset(\$_SESSION\['my_config'\]) \&\& empty(\$_SESSION\['my_config'\]\['FLICKR_API_KEY'\])) {\n\ \ \ \ \ \ \ \ \$_SESSION\['my_config'\]\['FLICKR_API_KEY'\] = \"221160312e1c22\";\n\ \ \ \ }" "$HOME"/BirdNET-Pi/scripts/common.php
    sed -i "s|e1c22|e1c22ec60ecf336951b0e77|g" "$HOME"/BirdNET-Pi/scripts/common.php
fi

# Correct log services to show /proc/1/fd/1
echo "... redirecting birdnet_log service output to /logs"
sed -i "/User=pi/d" "$HOME/BirdNET-Pi/templates/birdnet_log.service"
sed -i "s|birdnet_log.sh|cat /proc/1/fd/1|g" "$HOME/BirdNET-Pi/templates/birdnet_log.service"

# Correct backup script
echo "... correct backup script"
sed -i "/PHP_SERVICE=/c PHP_SERVICE=\$(systemctl list-unit-files -t service --no-pager | grep 'php' | grep 'fpm' | awk '{print \$1}')" "$HOME/BirdNET-Pi/scripts/backup_data.sh"

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

# Check if port 80 is correctly configured
if [ -n "$(bashio::addon.port "80")" ] && [ "$(bashio::addon.port "80")" != 80 ]; then
    bashio::log.fatal "The port 80 is enabled, but should still be 80 if you want automatic SSL certificates generation to work."
fi

# Correct systemctl path
#echo "... updating systemctl path"
#if [[ -f /helpers/systemctl3.py ]]; then
#    mv /helpers/systemctl3.py /bin/systemctl
#    chmod a+x /bin/systemctl
#fi

# Improve streamlit cache
#echo "... add streamlit cache"
#sed -i "/def get_data/i \\@st\.cache_resource\(\)" "$HOME/BirdNET-Pi/scripts/plotly_streamlit.py"

# Allow reverse proxy for streamlit
echo "... allow reverse proxy for streamlit"
sed -i "s|plotly_streamlit.py --browser.gatherUsageStats|plotly_streamlit.py --server.enableXsrfProtection=false --server.enableCORS=false --browser.gatherUsageStats|g" "$HOME/BirdNET-Pi/templates/birdnet_stats.service"

# Clean saved mp3 files
echo ".. add highpass and lowpass to sox extracts"
sed -i "s|f'={stop}']|f'={stop}', 'highpass', '250', 'lowpass', '15000']|g" "$HOME/BirdNET-Pi/scripts/utils/reporting.py"
sed -i '/sox.*-V1/s/spectrogram/highpass 250 spectrogram/' "$HOME/BirdNET-Pi/scripts/spectrogram.sh"

# Correct timedatectl path
echo "updating timedatectl path"
if [[ -f /helpers/timedatectl ]]; then
    mv /helpers/timedatectl /usr/bin/timedatectl
    chown pi:pi /usr/bin/timedatectl
    chmod a+x /usr/bin/timedatectl
fi

# Correct language labels according to birdnet.conf
echo "... adapting labels according to birdnet.conf"
if export "$(grep "^DATABASE_LANG" /config/birdnet.conf)"; then
    bashio::log.info "Setting language to ${DATABASE_LANG:-en}"
    "$HOME/BirdNET-Pi/scripts/install_language_label_nm.sh" -l "${DATABASE_LANG:-}" &>/dev/null || bashio::log.warning "Failed to update language labels"
else
    bashio::log.warning "DATABASE_LANG not found in configuration. Using default labels."
fi
