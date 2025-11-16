#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

NGINX_CONFIG=/etc/nginx/sites-available/ingress.conf
SUBFOLDER="$(bashio::addon.ingress_entry)"

# Ensure subfolder ends with a trailing slash (except for root)
if [[ -n "${SUBFOLDER}" && "${SUBFOLDER}" != "/" ]]; then
    [[ "${SUBFOLDER}" == */ ]] || SUBFOLDER="${SUBFOLDER}/"
else
    SUBFOLDER="/"
fi

cp /defaults/default.conf "${NGINX_CONFIG}"

# Keep only the first (non-SSL) server block
awk -v n=2 '/^[[:space:]]*server[[:space:]]*\{/{n--} n>0' "${NGINX_CONFIG}" > tmpfile
mv tmpfile "${NGINX_CONFIG}"

# Disable IPv6 listeners for ingress proxying
sed -i '/listen \[::\]/d' "${NGINX_CONFIG}"

# Adapt ports and upstream paths for Home Assistant ingress
sed -i "s|3000|$(bashio::addon.ingress_port)|g" "${NGINX_CONFIG}"
sed -i "s|SUBFOLDER|/|g" "${NGINX_CONFIG}"
sed -i "s|CWS|8082|g" "${NGINX_CONFIG}"
sed -i "s|REPLACE_HOME|${HOME:-/root}|g" "${NGINX_CONFIG}"
sed -i "s|REPLACE_DOWNLOADS_PATH|${HOME:-/config}|g" "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a proxy_set_header Accept-Encoding "";' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter_once off;' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter_types *;' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter "vnc/index.html?autoconnect" "vnc/index.html?path=%%path%%/websockify?autoconnect";' "${NGINX_CONFIG}"
sed -i "s|%%path%%|${SUBFOLDER:1}|g" "${NGINX_CONFIG}"

# Avoid content encoding on proxied responses to keep Selkies happy
sed -i '/proxy_buffering/a \
    proxy_set_header Accept-Encoding "";' "${NGINX_CONFIG}"

cp "${NGINX_CONFIG}" /etc/nginx/sites-enabled
