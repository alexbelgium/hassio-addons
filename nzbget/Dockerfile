ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/nzbget|g" /etc/services.d/nzbget/run \
    && sed -i "s|/config|/config/nzbget|g" /etc/cont-init.d/30-config \
    && sed -i "s|/downloads|/share/downloads|g" /etc/cont-init.d/30-config \
    && sed -i "s|/downloads|/share/downloads|g" /app/nzbget/share/nzbget/nzbget.conf

# copy local files
COPY root/ /
