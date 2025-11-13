#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
WIREGUARD_CONFIG_DIR="/config/wireguard"
VPN_INTERFACE_FILE="/var/run/vpn_interface"

if ! bashio::config.true 'wireguard_enabled'; then
    if ! bashio::config.true 'openvpn_enabled'; then
        rm -f "${VPN_INTERFACE_FILE}"
    fi
    exit 0
fi

bashio::log.info "----------------------------"
bashio::log.info "WireGuard enabled, configuring"
bashio::log.info "----------------------------"

if bashio::config.true 'openvpn_enabled'; then
    bashio::exit.nok "WireGuard and OpenVPN cannot be enabled at the same time."
fi

wireguard_interface=$(bashio::config 'wireguard_interface' 'wg0')
wireguard_interface=${wireguard_interface:-wg0}
wireguard_config=$(bashio::config 'wireguard_config' "${wireguard_interface}.conf")
wireguard_config=${wireguard_config:-${wireguard_interface}.conf}
wireguard_config_path="${WIREGUARD_CONFIG_DIR}/${wireguard_config}"

if [[ "${wireguard_config}" != *.conf ]]; then
    bashio::exit.nok "WireGuard configuration file must end with .conf"
fi

if [ ! -f "${wireguard_config_path}" ]; then
    bashio::exit.nok "WireGuard configuration ${wireguard_config} not found in ${WIREGUARD_CONFIG_DIR}."
fi

bashio::log.info "... using WireGuard configuration ${wireguard_config}"

mkdir -p /etc/wireguard
cp "${wireguard_config_path}" "/etc/wireguard/${wireguard_interface}.conf"
chmod 600 "/etc/wireguard/${wireguard_interface}.conf"

if command -v dos2unix >/dev/null 2>&1; then
    dos2unix "/etc/wireguard/${wireguard_interface}.conf" >/dev/null 2>&1 || true
fi

if ! sysctl -w net.ipv4.conf.all.src_valid_mark=1 >/dev/null 2>&1; then
    bashio::log.warning "Unable to set net.ipv4.conf.all.src_valid_mark=1; WireGuard connectivity might be impacted."
fi
if ! sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1; then
    bashio::log.warning "Unable to enable net.ipv4.ip_forward; WireGuard connectivity might be impacted."
fi

if bashio::config.true 'openvpn_alt_mode'; then
    bashio::log.warning "openvpn_alt_mode is ignored when WireGuard is enabled."
fi

if [ -f "${QBT_CONFIG_FILE}" ]; then
    bashio::log.info "... binding ${wireguard_interface} interface in qBittorrent configuration"
    sed -i '/Interface/d' "${QBT_CONFIG_FILE}"
    sed -i "/\\[Preferences\\]/ i\\Connection\\\\Interface=${wireguard_interface}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[Preferences\\]/ i\\Connection\\\\InterfaceName=${wireguard_interface}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[BitTorrent\\]/a \\Session\\\\Interface=${wireguard_interface}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[BitTorrent\\]/a \\Session\\\\InterfaceName=${wireguard_interface}" "${QBT_CONFIG_FILE}"
else
    bashio::log.error "qBittorrent config file doesn't exist, WireGuard must be added manually to qbittorrent options"
    exit 1
fi

echo "${wireguard_interface}" > "${VPN_INTERFACE_FILE}"
chmod 600 "${VPN_INTERFACE_FILE}"

bashio::log.info "... WireGuard configuration completed"
