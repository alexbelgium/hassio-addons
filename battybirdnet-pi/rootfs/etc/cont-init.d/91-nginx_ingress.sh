#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# NGINX SETTING #
#################

# Variables
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)

# Quits if ingress is not active
if [ -z "$ingress_entry" ]; then
    bashio::log.warning "Ingress entry is not set, exiting configuration."
    exit 0
fi

bashio::log.info "Adapting for ingress"
echo "... setting up nginx"

# Check if the NGINX configuration file exists
nginx_conf="/etc/nginx/servers/ingress.conf"
if [ -f "$nginx_conf" ]; then
    sed -i "s/%%port%%/${ingress_port}/g" "$nginx_conf"
    sed -i "s/%%interface%%/${ingress_interface}/g" "$nginx_conf"
    sed -i "s|%%ingress_entry%%|${ingress_entry}|g" "$nginx_conf"
else
    bashio::log.error "NGINX configuration file not found: $nginx_conf"
    exit 1
fi

echo "... ensuring restricted area access"
echo "${ingress_entry}" > /ingress_url

# Modify PHP file safely
for php_file in config.php play.php advanced.php overview.php; do
    sed -i "s|if (\!isset(\$_SERVER\['PHP_AUTH_USER'\])) {|if (\!isset(\$_SERVER\['PHP_AUTH_USER'\]) \&\& strpos(\$_SERVER\['HTTP_REFERER'\], '/api/hassio_ingress') == false) {|g" "$HOME/BirdNET-Pi/scripts/$php_file"
    sed -i "s+if(\$submittedpwd == \$caddypwd \&\& \$submitteduser == 'birdnet')+if((\$submittedpwd == \$caddypwd \&\& \$submitteduser == 'birdnet') || (strpos(\$_SERVER['HTTP_REFERER'], '/api/hassio_ingress') !== false \&\& strpos(\$_SERVER['HTTP_REFERER'], trim(file_get_contents('/ingress_url'))) !== false)+g" "$HOME/BirdNET-Pi/scripts/$php_file"
done

echo "... adapting Caddyfile for ingress"
chmod +x /helpers/caddy_ingress.sh

# Correct script execution
/helpers/caddy_ingress.sh

# Update the Caddyfile if update script exists
caddy_update_script="$HOME/BirdNET-Pi/scripts/update_caddyfile.sh"
if [ -f "$caddy_update_script" ]; then
    sed -i "/sudo caddy fmt --overwrite/i /helpers/caddy_ingress.sh" "$caddy_update_script"
else
    bashio::log.error "Caddy update script not found: $caddy_update_script"
    exit 1
fi
