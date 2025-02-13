#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

##############
# SET SYSTEM #
##############

bashio::log.info "Setting password for the user pi"
if bashio::config.has_value "pi_password"; then
    echo "pi:$(bashio::config "pi_password")" | chpasswd
fi
bashio::log.info "Password set successfully for user pi."

bashio::log.info "Setting timezone :"

# Use timezone defined in add-on options if available
if bashio::config.has_value 'TZ'; then
    TZ_VALUE="$(bashio::config 'TZ')"
    if timedatectl set-timezone "$TZ_VALUE"; then
        echo "... timezone set to $TZ_VALUE as defined in add-on options (BirdNET config ignored)."
    else
        bashio::log.warning "Couldn't set timezone to $TZ_VALUE. Refer to the list of valid timezones: https://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html"
        timedatectl set-ntp true &>/dev/null
    fi
# Use BirdNET-defined timezone if no add-on option is provided
elif [ -f /data/timezone ]; then
    BIRDN_CONFIG_TZ="$(cat /data/timezone)"
    timedatectl set-ntp false &>/dev/null
    if timedatectl set-timezone "$BIRDN_CONFIG_TZ"; then
        echo "... set to $BIRDN_CONFIG_TZ as defined in BirdNET config."
    else
        bashio::log.warning "Couldn't set timezone to $BIRDN_CONFIG_TZ. Reverting to automatic timezone."
        timedatectl set-ntp true &>/dev/null
    fi
# Fallback to automatic timezone if no manual settings are found
else
    if timedatectl set-ntp true &>/dev/null; then
        bashio::log.info "... automatic timezone enabled."
    else
        bashio::log.fatal "Couldn't set automatic timezone! Please set a manual one from the options."
    fi
fi

bashio::log.info "Starting system services"

bashio::log.info "Starting cron service"
systemctl start cron >/dev/null

bashio::log.info "Starting dbus service"
service dbus start >/dev/null

bashio::log.info "Starting BirdNET-Pi services"
chmod +x "$HOME/BirdNET-Pi/scripts/restart_services.sh" >/dev/null
"$HOME/BirdNET-Pi/scripts/restart_services.sh" >/dev/null

# Start livestream services if enabled in configuration
if bashio::config.true LIVESTREAM_BOOT_ENABLED; then
    echo "... starting livestream services"
    systemctl enable icecast2 >/dev/null
    systemctl start icecast2.service >/dev/null
    systemctl enable --now livestream.service >/dev/null
fi

bashio::log.info "Setup complete."
