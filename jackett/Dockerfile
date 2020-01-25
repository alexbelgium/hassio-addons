FROM linuxserver/jackett:v0.12.1635-ls51

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/jackett|g" /etc/cont-init.d/30-config

ENV XDG_DATA_HOME="/share/jackett" \
XDG_CONFIG_HOME="/config/jackett"

# copy local files
COPY root/ /