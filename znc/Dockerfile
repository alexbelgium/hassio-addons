ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/znc|g" /etc/services.d/znc/run \
    && sed -i "s|/config|/config/znc|g" /etc/cont-init.d/20-config \
    && sed -i "s|/config/znc/config/zncs|/config/znc/configs|g" /etc/cont-init.d/20-config

# copy local files
COPY root/ /