#!/usr/bin/with-contenv bashio
# ==============================================================================

declare CONFIG
declare incomplete_bool
declare download_dir
declare incomplete_dir

##########################
# IMPORT PREVIOUS FOLDER #
##########################
#if [ -d '/share/transmission' ]; then
#  mkdir -p /config/transmission
#  chown -R abc:abc /config/transmission
#  mv /config/transmission /share/transmission
#  echo "Folder migrated to /config/transmission"
#fi

###############
# PERMISSIONS #
###############
#Default folders

mkdir -p /config/transmission
chown -R abc:abc /config/transmission

if ! bashio::fs.file_exists '/config/transmission/settings.json'; then
  cp "/defaults/settings.json" "/config/transmission/settings.json"
fi

#################
# CONFIGURATION #
#################
# Variables 
download_dir=$(bashio::config 'download_dir')
incomplete_dir=$(bashio::config 'incomplete_dir')
CONFIG=$(</config/transmission/settings.json)

# Permissions
mkdir -p $download_dir || true
chown abc:abc $download_dir || true

# if incomplete dir > 2, to allow both null and '', set it as existing
if [ ${#incomplete_dir} -ge 2 ]
then
        CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir-enabled\"=true")
        mkdir -p $incomplete_dir
        chown abc:abc $incomplete_dir
else
        CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir-enabled\"=false")
fi

# Defaults
CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir\"=\"${incomplete_dir}\"")
CONFIG=$(bashio::jq "${CONFIG}" ".\"download-dir\"=\"${download_dir}\"")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-whitelist-enabled\"=false")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-host-whitelist-enabled\"=false")
CONFIG=$(bashio::jq "${CONFIG}" ".\"bind-address-ipv4\"=\"0.0.0.0\"")

echo "${CONFIG}" > /config/transmission/settings.json

################
# Alternate UI #
################

if bashio::config.has_value 'customUI'; then
  ### Variables
  CUSTOMUI=$(bashio::config 'customUI')
  export TRANSMISSION_WEB_HOME=/$CUSTOMUI/
  bashio::log.info "UK selected : $TRANSMISSION_WEB_HOME" 
fi
