#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

################
# JOAL SETTING #
################

declare TOKEN
TOKEN=$(bashio::config 'secret_token')
VERBOSE=$(bashio::config 'verbose') || true

# check password change

if [ "$TOKEN" = "lrMY24Byhx" ]; then
	bashio::log.warning "The token is still the default one, please change from addon options"
fi

# download latest version

if [ "$VERBOSE" = true ]; then
	curl --progress-bar -f -J -L -o /tmp/joal.tar.gz "$(curl -f -s -L https://api.github.com/repos/anthonyraymond/joal/releases/latest | grep -o "http.*joal.tar.gz")"
else
	curl --progress-bar -f -S -J -L -o /tmp/joal.tar.gz "$(curl -f -s -L https://api.github.com/repos/anthonyraymond/joal/releases/latest | grep -o "http.*joal.tar.gz")" >/dev/null
fi
mkdir -p /data/joal
tar zxvf /tmp/joal.tar.gz -C /data/joal >/dev/null
chown -R "$(id -u):$(id -g)" /data/joal
rm /data/joal/jack-of*
bashio::log.info "Joal updated"

##################
# SYMLINK CONFIG #
##################

# If config doesn't exist, create it
if [ ! -f /config/addons_config/joal/config.json ]; then
	bashio::log.info "Symlinking config files"
	mkdir -p /config/addons_config/joal
	cp /data/joal/config.json /config/addons_config/joal/config.json
fi

# Refresh symlink
ln -sf /config/addons_config/joal/config.json /data/joal/config.json

###############
# SET VARIABLES #
###############

#declare port
#declare certfile
declare ingress_interface
declare ingress_port
#declare keyfile

#INGRESSURL=$(bashio::config 'local_ip_port')$(bashio::addon.ingress_url)
host_port=$(bashio::core.port)
ingress_url=$(bashio::addon.ingress_entry)
ADDONPORT=$(bashio::addon.port "8081")
host_ip=$(bashio::network.ipv4_address)
host_ip=${host_ip%/*}
UIPATH=$(bashio::config 'ui_path')
#port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)

#################
# NGINX SETTING #
#################

# AUTOMATIC INGRESS
###################
#if bashio::config.has_value 'auto_connection'; then
#sed -i "s|/ui/|/ui?ui_credentials=%7B%22host%22%3A%22"${host_ip}:$host_port$ingress_url/"%22%2C%22port%22%3A%22"$host_port"%22%2C%22pathPrefix%22%3A%22"${UIPATH}"%22%2C%22secretToken%22%3A%22"${TOKEN}"%22%7D|g" /etc/nginx/servers/ingress.conf
#else
#  bashio::log.info "Ingress url not set. Connection must be done manually."
#fi

# NGINX
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%path%%/${UIPATH}/g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

###############
# LAUNCH APPS #
###############

if [ "$VERBOSE" = true ]; then
	nohup java -jar /joal/joal.jar --joal-conf=/data/joal --spring.main.web-environment=true --server.port="8081" --joal.ui.path.prefix="${UIPATH}" --joal.ui.secret-token="$TOKEN"
else
	nohup java -jar /joal/joal.jar --joal-conf=/data/joal --spring.main.web-environment=true --server.port="8081" --joal.ui.path.prefix="${UIPATH}" --joal.ui.secret-token="$TOKEN" >/dev/null
fi &
bashio::log.info "Please wait, loading..."

# Wait for transmission to become available
bashio::net.wait_for 8081 localhost 900 || true
bashio::log.warning "Configuration for direct access (in http://homeassistant.local:${ADDONPORT}/${UIPATH}/ui):"
bashio::log.info "... address : homeassistant.local"
bashio::log.info "... server port : ${ADDONPORT}"
bashio::log.info "... Path prefix : ${UIPATH}"
bashio::log.info "... Secret token : $TOKEN"
bashio::log.warning "Configuration for Ingress (in app):"
bashio::log.info "... address (if connected to hassio with IP:port) : ${host_ip}:$host_port$ingress_url/"
bashio::log.info "... address (if connected to hassio with homeassistant.local:port): homeassistant.local:$host_port$ingress_url/"
bashio::log.info "... address (if connected to hassio from internet): yourdomain.com:$host_port$ingress_url/"
bashio::log.info "... server port : $host_port"
bashio::log.info "... Path prefix : ${UIPATH}"
bashio::log.info "... Secret token : $TOKEN"
bashio::log.info "Everything loaded."

exec nginx &

###########
# TIMEOUT #
###########

if bashio::config.has_value 'run_duration'; then
	RUNTIME=$(bashio::config 'run_duration')
	bashio::log.info "Addon will stop after $RUNTIME"
	sleep "$RUNTIME" &&
		bashio::log.info "Timeout achieved, addon will stop !" &&
		exit 0
else
	bashio::log.info "Run_duration option not defined, addon will run continuously"
fi
