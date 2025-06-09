#!/command/with-contenv bashio
# shellcheck shell=bash
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

###############
# SSL SETTING #
###############

if bashio::config.true 'ssl'; then
	bashio::log.info "SSL is enabled using addon options, setting up NGINX and Caddy."

	# Check required SSL configurations
	bashio::config.require.ssl
	certfile=$(bashio::config 'certfile')
	keyfile=$(bashio::config 'keyfile')

	# Ensure Caddyfile exists before modifying
	caddyfile="/etc/caddy/Caddyfile"
	if [ -f "$caddyfile" ]; then
		sed -i "2a\    tls /ssl/${certfile} /ssl/${keyfile}" "$caddyfile"
		sed -i "s|http://:8081|https://:8081|g" "$caddyfile"
	else
		bashio::log.error "Caddyfile not found at $caddyfile, skipping SSL configuration."
		exit 1
	fi

	# Ensure update_caddyfile.sh exists before modifying
	update_script="$HOME/BirdNET-Pi/scripts/update_caddyfile.sh"
	if [ -f "$update_script" ]; then
		sed -i "s|http://:8081|https://:8081|g" "$update_script"
		if ! grep -q "tls /ssl/${certfile} /ssl/${keyfile}" "$update_script"; then
			sed -i "/https:/a\    tls /ssl/${certfile} /ssl/${keyfile}" "$update_script"
		fi
	else
		bashio::log.error "Update script not found: $update_script, skipping SSL setup for update."
		exit 1
	fi
fi
