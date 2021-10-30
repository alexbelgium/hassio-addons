#!/bin/bah

echo "Starting"

if [ ! -f /data/config.json ]; then
  echo "building userdir"
  freqtrade create-userdir --userdir /data \
  echo "building initial config"
  freqtrade new-config --config /data/config.json \
fi

echo "Starting app"
pause 36000000
#bash freqtrade trade --logfile /data/logs/freqtrade.log --db-url sqlite://///data/tradesv3.sqlite --config /data/config.json --strategy SampleStrategy
