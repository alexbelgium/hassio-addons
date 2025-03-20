#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

################
# MODIFY WEBUI #
################

bashio::log.info "Adapting webui"

# Remove services tab from webui
echo "... removing System Controls from webui as should be used from HA"
sed -i '/>System Controls/d' "$HOME/BirdNET-Pi/homepage/views.php"

# Remove Ram drive option from webui
echo "... removing Ram drive from webui as it is handled from HA"
sed -i '/Ram drive/{n;s/center"/center" style="display: none;"/;}' "$HOME/BirdNET-Pi/scripts/service_controls.php"
sed -i '/Ram drive/d' "$HOME/BirdNET-Pi/scripts/service_controls.php"

# Correct services to start as user pi
echo "... updating services to start as user pi"
while IFS= read -r file; do
    if [[ "$(basename "$file")" != "birdnet_log.service" ]]; then
        sed -i "s|ExecStart=|ExecStart=/usr/bin/sudo -u pi |g" "$file"
    fi
done < <(find "$HOME/BirdNET-Pi/templates/" -name "b*.service" -print)

# Send services log to container logs
echo "... redirecting services logs to container logs"
while IFS= read -r file; do
    sed -i "/Service/a StandardError=append:/proc/1/fd/1" "$file"
    sed -i "/Service/a StandardOutput=append:/proc/1/fd/1" "$file"
done < <(find "$HOME/BirdNET-Pi/templates/" -name "b*.service" -print)

# Avoid preselection in include and exclude lists
echo "... disabling preselecting options in include and exclude lists"
sed -i "s|option selected|option disabled|g" "$HOME/BirdNET-Pi/scripts/include_list.php"
sed -i "s|option selected|option disabled|g" "$HOME/BirdNET-Pi/scripts/exclude_list.php"

# Correct log services to show /proc/1/fd/1
echo "... redirecting birdnet_log service output to /logs"
sed -i "/User=pi/d" "$HOME/BirdNET-Pi/templates/birdnet_log.service"
sed -i "s|birdnet_log.sh|cat /proc/1/fd/1|g" "$HOME/BirdNET-Pi/templates/birdnet_log.service"

# Caddyfile modifications
echo "... modifying Caddyfile configurations"
caddy fmt --overwrite /etc/caddy/Caddyfile
#Change port to leave 80 free for certificate requests
sed -i "s|http://|http://:8081|g" /etc/caddy/Caddyfile
sed -i "s|http://|http://:8081|g" "$HOME/BirdNET-Pi/scripts/update_caddyfile.sh"
if [ -f /etc/caddy/Caddyfile.original ]; then
    rm /etc/caddy/Caddyfile.original
fi

# Correct webui paths
echo "... correcting webui paths"
sed -i "s|/stats|/stats/|g" "$HOME/BirdNET-Pi/homepage/views.php"
sed -i "s|/log|/log/|g" "$HOME/BirdNET-Pi/homepage/views.php"

# Check if port 80 is correctly configured
if [ -n "$(bashio::addon.port 80)" ] && [ "$(bashio::addon.port 80)" != 80 ]; then
    bashio::log.fatal "The port 80 is enabled, but should still be 80 if you want automatic SSL certificates generation to work."
fi

# Correct systemctl path
echo "... updating systemctl path"
mv /helpers/systemctl3.py /bin/systemctl
chmod a+x /bin/systemctl

# Correct timedatectl path
echo "updating timedatectl path"
mv /helpers/timedatectl /usr/bin/timedatectl
chown pi:pi /usr/bin/timedatectl
chmod a+x /usr/bin/timedatectl

# Correct timezone showing in config.php
sed -i -e '/<option disabled selected>/s/selected//' \
       -e '/\$current_timezone = trim(shell_exec("timedatectl show --value --property=Timezone"));/d' \
       -e "/\$date = new DateTime('now');/i \$current_timezone = trim(shell_exec(\"timedatectl show --value --property=Timezone\"));" \
       -e "/\$date = new DateTime('now');/i date_default_timezone_set(\$current_timezone);" "$HOME/BirdNET-Pi/scripts/config.php"

# Use only first user
echo "... correcting for multiple users"
for file in $(grep -rl "/1000/{print" "$HOME"/BirdNET-Pi/scripts); do
    sed -i "s|'/1000/{print \$1}'|'/1000/{print \$1; exit}'|" "$file"
    sed -i "s|'/1000/{print \$6}'|'/1000/{print \$6; exit}'|" "$file"
done
