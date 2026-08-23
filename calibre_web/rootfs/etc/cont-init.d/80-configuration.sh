#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015
set -e

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime && echo "$TIMEZONE" > /etc/timezone
fi

bashio::log.info "Install libnss3"
apt-get update && apt-get install libnss3 &> /dev/null

# Set Ingress login
if [ ! -f /config/app.db ]; then
    bashio::log.warning "First boot : disabling Ingress until addon restart"
else
    sqlite3 /config/app.db 'update settings set config_reverse_proxy_login_header_name="X-WebAuth-User",config_allow_reverse_proxy_header_login=1'

    # Calibre-web 0.6.27 only accepts the ingress auth header from a trusted source address, and
    # defaults that list to "127.0.0.1,::1". Nginx binds its upstream socket to the addon ip
    # (proxy_bind $server_addr in ingress.conf) and calibre-web listens dual-stack, so it sees
    # ::ffff:<addon ip> and drops the header. Both the plain and the ipv4-mapped forms are listed
    # because an ipv4 entry never matches an ipv6-mapped address on the calibre-web side.
    # The column only exists once calibre-web 0.6.27+ has migrated app.db, so a failure here is
    # not fatal : the next start applies it.
    addon_ip=$(bashio::addon.ip_address)
    trusted_ips="127.0.0.1,::1,::ffff:127.0.0.1"
    if bashio::var.has_value "${addon_ip}"; then
        trusted_ips="${trusted_ips},${addon_ip},::ffff:${addon_ip}"
    fi
    trusted_ips_error=$(sqlite3 /config/app.db "update settings set config_reverse_proxy_trusted_ips='${trusted_ips}'" 2>&1) || {
        if echo "${trusted_ips_error}" | grep -q "no such column"; then
            bashio::log.warning "Could not set the ingress trusted ip list, it will be applied at next start"
        else
            bashio::log.warning "Could not set the ingress trusted ip list: ${trusted_ips_error}"
        fi
    }
fi

bashio::log.info "Default username:password is admin:admin123"
