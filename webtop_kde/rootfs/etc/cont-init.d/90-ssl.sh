#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Shared with joplin_desktop (and webtop, through its rootfs symlink); keep it add-on agnostic.

if bashio::config.true 'use_own_certs'; then
    bashio::log.green "Using referenced ssl certificates to connect with https. Please remember to open the ssl port in the addon options"
    CERTFILE="$(bashio::config 'certfile')"
    KEYFILE="$(bashio::config 'keyfile')"
    NGINX_CONFIG="/defaults/default.conf"

    #Check if files exist
    echo "... checking if referenced files exist"
    if [ -f /ssl/"$CERTFILE" ] && [ -f /ssl/"$KEYFILE" ]; then
        # Replace whatever path the directives hold rather than a fixed one: the generated
        # certificate lives under the data location, and 20-folders.sh rewrites that path when
        # data_location is changed, so a literal /config/data/ssl/... match silently missed.
        sed -Ei "s|^([[:space:]]*ssl_certificate[[:space:]]+).*;|\1/ssl/$CERTFILE;|" "$NGINX_CONFIG"
        sed -Ei "s|^([[:space:]]*ssl_certificate_key[[:space:]]+).*;|\1/ssl/$KEYFILE;|" "$NGINX_CONFIG"
        if grep -q "ssl_certificate[[:space:]]*/ssl/$CERTFILE;" "$NGINX_CONFIG"; then
            echo "... done"
        else
            bashio::log.warning "... could not set /ssl/$CERTFILE in $NGINX_CONFIG, using self-generated certificates"
        fi
    else
        bashio::log.warning "...  certificate /ssl/$CERTFILE and /ssl/$KEYFILE and not found, using self-generated certificates"
    fi

fi
