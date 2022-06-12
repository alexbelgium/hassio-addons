#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

rm -rf /etc/cont-init.d/20-config || true

declare CONFIG
#declare incomplete_bool
declare download_dir
declare incomplete_dir
declare USER
declare PASS
declare WHITELIST
#declare HOST_WHITELIST

CONFIGDIR="/config/transmission"

###############
# PERMISSIONS #
###############

#Default folders
echo "Updating folders"
mkdir -p /config/transmission || true
mkdir -p /watch || true
chown -R abc:abc /config/transmission || true

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
    [ "$CUSTOMUI" != "standard" ] && sed -i "1a export TRANSMISSION_WEB_HOME=\"/$CUSTOMUI/\"" /etc/services.d/transmission/run

    # Enable transmission-web-control return to default UI
    if [ ! -f "/transmission-web-control/index.original.html" ]; then
        ln -s /usr/share/transmission/web/style /transmission-web-control
        ln -s /usr/share/transmission/web/images /transmission-web-control
        ln -s /usr/share/transmission/web/javascript /transmission-web-control
        ln -s /usr/share/transmission/web/index.html /transmission-web-control/index.original.html
    fi
fi
bashio::log.info "UI selected : $CUSTOMUI"

# INCOMPLETE DIR
################

echo "Creating config"
download_dir=$(bashio::config 'download_dir')
incomplete_dir=$(bashio::config 'incomplete_dir')
CONFIG=$(<$CONFIGDIR/settings.json)

# Permissions
echo "Updating permissions"
mkdir -p "$download_dir"
chown abc:abc "$download_dir"

# if incomplete dir > 2, to allow both null and '', set it as existing
if [ ${#incomplete_dir} -ge 2 ]; then
    echo "Incomplete dir set: $incomplete_dir"
    CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir-enabled\"=true")
    mkdir -p "$incomplete_dir"
    chown abc:abc "$incomplete_dir"
else
    echo "Incomplete dir disabled"
    CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir-enabled\"=false")
fi

# Defaults
CONFIG=$(bashio::jq "${CONFIG}" ".\"incomplete-dir\"=\"${incomplete_dir}\"")
CONFIG=$(bashio::jq "${CONFIG}" ".\"download-dir\"=\"${download_dir}\"")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-host-whitelist-enabled\"=false")
CONFIG=$(bashio::jq "${CONFIG}" ".\"bind-address-ipv4\"=\"0.0.0.0\"")

if bashio::config.has_value 'watch_dir'; then
    CONFIG=$(bashio::jq "${CONFIG}" ".\"watch-dir\"=\"$(bashio::config 'watch_dir')\"")
fi

echo "${CONFIG}" >"$CONFIGDIR"/settings.json &&
jq . -S "$CONFIGDIR"/settings.json | cat >temp.json && mv temp.json $CONFIGDIR/settings.json

# USER and PASS
###############

CONFIG=$(<"$CONFIGDIR"/settings.json)
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
echo "${CONFIG}" >"$CONFIGDIR"/settings.json &&
jq . -S "$CONFIGDIR"/settings.json | cat >temp.json && mv temp.json "$CONFIGDIR"/settings.json

# WHITELIST
###########

CONFIG=$(<"$CONFIGDIR"/settings.json)
WHITELIST=$(bashio::config 'whitelist')
if bashio::config.has_value 'whitelist'; then
    BOOLEAN=true
    bashio::log.info "Whitelist set, no authentification from IP $WHITELIST"
else
    BOOLEAN=false
    sed -i "2 i\"rpc-whitelist-enabled\": false," "$CONFIGDIR"/settings.json
fi
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-whitelist-enabled\"=${BOOLEAN}")
CONFIG=$(bashio::jq "${CONFIG}" ".\"rpc-whitelist\"=\"$WHITELIST\"")
echo "${CONFIG}" >"$CONFIGDIR"/settings.json &&
jq . -S "$CONFIGDIR"/settings.json | cat >temp.json && mv temp.json "$CONFIGDIR"/settings.json
