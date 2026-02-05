#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

OPENVPN_STATE_DIR="/var/run/openvpn"
QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
declare openvpn_config=""
declare openvpn_runtime_config=""
declare interface_name=""
declare openvpn_username
declare openvpn_password

if bashio::fs.directory_exists "${OPENVPN_STATE_DIR}"; then
    bashio::log.warning "Previous OpenVPN state directory found, cleaning up."
    rm -Rf "${OPENVPN_STATE_DIR}"
fi

if ! bashio::config.true 'openvpn_enabled'; then
    bashio::exit.ok 'OpenVPN is disabled.'
elif bashio::config.true 'wireguard_enabled'; then
    bashio::log.fatal 'OpenVPN and WireGuard cannot be enabled simultaneously. Disable one of them.'
    bashio::addon.stop
fi

mkdir -p "${OPENVPN_STATE_DIR}"

bashio::log.info "----------------------------"
bashio::log.info "Openvpn enabled, configuring"
bashio::log.info "----------------------------"

# Set credentials
if bashio::config.has_value "openvpn_username"; then
    openvpn_username=$(bashio::config 'openvpn_username')
else
    bashio::log.fatal "Openvpn is enabled, but openvpn_username option is empty! Exiting"
    bashio::addon.stop
fi
if bashio::config.has_value "openvpn_password"; then
    openvpn_password=$(bashio::config 'openvpn_password')
else
    bashio::log.fatal "Openvpn is enabled, but openvpn_password option is empty! Exiting"
    bashio::addon.stop
fi

echo -e "${openvpn_username}\n${openvpn_password}" > "${OPENVPN_STATE_DIR}/credentials.conf"
chmod 600 "${OPENVPN_STATE_DIR}/credentials.conf"

if bashio::config.has_value "openvpn_config"; then
    openvpn_config="$(bashio::config 'openvpn_config')"
    openvpn_config="${openvpn_config##*/}"
    if [[ ! "${openvpn_config}" =~ ^[A-Za-z0-9._-]+\.(conf|ovpn)$ ]]; then
        bashio::log.fatal "Invalid openvpn_config filename '${openvpn_config}'. Allowed characters: letters, numbers, dot, underscore, dash. Extension must be .conf or .ovpn."
        bashio::addon.stop
    fi
fi
if [[ -z "${openvpn_config}" ]]; then
    bashio::log.info 'openvpn_config option left empty. Attempting automatic selection.'
        mapfile -t configs < <(find /config/openvpn -maxdepth 1 \( -type f -name '*.conf' -o -name '*.ovpn' \) -print)
    if [ "${#configs[@]}" -eq 0 ]; then
        bashio::log.fatal 'OpenVPN is enabled but no .conf or .ovpn file was found in /config/openvpn.'
        bashio::addon.stop
    elif [ "${#configs[@]}" -eq 1 ]; then
        openvpn_config="${configs[0]}"
        bashio::log.info "OpenVPN configuration not specified. Using ${openvpn_config##*/}."
    elif bashio::fs.file_exists '/config/openvpn/config.conf'; then
        openvpn_config='/config/openvpn/config.conf'
        bashio::log.info 'Using default OpenVPN configuration config.conf.'
    else
        bashio::log.fatal "Multiple OpenVPN configuration files detected. Please set the 'openvpn_config' option."
        bashio::addon.stop
    fi
elif bashio::fs.file_exists "/config/openvpn/${openvpn_config}"; then
    openvpn_config="/config/openvpn/${openvpn_config}"
else
    bashio::log.fatal "OpenVPN configuration '/config/openvpn/${openvpn_config}' not found."
    bashio::addon.stop
fi

interface_name="$(sed -n "/^dev tun/p" "${openvpn_config}" | awk -F' ' '{print $2}')"
if [[ -z "${interface_name}" ]]; then
    bashio::log.fatal "OpenVPN configuration '${openvpn_config}' misses device directive."
    bashio::addon.stop
elif [[ ${interface_name} = "tun" ]]; then
    interface_name='tun0'
elif [[ ${interface_name} = "tap" ]]; then
    interface_name='tap0'
fi

openvpn_runtime_config="${OPENVPN_STATE_DIR}/${interface_name}.conf"

cp "${openvpn_config}" "${openvpn_runtime_config}"
chmod 600 "${openvpn_runtime_config}"

dos2unix "${openvpn_runtime_config}" >/dev/null 2>&1 || true
sed -i '/^[[:space:]]*[;#]/d' "${openvpn_runtime_config}"
sed -i 's/#.*//' "${openvpn_runtime_config}"
sed -i '/^[[:space:]]*$/d' "${openvpn_runtime_config}"
sed -i '/^[[:blank:]]*$/d' "${openvpn_runtime_config}"
sed -i '/^up/d' "${openvpn_runtime_config}"
sed -i '/^down/d' "${openvpn_runtime_config}"
sed -i '/^route/d' "${openvpn_runtime_config}"
sed -i '/^auth-user-pass /d' "${openvpn_runtime_config}"
sed -i '/^cd /d' "${openvpn_runtime_config}"
sed -i '/^chroot /d' "${openvpn_runtime_config}"
sed -i '$q' "${openvpn_runtime_config}"

bashio::log.info 'Prepared OpenVPN runtime configuration for initial connection attempt.'

echo "${openvpn_runtime_config}" > "${OPENVPN_STATE_DIR}/config"
echo "${interface_name}" > "${OPENVPN_STATE_DIR}/interface"

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

bashio::log.info "OpenVPN prepared with interface ${interface_name} using configuration ${openvpn_config##*/}."
