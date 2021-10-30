#!/bin/bah

echo "Starting"

if [ ! -f /data/config.json ]; then
echo "building userdir"
  freqtrade create-userdir --userdir /data \
echo "building initial config"
  freqtrade new-config --config /data/config.json \
fi

echo "Starting app"
trade --logfile /data/logs/freqtrade.log --db-url sqlite://///data/tradesv3.sqlite --config /data/config.json --strategy SampleStrategy
