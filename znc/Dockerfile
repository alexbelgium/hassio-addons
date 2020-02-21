ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

RUN apk add --no-cache \
        curl=7.67.0-r0 \
        jq=1.6-r0 \
    && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.8.0.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    \
    && rm -f -r \
        /tmp/*

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/znc|g" /etc/services.d/znc/run \
    && sed -i "s|/config|/config/znc|g" /etc/cont-init.d/20-config \
    && sed -i "s|/config/znc/config/zncs|/config/znc/configs|g" /etc/cont-init.d/20-config

# copy local files
COPY root/ /