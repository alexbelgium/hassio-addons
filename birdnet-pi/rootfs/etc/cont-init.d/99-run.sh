#!/command/with-contenv bashio
# shellcheck shell=bash

set -eu

##################
# ALLOW RESTARTS #
##################

if [[ "${BASH_SOURCE[0]}" == /etc/cont-init.d/* ]]; then
    mkdir -p /etc/scripts-init
    sed -i "s|/etc/cont-init.d|/etc/scripts-init|g" /ha_entrypoint.sh
    sed -i "/ rm/d" /ha_entrypoint.sh
    cp "${BASH_SOURCE[0]}" /etc/scripts-init/
fi

##############
# SET SYSTEM #
##############

# Set password
bashio::log.info "Setting password for the user pi"
if bashio::config.has_value "pi_password"; then
    echo "pi:$(bashio::config "pi_password")" | chpasswd
fi
bashio::log.info "Password set successfully for user pi."

# Use timezone defined in add-on options if available
bashio::log.info "Setting timezone :"
if bashio::config.has_value 'TZ'; then
    TZ_VALUE="$(bashio::config 'TZ')"
    if timedatectl set-timezone "$TZ_VALUE"; then
        echo "... timezone set to $TZ_VALUE as defined in add-on options (BirdNET config ignored)."
    else
        bashio::log.warning "Couldn't set timezone to $TZ_VALUE. Refer to the list of valid timezones: https://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html"
        timedatectl set-ntp true &> /dev/null
    fi
# Use BirdNET-defined timezone if no add-on option is provided
elif [ -f /data/timezone ]; then
    BIRDN_CONFIG_TZ="$(cat /data/timezone)"
    timedatectl set-ntp false &> /dev/null
    if timedatectl set-timezone "$BIRDN_CONFIG_TZ"; then
        echo "... set to $BIRDN_CONFIG_TZ as defined in BirdNET config."
    else
        bashio::log.warning "Couldn't set timezone to $BIRDN_CONFIG_TZ. Reverting to automatic timezone."
        timedatectl set-ntp true &> /dev/null
    fi
# Fallback to automatic timezone if no manual settings are found
else
    if timedatectl set-ntp true &> /dev/null; then
        bashio::log.info "... automatic timezone enabled."
    else
        bashio::log.fatal "Couldn't set automatic timezone! Please set a manual one from the options."
    fi
fi || true

# Use ALSA CARD defined in add-on options if available
if [ -n "${ALSA_CARD:-}" ]; then
    bashio::log.warning "ALSA_CARD is defined, the birdnet.conf is adapt to use device $ALSA_CARD"
    for file in "$HOME"/BirdNET-Pi/birdnet.conf /config/birdnet.conf; do
        if [ -f "$file" ]; then
            sed -i "/^REC_CARD/c\REC_CARD=$ALSA_CARD" "$file"
        fi
    done
fi

# Define permissions for audio
AUDIO_GID=$(stat -c %g /dev/snd/* | head -n1) \
    && (groupmod -o -g "$AUDIO_GID" audio 2> /dev/null || groupadd -o -g "$AUDIO_GID" audio || true) \
    && usermod -aG audio "${USER:-pi}" || true

# Fix timezone as per installer
CURRENT_TIMEZONE="$(timedatectl show --value --property=Timezone)"
[ -f /etc/timezone ] && echo "$CURRENT_TIMEZONE" | sudo tee /etc/timezone > /dev/null

bashio::log.info "Starting system services"

bashio::log.info "Starting cron service"
systemctl start cron > /dev/null

bashio::log.info "Starting dbus service"
service dbus start > /dev/null

bashio::log.info "Starting BirdNET-Pi services"
chmod +x "$HOME/BirdNET-Pi/scripts/restart_services.sh" > /dev/null
"$HOME/BirdNET-Pi/scripts/restart_services.sh" > /dev/null

# Start livestream services if enabled in configuration
if bashio::config.true "LIVESTREAM_BOOT_ENABLED"; then
    echo "... starting livestream services"
    systemctl enable icecast2 > /dev/null
    systemctl start icecast2.service > /dev/null
    systemctl enable --now livestream.service > /dev/null
fi

# Start
bashio::log.info "✅ Setup complete."
