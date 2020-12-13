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
