#!/usr/bin/env bashio
declare TOKEN
TOKEN=$(bashio::config 'secret_token')

mv -f /data/joal/config.json / || true

curl -s -L -o /tmp/joal.tar.gz "https://github.com/anthonyraymond/joal/releases/download/2.1.24/joal.tar.gz"
mkdir -p /data/joal
tar zxvf /tmp/joal.tar.gz -C /data/joal
chown -R $(id -u):$(id -g) /data/joal
rm /data/joal/jack-of*

mv -f /config.json /data/joal/ || true
java -jar /joal/joal.jar --joal-conf=/data/joal --spring.main.web-environment=true --server.port="8081" --joal.ui.path.prefix="joal" --joal.ui.secret-token=$TOKEN

# Wait for transmission to become available
bashio::net.wait_for 8081 localhost 900
bashio::log.info "Starting NGinx..."
exec nginx
