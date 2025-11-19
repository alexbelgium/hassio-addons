#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

WIREGUARD_STATE_DIR="/var/run/wireguard"
QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
declare wireguard_config=""
declare wireguard_runtime_config=""
declare wireguard_runtime_config_ipv4=""
declare configured_name

create_ipv4_only_config() {
    local source_file="$1"
    local target_file="$2"
    local temp_file

    temp_file="$(mktemp)"

    awk 'BEGIN { IGNORECASE = 1 }
function trim(str) {
    gsub(/^[ \t]+/, "", str)
    gsub(/[ \t]+$/, "", str)
    return str
}
{
    line = $0
    if (match(line, /^([[:space:]]*)(Address|AllowedIPs|DNS)([[:space:]]*=[[:space:]]*)(.*)$/, parts)) {
        prefix = parts[1]
        key = parts[2]
        sep = parts[3]
        rest = parts[4]
        comment = ""
        hash_index = index(rest, "#")
        if (hash_index > 0) {
            comment = substr(rest, hash_index)
            rest = substr(rest, 1, hash_index - 1)
        }
        gsub(/[\r\n]+/, "", rest)
        delete filtered
        filtered_count = 0
        n = split(rest, raw, /[,[:space:]]+/)
        for (i = 1; i <= n; i++) {
            entry = trim(raw[i])
            if (entry == "") {
                continue
            }
            if (index(entry, ":") > 0) {
                continue
            }
            filtered[++filtered_count] = entry
        }
        if (filtered_count == 0) {
            if (comment != "") {
                print prefix comment
            }
            next
        }
        line = prefix key sep filtered[1]
        for (i = 2; i <= filtered_count; i++) {
            line = line ", " filtered[i]
        }
        if (comment != "") {
            line = line comment
        }
        print line
        next
    }
    print line
}' "${source_file}" > "${temp_file}"

    if cmp -s "${source_file}" "${temp_file}"; then
        rm -f "${temp_file}" "${target_file}" "${WIREGUARD_STATE_DIR}/config_ipv4"
        return 1
    fi

    mv "${temp_file}" "${target_file}"
    chmod 600 "${target_file}" 2>/dev/null || true
    echo "${target_file}" > "${WIREGUARD_STATE_DIR}/config_ipv4"
    bashio::log.info "Prepared IPv4-only WireGuard fallback configuration at ${target_file##*/}."
    return 0
}

mkdir -p "${WIREGUARD_STATE_DIR}"

if ! bashio::config.true 'wireguard_enabled'; then
    rm -f "${WIREGUARD_STATE_DIR}/config" "${WIREGUARD_STATE_DIR}/interface"
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
wireguard_runtime_config_ipv4="${WIREGUARD_STATE_DIR}/${interface_name}.ipv4.conf"

cp "${wireguard_config}" "${wireguard_runtime_config}"
chmod 600 "${wireguard_runtime_config}" 2>/dev/null || true
bashio::log.info 'Prepared WireGuard runtime configuration with both IPv4 and IPv6 entries.'

if ! create_ipv4_only_config "${wireguard_runtime_config}" "${wireguard_runtime_config_ipv4}"; then
    bashio::log.debug 'IPv4-only WireGuard fallback configuration not required for this setup.'
fi

echo "${wireguard_runtime_config}" > "${WIREGUARD_STATE_DIR}/config"
echo "${interface_name}" > "${WIREGUARD_STATE_DIR}/interface"

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
