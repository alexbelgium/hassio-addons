#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

WIREGUARD_STATE_DIR="/var/run/wireguard"
QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
declare wireguard_config=""
declare wireguard_runtime_config=""
declare configured_name

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

dos2unix "${wireguard_config}" > /dev/null 2>&1 || true

interface_name="$(basename "${wireguard_config}" .conf)"
if [[ -z "${interface_name}" ]]; then
    interface_name='wg0'
fi

wireguard_runtime_config="${WIREGUARD_STATE_DIR}/${interface_name}.conf"

cp "${wireguard_config}" "${wireguard_runtime_config}"
chmod 600 "${wireguard_runtime_config}" 2> /dev/null || true
bashio::log.info 'Prepared WireGuard runtime configuration for initial connection attempt.'

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
