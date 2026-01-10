#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

APP_UID=20211
APP_GID=20211

: "${TMP_DIR:=/tmp}"
: "${NETALERTX_DATA:=/config}"
: "${NETALERTX_DB:=/config/db}"
: "${NETALERTX_CONFIG:=/config/config}"
: "${SYSTEM_NGINX_CONFIG_TEMPLATE:=/etc/nginx/nginx.conf.template}"

config_file="/config/config/app.conf"

# State files (persistent across restarts)
state_dir="/config/.netalertx_state"
sig_file="$state_dir/appconf.sha256"
restart_lock="$state_dir/restart_in_progress"

mkdir -p "$state_dir"

##############################
# Create required directories #
##############################

mkdir -p \
  /config /config/db /config/config \
  /data \
  /tmp/run/tmp /tmp/api /tmp/log /tmp/run /tmp/nginx/active-config \
  "$TMP_DIR" \
  "$NETALERTX_DATA" \
  "$NETALERTX_DB" \
  "$NETALERTX_CONFIG"

# Best-effort perms (don’t fail on edge cases)
chown -R "$APP_UID:$APP_GID" /config/db /config/config "$NETALERTX_DB" "$NETALERTX_CONFIG" \
  /tmp/run/tmp /tmp/api /tmp/log /tmp/run /tmp/nginx/active-config "$TMP_DIR" 2>/dev/null || true
chmod -R 755 /config/db /config/config "$NETALERTX_DB" "$NETALERTX_CONFIG" \
  /tmp/run/tmp /tmp/api /tmp/log /tmp/run /tmp/nginx/active-config "$TMP_DIR" 2>/dev/null || true

chmod -R 1777 /tmp 2>/dev/null || true
chmod 666 /dev/stdout /dev/stderr 2>/dev/null || true

