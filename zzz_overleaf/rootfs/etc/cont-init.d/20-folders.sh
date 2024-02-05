#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if [ -d /config/binance-trading-bot ]; then
    echo "Moving to new location /config/addons_config/binance-trading-bot"
    mkdir -p /config/addons_config/binance-trading-bot
    chmod 777 /config/addons_config/binance-trading-bot
    mv /config/binance-trading-bot/* /config/addons_config/binance-trading-bot/
    rm -r /config/binance-trading-bot
fi

if [ ! -d /config/addons_config/binance-trading-bot ]; then
    echo "Creating /config/addons_config/binance-trading-bot"
    mkdir -p /config/addons_config/binance-trading-bot
    chmod 777 /config/addons_config/binance-trading-bot
fi
