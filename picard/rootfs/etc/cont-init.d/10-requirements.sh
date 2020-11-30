#!/usr/bin/with-contenv bashio
# ==============================================================================
# This files check if all user configuration requirements are met
# ==============================================================================

# Check authentication requirements, if enabled
if bashio::config.true 'authentication_required'; then
    if ! bashio::config.has_value 'username'; then
        bashio::exit.nok 'Transmission authentication is enabled, but no username was specified'
    fi

    if ! bashio::config.has_value 'password'; then
        bashio::exit.nok 'Transmission authentication is enabled, but no password was specified'
    fi
fi

# Check OpenVPN requirements, if enabled
if bashio::config.true 'openvpn_enabled'; then
    if ! bashio::config.has_value 'openvpn_username'; then
        bashio::exit.nok 'OpenVPN is enabled, but no username was specified'
    fi

    if ! bashio::config.has_value 'openvpn_password'; then
        bashio::exit.nok 'OpenVPN is enabled, but no password was specified'
    fi

    if ! bashio::fs.file_exists "/config/openvpn/$(bashio::config 'openvpn_config').ovpn"; then
        bashio::exit.nok "The configured /config/openvpn/$(bashio::config 'openvpn_config').ovpn file is not found"
    fi
fi
