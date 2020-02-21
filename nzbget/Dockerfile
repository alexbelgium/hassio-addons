ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

RUN apk add --no-cache \
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
RUN sed -i "s|/config|/config/nzbget|g" /etc/services.d/nzbget/run \
    && sed -i "s|/config|/config/nzbget|g" /etc/cont-init.d/30-config \
    && sed -i "s|/downloads|/share/downloads|g" /etc/cont-init.d/30-config \
    && sed -i "s|/downloads|/share/downloads|g" /app/nzbget/share/nzbget/nzbget.conf

# copy local files
COPY root/ /
