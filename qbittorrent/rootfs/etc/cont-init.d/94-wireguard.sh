#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
ENV_DIR="/var/run/s6/container_environment"
WIREGUARD_DIR="/config/wireguard"

# Clean previous environment values when WireGuard is disabled
if ! bashio::config.true 'wireguard_enabled'; then
    rm -f "${ENV_DIR}/WIREGUARD_CONFIG" "${ENV_DIR}/WIREGUARD_INTERFACE" 2>/dev/null || true
    exit 0
fi

if bashio::config.true 'openvpn_enabled'; then
    bashio::exit.nok "Both OpenVPN and WireGuard are enabled. Please enable only one VPN protocol."
fi

bashio::log.info "-----------------------------"
bashio::log.info "WireGuard enabled, configuring"
bashio::log.info "-----------------------------"

# Capture current public IP for later comparison
curl -s ipecho.net/plain > /currentip || true

# Resolve WireGuard configuration file
if bashio::config.has_value 'wireguard_config'; then
    wireguard_config=$(bashio::config 'wireguard_config')
    if [[ "${wireguard_config}" != /* ]]; then
        wireguard_config="${WIREGUARD_DIR}/${wireguard_config}"
    fi
    if [ ! -f "${wireguard_config}" ]; then
        bashio::exit.nok "WireGuard configuration file ${wireguard_config} not found."
    fi
else
    mapfile -t WG_CONFIGS < <(find "${WIREGUARD_DIR}" -maxdepth 1 -type f -name '*.conf' -print)
    if [ "${#WG_CONFIGS[@]}" -eq 0 ]; then
        bashio::exit.nok "WireGuard is enabled, but no .conf files were found in ${WIREGUARD_DIR}."
    elif [ "${#WG_CONFIGS[@]}" -gt 1 ]; then
        bashio::log.error "Multiple WireGuard configuration files detected:"
        printf '%s\n' "${WG_CONFIGS[@]}"
        bashio::exit.nok "Please set the wireguard_config option to select the desired configuration."
    fi
    wireguard_config="${WG_CONFIGS[0]}"
fi

if [[ "${wireguard_config}" != *.conf ]]; then
    bashio::exit.nok "WireGuard configuration ${wireguard_config} must use the .conf extension."
fi

dos2unix "${wireguard_config}" >/dev/null 2>&1 || true
chmod 600 "${wireguard_config}" || true

wireguard_interface="$(basename "${wireguard_config}")"
wireguard_interface="${wireguard_interface%.*}"
wireguard_interface="${wireguard_interface:-wg0}"

mkdir -p "${ENV_DIR}"
printf '%s' "${wireguard_config}" > "${ENV_DIR}/WIREGUARD_CONFIG"
printf '%s' "${wireguard_interface}" > "${ENV_DIR}/WIREGUARD_INTERFACE"
export WIREGUARD_CONFIG="${wireguard_config}"
export WIREGUARD_INTERFACE="${wireguard_interface}"

if bashio::config.true 'openvpn_alt_mode'; then
    if [ -f "${QBT_CONFIG_FILE}" ]; then
        sed -i '/Interface/d' "${QBT_CONFIG_FILE}"
    fi
    bashio::log.info "Using container-level binding for WireGuard (openvpn_alt_mode enabled)."
    exit 0
fi

if [ ! -f "${QBT_CONFIG_FILE}" ]; then
    bashio::log.warning "qBittorrent config file not found; WireGuard interface binding will need to be configured after the application generates it."
    exit 0
fi

bashio::log.info "Binding qBittorrent to WireGuard interface ${wireguard_interface}."
sed -i '/Interface/d' "${QBT_CONFIG_FILE}"
sed -i "/\\[Preferences\\]/ i\\Connection\\\\Interface=${wireguard_interface}" "${QBT_CONFIG_FILE}"
sed -i "/\\[Preferences\\]/ i\\Connection\\\\InterfaceName=${wireguard_interface}" "${QBT_CONFIG_FILE}"
sed -i "/\\[BitTorrent\\]/a \\Session\\\\Interface=${wireguard_interface}" "${QBT_CONFIG_FILE}"
sed -i "/\\[BitTorrent\\]/a \\Session\\\\InterfaceName=${wireguard_interface}" "${QBT_CONFIG_FILE}"
