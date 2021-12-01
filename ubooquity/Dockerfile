ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="2.1.2"
FROM ${BUILD_FROM}
ARG BASHIO_VERSION=0.14.3

# Add bashio
RUN apk add --no-cache \
    curl \
    jq \
    moreutils \
    samba \
    nginx \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /tmp/bashio.tar.gz

# Copy root filesystem
COPY rootfs / 

RUN \
    # Set config directory
    sed -i 's|config|config/ubooquity|g' /etc/cont-init.d/10-adduser \
    && sed -i 's|config|config/ubooquity|g' /etc/cont-init.d/30-config \
    && sed -i 's|config|config/ubooquity|g' /etc/services.d/ubooquity/run \
    # Allow UID and GID setting
    && sed -i 's|bash|bashio|g' /etc/cont-init.d/10-adduser \
    && sed -i 's|{PUID:-911}|(bashio::config "PUID")|g' /etc/cont-init.d/10-adduser \
    && sed -i 's|{PGID:-911}|(bashio::config "PGID")|g' /etc/cont-init.d/10-adduser \
    # Set default directory
    && sed -i 's|/files|/share/ubooquity/files|g' /defaults/preferences.json \
    && sed -i 's|/comics|/share/ubooquity/comics|g' /defaults/preferences.json \
    && sed -i 's|/books|/share/ubooquity/books|g' /defaults/preferences.json \
    # Allow maximum memory setting
    && sed -i 's|bash|bashio|g' /etc/services.d/ubooquity/run \
    && sed -i 's|{MAXMEM:-512}|(bashio::config "maxmem")|g' /etc/services.d/ubooquity/run

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
