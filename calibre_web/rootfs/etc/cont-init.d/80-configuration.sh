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
    addon_ip=$(bashio::addon.ip_address)
    trusted_ips="127.0.0.1,::1,::ffff:127.0.0.1"
    if bashio::var.has_value "${addon_ip}"; then
        trusted_ips="${trusted_ips},${addon_ip},::ffff:${addon_ip}"
    fi

    # The same field is where a user lists their own reverse proxy when they reach calibre-web
    # through the exposed port instead of ingress, so the list is merged rather than replaced.
    # Carried over : every entry outside the ranges this script manages itself. Dropped : the
    # loopback and 172.30.32.0/23 forms, because the addon ip changes across restarts and an
    # entry left in place would accumulate -- supervisor can hand that address to a different
    # addon later, which would then be trusted to send the auth header. The current addon ip is
    # re-added above, so dropping the whole range costs nothing and needs no state kept between
    # starts. Entries are also restricted to the characters an ip or a cidr can contain : that is
    # all calibre-web accepts, and it keeps the value safe to interpolate into the statement.
    current_ips=$(sqlite3 /config/app.db "select coalesce(config_reverse_proxy_trusted_ips,'') from settings" 2> /dev/null) || current_ips=""
    IFS=',' read -r -a current_ips_entries <<< "${current_ips}"
    for entry in "${current_ips_entries[@]}"; do
        entry="${entry//[[:space:]]/}"
        case "${entry,,}" in
            "" | *[!0-9a-f:./]*) continue ;;
            127.* | ::1 | ::ffff:127.* ) continue ;;
            172.30.3[23].* | ::ffff:172.30.3[23].* | ::ffff:ac1e:2[01]??) continue ;;
        esac
        if [[ ",${trusted_ips}," == *",${entry},"* ]]; then
            continue
        fi
        trusted_ips="${trusted_ips},${entry}"
    done

    # The column only exists once calibre-web 0.6.27+ has migrated app.db, and cont-init runs
    # before calibre-web, so a failure here is not fatal : the next start applies it. Any other
    # sqlite error is reported as-is rather than hidden behind that message.
    if ! trusted_ips_error=$(sqlite3 /config/app.db "update settings set config_reverse_proxy_trusted_ips='${trusted_ips}'" 2>&1); then
        if echo "${trusted_ips_error}" | grep -q "no such column"; then
            bashio::log.warning "Could not set the ingress trusted ip list, it will be applied at next start"
        else
            bashio::log.warning "Could not set the ingress trusted ip list: ${trusted_ips_error}"
        fi
    fi
fi

bashio::log.info "Default username:password is admin:admin123"
