ARG BUILD_FROM
ARG BUILD_UPSTREAM="2.1.27"
FROM anthonyraymond/joal:$BUILD_UPSTREAM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG BUILD_VERSION
ARG BUILD_UPSTREAM="2.1.27"
ENV BASHIO_VERSION=0.14.3

RUN \
    #Install bashio
    apt-get clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    wget \
    jq \
    nginx \
    ##################
    # Install bashio #
    ##################
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    \
    #Install Joal
    && wget -O /tmp/joal.tar.gz "https://github.com/anthonyraymond/joal/releases/download/$BUILD_UPSTREAM/joal.tar.gz" \
    && mkdir -p /data/joal \
    && tar zxvf /tmp/joal.tar.gz -C /data/joal \
    && rm /data/joal/jack-of* \
    #Clean
    && rm -fr \
    /tmp/* \
    /var/{cache,log}/* \
    /var/lib/apt/lists/*

VOLUME [ "/data" ]

# Copy root filesystem
COPY rootfs / 
RUN chmod 777 /run.sh

ENTRYPOINT [ "/run.sh" ]

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
