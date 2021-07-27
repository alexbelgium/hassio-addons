ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}

COPY rootfs /

RUN \
    ################
    # Install apps #
    ################
    apk add --no-cache jq curl bash nginx \
    \
    ##################
    # Install bashio #
    ##################
    && mkdir -p /bashio/bashio \
    && curl -J -L -o /bashio/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.13.0.tar.gz" \
    && tar zxvf \
    /bashio/bashio.tar.gz \
    --strip 1 -C /bashio/bashio \
    \
    && mv /bashio/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /bashio \
    \
    ###############
    # Adapt image #
    ###############
    # Correct data path
    && grep -rl "/app/data" /app | xargs sed -i 's|/app/data|/data|g' \
    # Add nginx
    && sed -i '1d' /app/mealie/run.sh \ 
    && cat /app/mealie/run.sh >> /nginx.txt \
    && cat /nginx.txt > /app/mealie/run.sh \
    && chmod +x /app/mealie/run.sh

    #&& sed -i 's|#!/bin/sh|#!/usr/bin/env bashio|g' /app/mealie/run.sh \
    #&& sed -i '1 a bashio::log.info "Mealie started"' /app/mealie/run.sh \
    #&& sed -i '$ d' /app/mealie/run.sh \
    #&& sed -i 's|--preload|--preload & bashio::log.info "Mealie started"|g' /app/mealie/run.sh \
    #&& cat /nginx.txt >> /app/mealie/run.sh

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
    maintainer="tyjtyj (https://github.com/tyjtyj)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="tyjtyj (https://github.com/tyjtyj)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/tyjtyj" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
