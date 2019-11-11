FROM linuxserver/hydra2:v2.8.1-ls42

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/hydra2|g" /etc/services.d/nzbhydra2/run \
    && sed -i "s|/config|/config/hydra2|g" /etc/cont-init.d/30-config
