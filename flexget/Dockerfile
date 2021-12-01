ARG BUILD_FROM
ARG BUILD_VERSION
FROM wiserain/flexget:latest
ARG BASHIO_VERSION=0.14.3

RUN \
    ##################
    # Install apps #
    ##################
    apk add --no-cache \
    jq \
    yq \
    curl \
    cifs-utils \
    \
    ##################
    # Install bashio #
    ##################
    && mkdir -p /tmp/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    | tar -xzf - --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio \
    \
    ###############
    # Adapt image #
    ###############
    # Allow UID and GID setting
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    \
    # Correct config folder
    && grep -rl " /config" /etc/cont-init.d | xargs sed -i 's| /config| /config/flexget|g' \
    && grep -rl " /config" /etc/services.d | xargs sed -i 's| /config| /config/flexget|g' \
    && sed -i 's=/config/flexget=/config/flexget || true=g' /etc/cont-init.d/10-adduser \
    \
    # Set password
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/20-config \
    && sed -i 's/# set FG_WEBUI_PASSWD/if bashio::config.has_value "WebuiPass"; then FG_WEBUI_PASSWD=$(bashio::config "WebuiPass"); fi/g' /etc/cont-init.d/20-config \
    && sed -i 's/# install custom plugins/if bashio::config.has_value "FG_PLUGINS"; then FG_PLUGINS=$(bashio::config "FG_PLUGINS"); fi/g' /etc/cont-init.d/20-config

VOLUME [ "/data" ]

### LABELS
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/alexbelgium" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
