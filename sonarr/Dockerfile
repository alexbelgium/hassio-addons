ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="3.0.6.1196"
FROM ${BUILD_FROM}${BUILD_UPSTREAM}
ARG BASHIO_VERSION=0.13.0

RUN \
    ##################
    # Install bashio #
    ##################
    mkdir -p /tmp/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    | tar -xzf - --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio \
    \
    # use /data instead of /config for hass.io environment
    && sed -i "s|/config|/config/sonarr|g" /etc/services.d/sonarr/run \
    && sed -i "s|/config|/config/sonarr|g" /etc/cont-init.d/30-config \
    \
    # Allow UID and GID setting
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser

# copy local files
COPY root/ /
