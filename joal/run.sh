#!/usr/bin/env bashio
declare TOKEN
TOKEN=$(bashio::config 'secret_token')

mkdir -p /data/joal/torrents

java -jar /joal/joal.jar --joal-conf=/data/joal --spring.main.web-environment=true --server.port="8081" --joal.ui.path.prefix="joal" --joal.ui.secret-token=$TOKEN
