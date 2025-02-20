#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015
set -e

# Install specific apps
if bashio::config.has_value 'additional_apps'; then
    bashio::log.info "Installing additional apps :"
    # hadolint ignore=SC2005
    NEWAPPS=$(bashio::config 'additional_apps')
    for packagestoinstall in ${NEWAPPS//,/ }; do
        bashio::log.green "... $packagestoinstall"
        if command -v "apk" &>/dev/null; then
            apk add --no-cache "$packagestoinstall" &>/dev/null || (bashio::log.fatal "Error : $packagestoinstall not found")
        elif command -v "apt" &>/dev/null; then
            apt-get install -yqq --no-install-recommends "$packagestoinstall" &>/dev/null || (bashio::log.fatal "Error : $packagestoinstall not found")
        elif command -v "pacman" &>/dev/null; then
            pacman --noconfirm -S "$packagestoinstall" &>/dev/null || (bashio::log.fatal "Error : $packagestoinstall not found")
        fi
    done
fi

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" >/etc/timezone
fi || (bashio::log.fatal "Error : $TIMEZONE not found. Here is a list of valid timezones : https://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html")

# Set keyboard
if bashio::config.has_value 'KEYBOARD'; then
    KEYBOARD=$(bashio::config 'KEYBOARD')
    bashio::log.info "Setting keyboard to $KEYBOARD"
    if [ -d /var/run/s6/container_environment ]; then printf "%s" "$KEYBOARD" > /var/run/s6/container_environment/KEYBOARD; fi
    printf "%s\n" "KEYBOARD=\"$KEYBOARD\"" >> ~/.bashrc
fi || true

# Set password
if bashio::config.has_value 'PASSWORD'; then
    bashio::log.info "Setting password to the value defined in options"
    PASSWORD=$(bashio::config 'PASSWORD')
    passwd -d abc
    echo -e "$PASSWORD\n$PASSWORD" | passwd abc
elif ! bashio::config.has_value 'PASSWORD' && [[ -n "$(bashio::addon.port "3000")" ]] && [[ -n $(bashio::addon.port "3001") ]]; then
    bashio::log.warning "SEVERE RISK IDENTIFIED"
    bashio::log.warning "You are opening an external port but your password is not defined"
    bashio::log.warning "You risk being hacked ! Please disable the external ports, or use a password"
fi

# Set permissions

# Set permissions
echo "... setting permissions for node user"
usermod -o -u 0 abc &>/dev/null
groupmod -o -g 0 abc &>/dev/null
