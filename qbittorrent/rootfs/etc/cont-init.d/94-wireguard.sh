#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

QBT_CONFIG_FILE="/config/qBittorrent/qBittorrent.conf"
WIREGUARD_STATE_FILE="/run/wireguard/interface"

mkdir -p "$(dirname "${WIREGUARD_STATE_FILE}")"

if ! bashio::config.true 'wireguard_enabled'; then
    # Ensure previous state is cleared when WireGuard is disabled
    rm -f "${WIREGUARD_STATE_FILE}"
    exit 0
fi

if bashio::config.true 'openvpn_enabled'; then
    bashio::exit.nok "OpenVPN and WireGuard cannot be enabled at the same time. Disable one of them to continue."
fi

bashio::log.info "------------------------------"
bashio::log.info "WireGuard enabled, configuring"
bashio::log.info "------------------------------"

# Store current public IP for comparison later on
curl -s ipecho.net/plain > /currentip

wireguard_config_name=$(bashio::config 'wireguard_config')
wireguard_config_name=${wireguard_config_name:-config.conf}
wireguard_config_path="/config/wireguard/${wireguard_config_name}"

if [ ! -f "${wireguard_config_path}" ]; then
    bashio::exit.nok "WireGuard configuration file '${wireguard_config_name}' was not found in /config/wireguard."
fi

wireguard_port=$(bashio::addon.port '51820/udp')
if ! bashio::var.has_value "${wireguard_port}" || [[ "${wireguard_port}" == "null" ]]; then
    bashio::exit.nok "WireGuard requires port 51820/udp to be exposed by the add-on. Please map it in the add-on configuration."
fi

# Try to bring WireGuard down in case it is still up from a previous run
wg-quick down "${wireguard_config_path}" >/dev/null 2>&1 || true

bashio::log.info "Starting WireGuard using ${wireguard_config_name}"

wireguard_output="$(mktemp)"
if ! wg-quick up "${wireguard_config_path}" >"${wireguard_output}" 2>&1; then
    bashio::log.error "WireGuard failed to establish a tunnel."
    while IFS= read -r line; do
        bashio::log.error "WireGuard: ${line}"
    done < "${wireguard_output}"
    bashio::log.info "Troubleshooting tips:"
    bashio::log.info "  1. Validate the WireGuard configuration contents inside /config/wireguard/${wireguard_config_name}."
    bashio::log.info "  2. Ensure the 51820/udp port is forwarded from your router to the Home Assistant host."
    bashio::log.info "  3. Confirm your DNS entries and endpoint address are reachable from the Home Assistant host."
    bashio::log.info "  4. Inspect the complete WireGuard log at /config/wireguard/wireguard-last-error.log for provider-specific errors."
    cat "${wireguard_output}" > /config/wireguard/wireguard-last-error.log
    rm -f "${wireguard_output}"
    bashio::exit.nok "WireGuard could not be started. Review the troubleshooting steps above."
fi

# Preserve log for later inspection
cat "${wireguard_output}" > /config/wireguard/wireguard-last-start.log
rm -f "${wireguard_output}"

wireguard_interface=$(wg show interfaces 2>/dev/null | awk '{print $1}' | head -n 1)

if [ -z "${wireguard_interface}" ]; then
    bashio::exit.nok "WireGuard reported no active interfaces after startup."
fi

echo "${wireguard_interface}" > "${WIREGUARD_STATE_FILE}"

bashio::log.info "WireGuard tunnel established on interface '${wireguard_interface}'."
bashio::log.info "The add-on is listening on port ${wireguard_port}/udp for incoming WireGuard traffic."

# Bind qBittorrent to the WireGuard interface to avoid traffic leaks
if [ -f "${QBT_CONFIG_FILE}" ]; then
    bashio::log.info "Binding qBittorrent to the WireGuard interface '${wireguard_interface}'."
    sed -i '/Interface/d' "${QBT_CONFIG_FILE}"
    sed -i "/\\[Preferences\\]/ i\\Connection\\\\Interface=${wireguard_interface}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[Preferences\\]/ i\\Connection\\\\InterfaceName=${wireguard_interface}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[BitTorrent\\]/a \\Session\\\\Interface=${wireguard_interface}" "${QBT_CONFIG_FILE}"
    sed -i "/\\[BitTorrent\\]/a \\Session\\\\InterfaceName=${wireguard_interface}" "${QBT_CONFIG_FILE}"
else
    bashio::log.warning "qBittorrent configuration file not found. Please bind the WireGuard interface manually from the UI."
fi

bashio::log.info "WireGuard setup completed successfully."
