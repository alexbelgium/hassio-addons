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
    managed_ips="127.0.0.1,::1,::ffff:127.0.0.1"
    if bashio::var.has_value "${addon_ip}"; then
        managed_ips="${managed_ips},${addon_ip},::ffff:${addon_ip}"
    fi
    trusted_ips="${managed_ips}"

    # The same field is where a user lists their own reverse proxy when they reach calibre-web
    # through the exposed port instead of ingress, so the list is merged rather than replaced :
    # everything this script did not put there itself is kept. What was written on the previous
    # start is recorded in /data rather than guessed back from the value, because the addon ip
    # changes across restarts and an entry that is merely left alone would accumulate. A stale
    # 172.30.32.0/23 address can be handed to a different addon later, which would then be
    # trusted to send the auth header.
    managed_ips_state=/data/.reverse_proxy_trusted_ips
    previous_ips=""
    if [ -f "${managed_ips_state}" ]; then
        previous_ips=$(cat "${managed_ips_state}")
    fi
    current_ips=$(sqlite3 /config/app.db "select coalesce(config_reverse_proxy_trusted_ips,'') from settings" 2> /dev/null) || current_ips=""
    IFS=',' read -r -a current_ips_entries <<< "${current_ips}"
    for entry in "${current_ips_entries[@]}"; do
        entry="${entry//[[:space:]]/}"
        if [ -z "${entry}" ]; then
            continue
        fi
        # Already required, or injected by an earlier start : do not carry it over.
        if [[ ",${trusted_ips},${previous_ips}," == *",${entry},"* ]]; then
            continue
        fi
        trusted_ips="${trusted_ips},${entry}"
    done

    if trusted_ips_error=$(sqlite3 /config/app.db "update settings set config_reverse_proxy_trusted_ips='${trusted_ips}'" 2>&1); then
        printf '%s' "${managed_ips}" > "${managed_ips_state}"
    elif echo "${trusted_ips_error}" | grep -q "no such column"; then
        bashio::log.warning "Could not set the ingress trusted ip list, it will be applied at next start"
    else
        bashio::log.warning "Could not set the ingress trusted ip list: ${trusted_ips_error}"
    fi
fi

bashio::log.info "Default username:password is admin:admin123"
