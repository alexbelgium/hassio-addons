#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

CONFIG_LOCATION="/config"
bashio::log.info "Config stored in $CONFIG_LOCATION"

mkdir -p "$CONFIG_LOCATION/.pg0"
mkdir -p /home/hindsight

# Symlink /home/hindsight/.pg0 to HA persistent storage
if [ -d /home/hindsight/.pg0 ] && [ ! -L /home/hindsight/.pg0 ]; then
    if ! cp -rn /home/hindsight/.pg0/. "$CONFIG_LOCATION/.pg0/"; then
        echo "[ERROR] Copy from /home/hindsight/.pg0 to $CONFIG_LOCATION/.pg0 failed. Keeping source directory." >&2
        exit 1
    fi
    rm -rf /home/hindsight/.pg0
fi
ln -sfn "$CONFIG_LOCATION/.pg0" /home/hindsight/.pg0

# Ensure persistent database directory is owned by hindsight user (UID 1000)
# Re-owns files on boot in case permissions or user context changed
chown -R hindsight:hindsight "$CONFIG_LOCATION/.pg0" /home/hindsight 2>/dev/null || true
chmod 700 "$CONFIG_LOCATION/.pg0" 2>/dev/null || true

# Clean empty strings in /.env for optional API credentials
if [ -f /.env ]; then
    sed -i '/^HINDSIGHT_API_LLM_API_KEY=""$/d' /.env 2>/dev/null || true
    sed -i '/^HINDSIGHT_API_LLM_BASE_URL=""$/d' /.env 2>/dev/null || true
fi

# Ensure timezone is applied
if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" > /etc/timezone
fi
