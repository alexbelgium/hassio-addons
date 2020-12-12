#!/usr/bin/with-contenv bashio
# ==============================================================================

declare CONFIG
declare authentication_required
declare username
declare password

if ! bashio::fs.directory_exists '/share/transmission'; then
  mkdir '/share/transmission'
fi

if ! bashio::fs.file_exists '/share/transmission/settings.json'; then
  echo "{}" > /share/transmission/settings.json
fi

CONFIG=$(</share/transmission/settings.json)

# Defaults
CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir\"=\"/share/incomplete\"")
CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir-enabled\"=true")
CONFIG=$(bashio::jq "${CONFIG}" ".\"download-dir\"=\"/share/downloads\"")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-whitelist-enabled\"=false")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-host-whitelist-enabled\"=false")
CONFIG=$(bashio::jq "${CONFIG}" ".\"bind-address-ipv4\"=\"0.0.0.0\"")

authentication_required=$(bashio::config 'authentication_required')
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-authentication-required\"=${authentication_required}")


username=$(bashio::config 'username')
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-username\"=\"${username}\"")


password=$(bashio::config 'password')
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-password\"=\"${password}\"")

echo "${CONFIG}" > /share/transmission/settings.json
