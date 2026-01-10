#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Update structure #
####################

APP_UID=20211

# CRITICAL: ensure newly-created files (like /config/config/app.conf on first run) are not root-only
umask 022
export UMASK=022

# Ensure base dirs exist and have sane perms for the app user
mkdir -p /config/config /config/db
chown -R "${APP_UID}:${APP_UID}" /config/config /config/db
chmod 775 /config/config /config/db

# 1. Fix the directories (skip empty vars)
for folder in \
    /tmp/run/tmp \
    /tmp/api \
    /tmp/log \
    /tmp/run \
    /tmp/nginx/active-config \
    "${TMP_DIR:-}" \
    "${NETALERTX_DATA:-}" \
    "${NETALERTX_DB:-}" \
    "${NETALERTX_CONFIG:-}"
do
    [[ -z "${folder}" ]] && continue
    mkdir -p "${folder}"
    chown -R "${APP_UID}:${APP_UID}" "${folder}"
    chmod -R 755 "${folder}"
done

# 2. Fix /tmp and Standard Streams (CRITICAL)
chmod -R 1777 /tmp
# Allow non-root user to write to container logs
chmod 666 /dev/stdout /dev/stderr

# 3. Pre-create and chown log files
touch /tmp/log/app.php_errors.log /tmp/log/cron.log /tmp/log/stdout.log /tmp/log/stderr.log
chown "${APP_UID}:${APP_UID}" /tmp/log/*.log

# 4. Create Symlinks
for item in db config; do
    rm -rf "/data/${item}"
    ln -sf "/config/${item}" "/data/${item}"
    chown -R "${APP_UID}:${APP_UID}" "/data/${item}"
    chmod -R 755 "/data/${item}"
done

# Fix php
sed -i 's|>>"\?/tmp/log/app\.php_errors\.log"\? 2>/dev/stderr|>>"/tmp/log/app.php_errors.log"|g' /services/start-php-fpm.sh
sed -i 's|TEMP_CONFIG_FILE=$(mktemp "${TMP_DIR}/netalertx\.conf\.XXXXXX")|TEMP_CONFIG_FILE=$(mktemp -p "${TMP_DIR:-/tmp}" netalertx.conf.XXXXXX)|' /services/start-php-fpm.sh
sed -i "/default_type/a include /etc/nginx/http.d/ingress.conf;" "${SYSTEM_NGINX_CONFIG_TEMPLATE}"

#####################
# Configure network #
#####################

config_file="/config/config/app.conf"

# If DB already exists, ensure it’s readable/writable by the app user
if [[ -f /config/db/app.db ]]; then
    chown "${APP_UID}:${APP_UID}" /config/db/app.db || true
    chmod 664 /config/db/app.db || true
fi

execute_main_logic() {
    bashio::log.info "Initiating scan of Home Assistant network configuration..."

    local_ip="$(bashio::network.ipv4_address)"
    local_ip="${local_ip%/*}"
    echo "... Detected local IP: ${local_ip}"
    echo "... Scanning network for changes"

    if ! command -v arp-scan &>/dev/null; then
        bashio::log.error "arp-scan command not found. Please install arp-scan to proceed."
        exit 1
    fi

    if [[ ! -f "${config_file}" ]]; then
        bashio::log.warning "Config file not present yet (${config_file}); skipping network scan update."
        return 0
    fi

    # Make sure the app user can read it (covers upgrades / odd umask cases)
    chown "${APP_UID}:${APP_UID}" "${config_file}" 2>/dev/null || true
    chmod 664 "${config_file}" 2>/dev/null || true

    if ! grep -q "^SCAN_SUBNETS" "${config_file}"; then
        bashio::log.fatal "SCAN_SUBNETS is not found in ${config_file}, please correct your file first"
        return 1
    fi

    for interface in $(bashio::network.interfaces); do
        echo "Scanning interface: ${interface}"

        if grep -q "${interface}" "${config_file}"; then
            echo "... ${interface} is already configured in app.conf"
            continue
        fi

        SCAN_SUBNETS="$(grep "^SCAN_SUBNETS" "${config_file}" | head -1)"
        if [[ "${SCAN_SUBNETS}" != *"${local_ip}"*"${interface}"* ]]; then
            NEW_SCAN_SUBNETS="${SCAN_SUBNETS%]}, '${local_ip}/24 --interface=${interface}']"
            sed -i "/^SCAN_SUBNETS/c\\${NEW_SCAN_SUBNETS}" "${config_file}"

            VALUE="$(arp-scan --interface="${interface}" "${local_ip}/24" 2>/dev/null \
                | grep "responded" \
                | awk -F'.' '{print $NF}' \
                | awk '{print $1}' || true)"

            echo "... ${interface} is available in Home Assistant (with ${VALUE} devices), added to app.conf"
        fi
    done

    bashio::log.info "Network scan completed."
}

execute_main_logic || true
