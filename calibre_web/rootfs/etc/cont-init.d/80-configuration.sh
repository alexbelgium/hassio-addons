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

    # Calibre-web 0.6.27 only accepts that header from a trusted source address, and defaults the
    # list to "127.0.0.1,::1". Ingress reaches calibre-web from the addon's own address on the
    # supervisor network (proxy_bind $server_addr in ingress.conf) and calibre-web listens
    # dual-stack, so it sees ::ffff:<addon ip> and drops the header. The supervisor range is
    # listed in both forms because an ipv4 entry never matches an ipv4-mapped address.
    # Prepended to whatever is already there, and only when the mapped form is missing : that form
    # is the one ingress needs and the one nobody types by hand, so it doubles as the marker that
    # this already ran. Anything the user added is kept, the statement runs at most once, and the
    # duplicates it can leave behind are entries calibre-web skips or already trusts.
    # The column only exists once calibre-web 0.6.27+ has migrated app.db and cont-init runs
    # before calibre-web, so a failure here is not fatal : the next start applies it.
    trusted_ips_error=$(sqlite3 /config/app.db "update settings set config_reverse_proxy_trusted_ips='127.0.0.1,::1,::ffff:127.0.0.1,172.30.32.0/23,::ffff:172.30.32.0/119,'||coalesce(config_reverse_proxy_trusted_ips,'') where coalesce(config_reverse_proxy_trusted_ips,'') not like '%::ffff:172.30.32.0/119%'" 2>&1) ||
        bashio::log.warning "Could not set the ingress trusted ip list, it will be applied at next start (${trusted_ips_error})"
fi

bashio::log.info "Default username:password is admin:admin123"
