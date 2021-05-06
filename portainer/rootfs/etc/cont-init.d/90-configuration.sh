#!/usr/bin/env bashio

##################
# DEFINE OPTIONS #
##################
declare -a options
options+=(--data /data)
options+=(--bind 0.0.0.0:9000)
options+=(--templates /opt/portainer/templates.json)
options+=(--host unix:///var/run/docker.sock)

bashio::log.info "Starting Portainer..."

################
# SET PASSWORD #
################

PASSWORD=$(bashio::config 'password')
echo -n $PASSWORD > /tmp/portainer_password
options+=(--admin-password-file /tmp/portainer_password)
bashio::log.info "... password set to $PASSWORD"

##############
# SSL CONFIG #
##############

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
  bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"
  #set variables
  CERTFILE="/ssl/$(bashio::config 'certfile')"
  KEYFILE="/ssl/$(bashio::config 'keyfile')"
  options+=(--ssl true)
  options+=(--sslcert /ssl/$CERTFILE)
  options+=(--sslkey /ssl/$KEYFILE)
  bashio::log.info "... ssl activated"
fi

###################
# HIDE CONTAINERS #
###################

# Hide Hassio containers by default, but only eforce on first run
if ! bashio::fs.file_exists "/data/hidden"; then
    options+=(--hide-label io.hass.type=supervisor)
    options+=(--hide-label io.hass.type=homeassistant)
    options+=(--hide-label io.hass.type=base)
    options+=(--hide-label io.hass.type=core)
    # options+=(--hide-label io.hass.type=addon)
    options+=(--hide-label io.hass.type=audio)
    options+=(--hide-label io.hass.type=cli)
    options+=(--hide-label io.hass.type=dns)
    options+=(--hide-label io.hass.type=multicast)
    options+=(--hide-label io.hass.type=observer)
	bashio::log.info "... non-addon containers hidden"
    touch /data/hidden
fi

####################
# LAUNCH PORTAINER #
####################
bashio::log.info "... portainer launched"

exec /opt/portainer/portainer "${options[@]}"
