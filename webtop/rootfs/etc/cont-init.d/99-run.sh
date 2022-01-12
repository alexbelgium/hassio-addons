#!/usr/bin/with-contenv bashio

# Uprade
echo "Updating distribution"
export DEBIAN_FRONTEND=noninteractive
apt-get update &>/dev/null
apt-get -y upgrade >/dev/null || true

# Fix mate software center
if [ -f /usr/lib/dbus-1.0/dbus-daemon-launch-helper ]; then
echo "Allow software center"
chmod u+s /usr/lib/dbus-1.0/dbus-daemon-launch-helper
service dbus restart
fi

# Spotify source
curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo gpg --dearmor -o /usr/share/keyrings/spotify-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/spotify-archive-keyring.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# Install specific apps
if bashio::config.has_value 'additional_apps'; then
    bashio::log.info "Installing additional apps :" 
    # Install apps
            for APP in $(echo "$(bashio::config 'additional_apps')" | tr "," " "); do
              bashio::log.green "... $APP"
              # Test install with both apt-get and snap
              apt-get install -yqq $APP &>/dev/null \
              && bashio::log.green "... done" \
              || bashio::log.red "... not successful, please check package name"
            done
fi
