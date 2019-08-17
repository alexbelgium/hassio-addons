FROM linuxserver/sonarr:2.0.0.5338-ls31

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/sonarr|g" /etc/services.d/sonarr/run \
    && sed -i "s|/config|/config/sonarr|g" /etc/cont-init.d/30-config

# copy local files
COPY root/ /
