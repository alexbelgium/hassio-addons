#!/bin/bash

echo "Starting"

if [ ! -f /data/config.json ]; then
  echo "building userdir"
  freqtrade create-userdir --userdir /data
  echo "building initial config"
  freqtrade new-config --config /data/config.json
fi

sleep 5000000

echo "Starting app"
freqtrade trade --logfile /data/logs/freqtrade.log --db-url sqlite://///data/tradesv3.sqlite --config /data/config.json --strategy SampleStrategy