touch /tmp/log/app.php_errors.log /tmp/log/cron.log /tmp/log/stdout.log /tmp/log/stderr.log
chown "$APP_UID:$APP_GID" /tmp/log/*.log 2>/dev/null || true
chmod 644 /tmp/log/*.log 2>/dev/null || true

# /data symlinks -> /config
rm -rf /data/db /data/config
ln -sf /config/db /data/db
ln -sf /config/config /data/config

################
# Fix scripts  #
################

if [ -f /services/start-php-fpm.sh ]; then
  sed -i 's|>>"\?/tmp/log/app\.php_errors\.log"\? 2>/dev/stderr|>>"/tmp/log/app.php_errors.log"|g' /services/start-php-fpm.sh
  sed -i 's|TEMP_CONFIG_FILE=$(mktemp "${TMP_DIR}/netalertx\.conf\.XXXXXX")|TEMP_CONFIG_FILE=$(mktemp -p "${TMP_DIR:-/tmp}" netalertx.conf.XXXXXX)|' /services/start-php-fpm.sh
fi

if [ -n "${SYSTEM_NGINX_CONFIG_TEMPLATE:-}" ] && [ -f "${SYSTEM_NGINX_CONFIG_TEMPLATE:-}" ]; then
  sed -i '/default_type/a include /etc/nginx/http.d/ingress.conf;' "${SYSTEM_NGINX_CONFIG_TEMPLATE}" 2>/dev/null || true
fi

#####################
# Helper: signature #
#####################

appconf_signature() {
  # Prints sha256 or nothing if missing
  if [ -f "$config_file" ]; then
    sha256sum "$config_file" | awk '{print $1}'
  fi
}

record_signature() {
  sig="$(appconf_signature || true)"
  if [ -n "${sig:-}" ]; then
    printf '%s\n' "$sig" >"$sig_file"
  fi
}

signature_changed_or_unknown() {
  # Returns 0 (true) if app.conf exists and signature differs from recorded (or no recorded signature)
  [ -f "$config_file" ] || return 1
  current="$(appconf_signature || true)"
  [ -n "${current:-}" ] || return 1

  if [ ! -f "$sig_file" ]; then
    return 0
  fi

  recorded="$(cat "$sig_file" 2>/dev/null || true)"
  [ "$current" != "$recorded" ]
}

#############################################
# One-time restart when app.conf is created #
#############################################

wait_for_appconf_then_restart_once() {
  # Prevent concurrent watcher restarts
  if [ -f "$restart_lock" ]; then
    exit 0
  fi
  touch "$restart_lock" || true

  bashio::log.info "Waiting for NetAlertX to create $config_file ..."

  while [ ! -f "$config_file" ]; do
    sleep 2
  done

  # Wait for stability (size unchanged across checks)
  last_size=""
  stable_count=0
  while [ "$stable_count" -lt 3 ]; do
    size="$(wc -c <"$config_file" 2>/dev/null || echo 0)"
    if [ "$size" = "$last_size" ] && [ "$size" -gt 0 ]; then
      stable_count=$((stable_count + 1))
    else
      stable_count=0
    fi
    last_size="$size"
    sleep 2
  done

  # Record signature so we don't re-restart for the same file
  record_signature

  bashio::log.notice "app.conf detected and stable. Restarting add-on once."
  rm -f "$restart_lock" 2>/dev/null || true
  bashio::addon.restart
}

#####################
# Configure network #
#####################

execute_main_logic() {
  bashio::log.info "Initiating scan of Home Assistant network configuration..."

  local_ip="$(bashio::network.ipv4_address | head -n 1)"
  local_ip="${local_ip%/*}"

  if [ -z "$local_ip" ]; then
    bashio::log.error "Could not determine local IPv4 address"
    return 0
  fi

  if ! command -v arp-scan >/dev/null 2>&1; then
    bashio::log.error "arp-scan command not found."
    exit 1
  fi

  if [ ! -f "$config_file" ]; then
    bashio::log.warning "$config_file missing; nothing to update."
    return 0
  fi

  if ! grep -q "^SCAN_SUBNETS" "$config_file"; then
    bashio::log.fatal "SCAN_SUBNETS is not found in $config_file"
    exit 1
  fi

  for interface in $(bashio::network.interfaces); do
    bashio::log.info "Scanning interface: $interface"

    if grep -q -- "$interface" "$config_file"; then
      continue
    fi

    SCAN_SUBNETS="$(grep "^SCAN_SUBNETS" "$config_file" | head -n 1)"

    if [[ "$SCAN_SUBNETS" == *"$local_ip"*"$interface"* ]]; then
      continue
    fi

    if [[ "$SCAN_SUBNETS" =~ ^SCAN_SUBNETS=\[\]$ ]]; then
      NEW_SCAN_SUBNETS="SCAN_SUBNETS=['${local_ip}/24 --interface=${interface}']"
    else
      NEW_SCAN_SUBNETS="${SCAN_SUBNETS%]} , '${local_ip}/24 --interface=${interface}']"
    fi

    sed -i "/^SCAN_SUBNETS/c\\$NEW_SCAN_SUBNETS" "$config_file"

    VALUE="$(
      arp-scan --interface="$interface" "${local_ip}/24" 2>/dev/null \
        | grep "responded" \
        | awk -F'.' '{print $NF}' \
        | awk '{print $1}' || true
    )"

    bashio::log.info "Added ${interface} (${VALUE:-0} devices) to SCAN_SUBNETS"
  done

  # Update signature after modifications
  record_signature
  bashio::log.info "Network scan completed."
}

###################
# Main entrypoint #
###################

# Case 1: app.conf is missing -> let NetAlertX generate it, then restart once.
if [ ! -f "$config_file" ]; then
  wait_for_appconf_then_restart_once &
  exit 0
fi

# Case 2: app.conf exists but is "new" (user deleted/recreated, or NetAlertX regenerated)
# => restart once to allow NetAlertX to re-bootstrap cleanly, then continue on next boot.
if signature_changed_or_unknown; then
  bashio::log.notice "Detected new or changed app.conf instance; restarting add-on once to re-bootstrap."
  record_signature
  bashio::addon.restart
fi

# Normal run
execute_main_logic
