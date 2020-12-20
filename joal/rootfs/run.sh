#!/usr/bin/with-contenv bashio
# ==============================================================================

cp -R -n /joal /data/joal

java -jar /joal/joal.jar --joal-conf=/data/joal
