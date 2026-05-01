#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -Eeuo pipefail

# HA Supervisor places options.json at /data/options.json.
# NPM also uses /data for its database and generated configs.
# The /data Docker VOLUME is persisted automatically by HA Supervisor between restarts.
OPTIONS_JSON="/data/options.json"

log() { echo "[nginx-proxy-manager-addon] $*"; }
warn() { echo "[nginx-proxy-manager-addon] WARN: $*" >&2; }
die() {
    echo "[nginx-proxy-manager-addon] ERROR: $*" >&2
    exit 1
}

read_opt() {
    jq -er --arg k "$1" '.[$k]' "$OPTIONS_JSON" 2> /dev/null || true
}

# ---------------------------------------------------------------------------
# Step 1: Read add-on options
# ---------------------------------------------------------------------------
[[ -f "$OPTIONS_JSON" ]] || die "Missing options file at ${OPTIONS_JSON}"

STATIC_ENABLED="$(read_opt static_site_enabled)"
STATIC_ENABLED="${STATIC_ENABLED:-true}"
STATIC_ROOT_RAW="$(read_opt static_site_root)"
STATIC_ROOT_RAW="${STATIC_ROOT_RAW:-/share/www}"
STATIC_PREFIX="$(read_opt static_site_prefix)"
STATIC_PREFIX="${STATIC_PREFIX:-/}"
LOG_LEVEL="$(read_opt log_level)"
LOG_LEVEL="${LOG_LEVEL:-info}"

# ---------------------------------------------------------------------------
# Step 2: Validate static_site_root
# ---------------------------------------------------------------------------
normalize_path() {
    if command -v realpath > /dev/null 2>&1; then
        realpath -m -- "$1"
    else
        local p="${1%/}"
        [[ "$p" == /* ]] || p="/$p"
        printf '%s\n' "$p"
    fi
}

STATIC_ROOT="$(normalize_path "$STATIC_ROOT_RAW")"

case "$STATIC_ROOT" in
    / | /etc | /etc/* | /bin | /bin/* | /sbin | /sbin/* | /lib | /lib/* | /proc | /proc/* | /sys | /sys/*)
        die "static_site_root '${STATIC_ROOT}' is a dangerous system path. Use /share, /media, /config, or /mnt."
        ;;
esac

case "$STATIC_ROOT" in
    /share | /share/* | /media | /media/* | /config | /config/*)
        log "static_site_root: ${STATIC_ROOT}"
        ;;
    /mnt | /mnt/*)
        warn "static_site_root '${STATIC_ROOT}' is under /mnt — HA cannot map /mnt."
        warn "If files are inaccessible, create a symlink under /share or /media pointing to your /mnt path."
        ;;
    *)
        warn "static_site_root '${STATIC_ROOT}' is outside standard HA-mapped paths — may not be accessible."
        ;;
esac

[[ "$STATIC_PREFIX" == /* ]] || die "static_site_prefix must start with '/'. Got: '${STATIC_PREFIX}'"

# ---------------------------------------------------------------------------
# Step 3: Write static-site server block into NPM's default_host dir
# NPM includes /data/nginx/default_host/*.conf for the port 80 default server.
# Writing here replaces NPM's "Congratulations" page with our static file server.
# ---------------------------------------------------------------------------
DEFAULT_HOST_DIR="/data/nginx/default_host"
mkdir -p "$DEFAULT_HOST_DIR"
STATIC_CONF="${DEFAULT_HOST_DIR}/static_site.conf"

if [[ "$STATIC_ENABLED" == "true" ]]; then
    mkdir -p "$STATIC_ROOT" 2> /dev/null \
        || warn "Could not create '${STATIC_ROOT}' (may not be mounted yet)"

    cat > "$STATIC_CONF" << NGINX_EOF
# Managed by nginx_webserver_proxy add-on — regenerated on every container start.
# Edit options in the HA add-on configuration UI, not here.
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location ${STATIC_PREFIX} {
        alias ${STATIC_ROOT}/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        try_files \$uri \$uri/ =404;
        access_log /proc/1/fd/1;
        error_log  /proc/1/fd/1 warn;
    }
}
NGINX_EOF
    log "Static site config written → ${STATIC_CONF}"
else
    printf '# Static site disabled by add-on options\n' > "$STATIC_CONF"
    log "Static site disabled"
fi

# ---------------------------------------------------------------------------
# Step 4: Hand off to NPM's own s6-overlay boot
# ---------------------------------------------------------------------------
log "static_site_root=${STATIC_ROOT} prefix=${STATIC_PREFIX} log_level=${LOG_LEVEL}"
# NPM's prepare service requires /etc/letsencrypt to exist.
# HA Supervisor maps the ssl volume there automatically; for other environments create it.
mkdir -p /etc/letsencrypt

log "Handing off to NPM: exec /init"
exec /init
