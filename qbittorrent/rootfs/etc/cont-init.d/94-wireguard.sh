#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

WIREGUARD_STATE_DIR="/var/run/wireguard"
QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
WIREGUARD_IPV6_STATE_FILE="${WIREGUARD_STATE_DIR}/ipv6_state"
declare wireguard_config=""
declare wireguard_runtime_config=""
declare configured_name

wireguard_ipv6_supported() {
    local ipv6_disabled="0"
    if command -v sysctl >/dev/null 2>&1; then
        ipv6_disabled="$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null || echo 0)"
    fi

    if [[ "${ipv6_disabled}" == "1" ]]; then
        return 1
    fi

    if [[ ! -s /proc/net/if_inet6 ]]; then
        return 1
    fi

    return 0
}

record_ipv6_state() {
    local state="$1"
    echo "${state}" > "${WIREGUARD_IPV6_STATE_FILE}"
}

mkdir -p "${WIREGUARD_STATE_DIR}"

if ! bashio::config.true 'wireguard_enabled'; then
    rm -f "${WIREGUARD_STATE_DIR}/config" "${WIREGUARD_STATE_DIR}/interface" "${WIREGUARD_IPV6_STATE_FILE}"
    exit 0
fi

if bashio::config.true 'openvpn_enabled'; then
    bashio::exit.nok 'OpenVPN and WireGuard cannot be enabled simultaneously. Disable one of them.'
fi

if bashio::config.true 'openvpn_alt_mode'; then
    bashio::log.warning 'The openvpn_alt_mode option is ignored when WireGuard is enabled.'
fi

if bashio::config.has_value 'wireguard_config'; then
    configured_name="$(bashio::config 'wireguard_config')"
    configured_name="${configured_name##*/}"
    if [[ -z "${configured_name}" ]]; then
        bashio::log.info 'wireguard_config option left empty. Attempting automatic selection.'
    elif bashio::fs.file_exists "/config/wireguard/${configured_name}"; then
        wireguard_config="/config/wireguard/${configured_name}"
    else
        bashio::exit.nok "WireGuard configuration '/config/wireguard/${configured_name}' not found."
    fi
fi

if [ -z "${wireguard_config:-}" ]; then
    mapfile -t configs < <(find /config/wireguard -maxdepth 1 -type f -name '*.conf' -print)
    if [ "${#configs[@]}" -eq 0 ]; then
        bashio::exit.nok 'WireGuard is enabled but no .conf file was found in /config/wireguard.'
    elif [ "${#configs[@]}" -eq 1 ]; then
        wireguard_config="${configs[0]}"
        bashio::log.info "WireGuard configuration not specified. Using ${wireguard_config##*/}."
    elif bashio::fs.file_exists '/config/wireguard/config.conf'; then
        wireguard_config='/config/wireguard/config.conf'
        bashio::log.info 'Using default WireGuard configuration config.conf.'
    else
        bashio::exit.nok "Multiple WireGuard configuration files detected. Please set the 'wireguard_config' option."
    fi
fi

dos2unix "${wireguard_config}" >/dev/null 2>&1 || true

interface_name="$(basename "${wireguard_config}" .conf)"
if [[ -z "${interface_name}" ]]; then
    interface_name='wg0'
fi

wireguard_runtime_config="${WIREGUARD_STATE_DIR}/${interface_name}.conf"

cp "${wireguard_config}" "${wireguard_runtime_config}"
chmod 600 "${wireguard_runtime_config}" 2>/dev/null || true
bashio::log.info 'Prepared WireGuard runtime configuration copy. Performing compatibility checks next.'

echo "${wireguard_runtime_config}" > "${WIREGUARD_STATE_DIR}/config"
echo "${interface_name}" > "${WIREGUARD_STATE_DIR}/interface"

if wireguard_ipv6_supported; then
    record_ipv6_state 'enabled'
else
    record_ipv6_state 'disabled'
    if command -v python3 >/dev/null 2>&1; then
        if WIREGUARD_RUNTIME_CONFIG="${wireguard_runtime_config}" python3 <<'PY'
import os
from pathlib import Path

runtime_config = Path(os.environ['WIREGUARD_RUNTIME_CONFIG'])
raw_text = runtime_config.read_text()
lines = raw_text.splitlines()
keys = {'Address', 'AllowedIPs', 'DNS'}
changed = False
result = []

for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith('#') or '=' not in line:
        result.append(line)
        continue

    key, rest = line.split('=', 1)
    key_name = key.strip()
    if key_name not in keys:
        result.append(line)
        continue

    comment = ''
    if '#' in rest:
        rest, comment = rest.split('#', 1)
        comment = '#' + comment

    values = [entry.strip() for entry in rest.split(',') if entry.strip()]
    filtered = [entry for entry in values if ':' not in entry]

    if len(filtered) != len(values):
        changed = True

    if filtered:
        new_line = f"{key.rstrip()} = {', '.join(filtered)}"
        if comment:
            new_line = f"{new_line} {comment.strip()}"
        result.append(new_line)
    else:
        if comment:
            result.append(comment.strip())

if changed:
    ending = '\n' if raw_text.endswith('\n') else ''
    runtime_config.write_text('\n'.join(result) + ending)
PY
        then
            bashio::log.warning 'IPv6 support not detected on the host. IPv6 entries have been stripped from the WireGuard runtime configuration.'
        else
            bashio::log.warning 'IPv6 support not detected and automatic IPv6 stripping failed. Please ensure your WireGuard configuration only contains IPv4 values.'
        fi
    else
        bashio::log.warning 'IPv6 support not detected but python3 is unavailable. Please provide an IPv4-only WireGuard configuration.'
    fi
fi

if bashio::fs.file_exists "${QBT_CONFIG_FILE}"; then
    sed -i '/Interface/d' "${QBT_CONFIG_FILE}"
    sed -i "/\\[Preferences\\]/ i\\Connection\\\\Interface=${interface_name}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[Preferences\\]/ i\\Connection\\\\InterfaceName=${interface_name}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[BitTorrent\\]/a \\Session\\\\Interface=${interface_name}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[BitTorrent\\]/a \\Session\\\\InterfaceName=${interface_name}" "${QBT_CONFIG_FILE}"
else
    bashio::log.warning "qBittorrent config file not found. Bind the client manually to interface ${interface_name}."
fi

# Get current ip
curl -s ipecho.net/plain > /currentip

bashio::log.info "WireGuard prepared with interface ${interface_name} using configuration ${wireguard_config##*/}."
