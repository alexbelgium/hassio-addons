ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/jackett|g" /etc/cont-init.d/30-config

ENV XDG_DATA_HOME="/share/jackett" \
XDG_CONFIG_HOME="/config/jackett"

# copy local files
COPY root/ /