#!/usr/bin/with-contenv bashio
# ==============================================================================
declare CONFIG

CONFIG=$(</data/transmission/settings.json)

CONFIG=$(bashio::jq "${CONFIG}" ".\"bind-address-ipv4\"=\"${1}\"")

echo "${CONFIG}" > /data/transmission/settings.json

exec /usr/bin/transmission-daemon --foreground --config-dir /data/transmission
