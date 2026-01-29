#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

WIREGUARD_STATE_DIR="/var/run/wireguard"
QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
declare wireguard_config=""
declare wireguard_runtime_config=""
declare interface_name=""

if bashio::fs.directory_exists "${WIREGUARD_STATE_DIR}"; then
    bashio::log.warning "Previous WireGuard state directory found, cleaning up."
    rm -Rf "${WIREGUARD_STATE_DIR}"
fi

if ! bashio::config.true 'wireguard_enabled'; then
    bashio::exit.ok 'WireGuard is disabled.'
elif bashio::config.true 'openvpn_enabled'; then
    bashio::exit.nok 'OpenVPN and WireGuard cannot be enabled simultaneously. Disable one of them.'
fi

mkdir -p "${WIREGUARD_STATE_DIR}"

bashio::log.info "------------------------------"
bashio::log.info "Wireguard enabled, configuring"
bashio::log.info "------------------------------"

if bashio::config.has_value 'wireguard_config'; then
    wireguard_config="$(bashio::config 'wireguard_config')"
    wireguard_config="${wireguard_config##*/}"
    if [[ -z "${wireguard_config}" ]]; then
        bashio::log.info 'wireguard_config option left empty. Attempting automatic selection.'
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
    elif bashio::fs.file_exists "/config/wireguard/${wireguard_config}"; then
        wireguard_config="/config/wireguard/${wireguard_config}"
    else
        bashio::exit.nok "WireGuard configuration '/config/wireguard/${wireguard_config}' not found."
    fi
fi

interface_name="$(basename "${wireguard_config}" .conf)"
if [[ -z "${interface_name}" ]]; then
    interface_name='wg0'
fi

wireguard_runtime_config="${WIREGUARD_STATE_DIR}/${interface_name}.conf"

cp "${wireguard_config}" "${wireguard_runtime_config}"
chmod 600 "${wireguard_runtime_config}"

dos2unix "${wireguard_runtime_config}" >/dev/null 2>&1 || true
sed -i '/^[[:space:]]*[;#]/d' "${wireguard_runtime_config}"
sed -i 's/#.*//' "${wireguard_runtime_config}"
sed -i '/^[[:space:]]*$/d' "${wireguard_runtime_config}"
sed -i '/^[[:blank:]]*$/d' "${wireguard_runtime_config}"
sed -i '/DNS/d' "${wireguard_runtime_config}"
sed -i '/PostUp/d' "${wireguard_runtime_config}"
sed -i '/PostDown/d' "${wireguard_runtime_config}"
sed -i '/SaveConfig/d' "${wireguard_runtime_config}"
sed -i "\$q" "${wireguard_runtime_config}"

bashio::log.info 'Prepared WireGuard runtime configuration for initial connection attempt.'

echo "${wireguard_runtime_config}" > "${WIREGUARD_STATE_DIR}/config"
echo "${interface_name}" > "${WIREGUARD_STATE_DIR}/interface"

bashio::log.info "Using interface binding in the qBittorrent app"

if bashio::fs.file_exists "${QBT_CONFIG_FILE}"; then
    sed -i '/Interface/d' "${QBT_CONFIG_FILE}"
    sed -i "/\\[Preferences\\]/ i\\Connection\\\\Interface=${interface_name}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[Preferences\\]/ i\\Connection\\\\InterfaceName=${interface_name}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[BitTorrent\\]/a \\Session\\\\Interface=${interface_name}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[BitTorrent\\]/a \\Session\\\\InterfaceName=${interface_name}" "${QBT_CONFIG_FILE}"
else
    bashio::log.warning "qBittorrent config file not found. Bind the client manually to interface ${interface_name}."
fi

bashio::log.info "WireGuard prepared with interface ${interface_name} using configuration ${wireguard_config##*/}."
