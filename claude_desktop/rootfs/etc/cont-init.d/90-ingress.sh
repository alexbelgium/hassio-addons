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
# Same value 20-folders.sh exports to the Selkies services; both must move together or nginx
# proxies the data websocket to a port nothing listens on. That script also normalises it into
# the s6 envdir, which this one picks up through with-contenv; the check is repeated so a
# malformed value cannot reach the nginx config if 20-folders.sh did not get that far.
CWS="${CUSTOM_WS_PORT:-8082}"
if ! [[ "$CWS" =~ ^[0-9]+$ ]] || [ "$CWS" -lt 1 ] || [ "$CWS" -gt 65535 ]; then
    CWS=8082
fi
sed -i "s|CWS|${CWS}|g" "${NGINX_CONFIG}"
sed -i "s|REPLACE_HOME|${HOME:-/root}|g" "${NGINX_CONFIG}"
sed -i "s|REPLACE_DOWNLOADS_PATH|${HOME:-/config}|g" "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a proxy_set_header Accept-Encoding "";' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter_once off;' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter_types *;' "${NGINX_CONFIG}"
sed -i '/proxy_buffering/a sub_filter "vnc/index.html?autoconnect" "vnc/index.html?path=%%path%%/websockify?autoconnect";' "${NGINX_CONFIG}"
sed -i "s|%%path%%|${SUBFOLDER:1}|g" "${NGINX_CONFIG}"

# Avoid content encoding on proxied responses to keep Selkies happy (handled by proxy_set_header Accept-Encoding insertion above)
cp "${NGINX_CONFIG}" /etc/nginx/sites-enabled
