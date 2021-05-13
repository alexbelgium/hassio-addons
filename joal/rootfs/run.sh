#!/usr/bin/env bashio
bashio::log.info "Starting addon..."

#################
# NGINX SETTING #
#################
declare port
declare certfile
declare ingress_interface
declare ingress_port
declare keyfile

port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf

################
# JOAL SETTING #
################

declare TOKEN
TOKEN=$(bashio::config 'secret_token')
UPSTREAM="2.1.24"

mv -f /data/joal/config.json / || true
#curl -s -S -J -L -o /tmp/joal.tar.gz $(curl -s https://api.github.com/repos/anthonyraymond/joal/releases/latest | grep -o "http.*joal.tar.gz") >/dev/null
wget -q -O /tmp/joal.tar.gz "https://github.com/anthonyraymond/joal/releases/download/$UPSTREAM/joal.tar.gz"
mkdir -p /data/joal
tar zxvf /tmp/joal.tar.gz -C /data/joal >/dev/null
chown -R $(id -u):$(id -g) /data/joal
rm /data/joal/jack-of*
bashio::log.info "... Joal updated"
mv -f /config.json /data/joal/ || true

###############
# LAUNCH APPS #
###############

nohup java -jar /joal/joal.jar --joal-conf=/data/joal --spring.main.web-environment=true --server.port="8081" --joal.ui.path.prefix="joal" --joal.ui.secret-token=$TOKEN \
& bashio::log.info "... Joal started with secret token $TOKEN"
# Wait for transmission to become available
bashio::net.wait_for 8081 localhost 900 || true
exec nginx || bashio::log.fatal "... Nginx not started, only access through webui available" \
& bashio::log.info "... Nginx started for Ingress" 

###########
# TIMEOUT #
###########

if bashio::config.has_value 'run_for_hours'; then
  RUNTIME=$(bashio::config 'run_for_hours')
  bashio::log.info "... Addon will stop after $RUNTIME hours"
  sleep $TIMEOUT && \
  kill "$PID" && \
  bashio::log.info "... Timeout achieved, addon will stop !" 

else
  bashio::log.info "... run_for_hours option not defined, addon will run continuously"
fi
