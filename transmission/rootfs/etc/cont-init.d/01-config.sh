#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

declare CONFIG
#declare incomplete_bool
declare download_dir
declare incomplete_dir
declare USER
declare PASS
declare WHITELIST
#declare HOST_WHITELIST

CONFIGDIR="/config/addons_config/transmission"

####################
#  Migrate folders #
####################

if [ -d /config/transmission ]; then
    cp -r /config/transmission /config/addons_config/transmission
    rm -r /config/transmission
fi

###############
# PERMISSIONS #
###############

#Default folders
echo "Updating folders"
mkdir -p "$CONFIGDIR"
mkdir -p /watch || true
chown -R "$PUID:$PGID" "$CONFIGDIR"

if ! bashio::fs.file_exists "$CONFIGDIR/settings.json"; then
    echo "Creating default config"
    cp "/defaults/settings.json" "$CONFIGDIR/settings.json"
fi

#################
# CONFIGURATION #
#################

# Alternate UI
##############

if bashio::config.has_value 'customUI'; then
    CUSTOMUI=$(bashio::config 'customUI')

fi
bashio::log.info "UI selected : $CUSTOMUI"
bashio::log.warning "If UI was changed, you need to clear browser cache for it to show in Ingress"

# INCOMPLETE DIR
################

echo "Creating config"
download_dir=$(bashio::config 'download_dir')
incomplete_dir=$(bashio::config 'incomplete_dir')
CONFIG=$(< $CONFIGDIR/settings.json)

# Permissions
echo "Updating permissions"
mkdir -p "$download_dir"
chown "$PUID:$PGID" "$download_dir"

# if incomplete dir > 2, to allow both null and '', set it as existing
if [ ${#incomplete_dir} -ge 2 ]; then
    echo "Incomplete dir set: $incomplete_dir"
    CONFIG=$(bashio::jq "${CONFIG}" '."incomplete-dir-enabled"=true')
    mkdir -p "$incomplete_dir"
    chown "$PUID:$PGID" "$incomplete_dir"
else
    echo "Incomplete dir disabled"
    CONFIG=$(bashio::jq "${CONFIG}" '."incomplete-dir-enabled"=false')
fi

# Defaults
CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir\"=\"${incomplete_dir}\"")
CONFIG=$(bashio::jq "${CONFIG}" ".\"download-dir\"=\"${download_dir}\"")
CONFIG=$(bashio::jq "${CONFIG}" '."rpc-host-whitelist-enabled"=false')
CONFIG=$(bashio::jq "${CONFIG}" '."bind-address-ipv4"="0.0.0.0"')

if bashio::config.has_value 'watch_dir'; then
    CONFIG=$(bashio::jq "${CONFIG}" ".\"watch-dir\"=\"$(bashio::config 'watch_dir')\"")
fi

echo "${CONFIG}" > "$CONFIGDIR"/settings.json \
                                             && jq . -S "$CONFIGDIR"/settings.json | cat > temp.json && mv temp.json $CONFIGDIR/settings.json

# USER and PASS
###############

CONFIG=$(< "$CONFIGDIR"/settings.json)
USER=$(bashio::config 'user')
PASS=$(bashio::config 'pass')
if bashio::config.has_value 'user'; then
    BOOLEAN=true
    bashio::log.info "User & Pass set, authentification will be with user : $USER and pass : $PASS"
else
    BOOLEAN=false
    bashio::log.warning "User & Pass not set, no authentification required"
fi
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-authentication-required\"=${BOOLEAN}")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-username\"=\"${USER}\"")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-password\"=\"${PASS}\"")
echo "${CONFIG}" > "$CONFIGDIR"/settings.json \
                                             && jq . -S "$CONFIGDIR"/settings.json | cat > temp.json && mv temp.json "$CONFIGDIR"/settings.json

# WHITELIST
###########

CONFIG=$(< "$CONFIGDIR"/settings.json)
WHITELIST=$(bashio::config 'whitelist')
if bashio::config.has_value 'whitelist'; then
    BOOLEAN=true
    bashio::log.info "Whitelist set, no authentification from IP $WHITELIST"
else
    BOOLEAN=false
    sed -i '2 i"rpc-whitelist-enabled": false,'   "$CONFIGDIR"/settings.json
fi
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-whitelist-enabled\"=${BOOLEAN}")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-whitelist\"=\"$WHITELIST\"")
echo "${CONFIG}" > "$CONFIGDIR"/settings.json \
                                             && jq . -S "$CONFIGDIR"/settings.json | cat > temp.json && mv temp.json "$CONFIGDIR"/settings.json
