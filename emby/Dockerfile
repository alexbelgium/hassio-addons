ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="4.6.3.0"

FROM ${BUILD_FROM}${BUILD_UPSTREAM}
ARG BASHIO_VERSION=0.13.0
ARG TEMPIO_VERSION=2021.01.0

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
    ################
    # Install apps #
    ################
    apt-get update \
    && apt-get install -y --no-install-recommends \
    jq \
    cifs-utils \
    keyutils \
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
    /var/{cache,log}/* \
    /var/lib/apt/lists/* \
    \
    #############################
    # Allow UID and GID setting #
    #############################
    \
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    && sed -i "s|chown abc:abc /config||g" /etc/cont-init.d/10-adduser \
    \
    ###########
    # FOLDERS #
    ###########
    \
    && sed -i "s|/config|/emby|g" /etc/services.d/emby/run \
    && sed -i "s|/config|/emby|g" /etc/cont-init.d/30-config

# copy local files
COPY root/ /

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
