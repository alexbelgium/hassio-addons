FROM linuxserver/radarr:v0.2.0.1450-ls46

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/radarr|g" /etc/services.d/radarr/run \
    && sed -i "s|/config|/config/radarr|g" /etc/cont-init.d/30-config

# copy local files
COPY root/ /
